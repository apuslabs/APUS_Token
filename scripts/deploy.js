import Arweave from 'arweave'
import fs from 'fs'
import path from 'path'
import yaml from 'js-yaml';
import { connect, createDataItemSigner } from "@permaweb/aoconnect"

const _arweave = Arweave.init()

let CHECKINGS = {}
function _exploreNodes(node, cwd) {
  if (!fs.existsSync(node.path)) return []

  // set content
  node.content = fs.readFileSync(node.path, 'utf-8')

  const requirePattern = /(?<=(require( *)(\n*)(\()?( *)("|'))).*(?=("|'))/g
  const requiredModules = node.content.match(requirePattern)?.map(
    (mod) => ({
      name: mod,
      path: path.join(cwd, mod.replace(/\./g, '/') + '.lua'),
      content: undefined
    })
  ) || []

  return requiredModules
}

function _createExecutableFromProject(project) {
  const getModFnName = (name) => name.replace(/\./g, '_').replace(/^_/, '')
  /** @type {Module[]} */
  const contents = []

  // filter out repeated modules with different import names
  // and construct the executable Lua code
  // (the main file content is handled separately)
  for (let i = 0; i < project.length - 1; i++) {
    const mod = project[i]

    const existing = contents.find((m) => m.path === mod.path)
    const moduleContent = (!existing && `-- module: "${mod.name}"\nlocal function _loaded_mod_${getModFnName(mod.name)}()\n${mod.content}\nend\n`) || ''
    const requireMapper = `\n_G.package.loaded["${mod.name}"] = _loaded_mod_${getModFnName(existing?.name || mod.name)}()`

    contents.push({
      ...mod,
      content: moduleContent + requireMapper
    })
  }

  // finally, add the main file
  contents.push(project[project.length - 1])

  return [
    contents.reduce((acc, con) => acc + '\n\n' + con.content, ''),
    contents
  ]
}

/**
 * Create the project structure from the main file's content
 * @param {string} mainFile
 * @return {Module[]}
 */
function _createProjectStructure(mainFile) {
  const sorted = []
  const cwd = path.dirname(mainFile)

  // checks if the sorted module list already includes a node
  const isSorted = (node) => sorted.find(
    (sortedNode) => sortedNode.path === node.path
  )

  // recursive dfs algorithm
  function dfs(currentNode) {
    const unvisitedChildNodes = _exploreNodes(currentNode, cwd).filter(
      (node) => !isSorted(node)
    )

    for (let i = 0; i < unvisitedChildNodes.length; i++) {
      dfs(unvisitedChildNodes[i])
    }

    if (!isSorted(currentNode))
      sorted.push(currentNode)
  }

  // run DFS from the main file
  dfs({ path: mainFile })

  return sorted.filter(
    // modules that were not read don't exist locally
    // aos assumes that these modules have already been
    // loaded into the process, or they're default modules
    (mod) => mod.content !== undefined
  )
}

function _load(filePath) {
  const projectStructure = _createProjectStructure(filePath)

  const [executable, modules] = _createExecutableFromProject(projectStructure)
  const line = executable

  if (projectStructure.length > 0) {
  }

  return [line, modules]
}

async function _getAOWallet() {
  const _arweave = Arweave.init()
  const jwk = JSON.parse(fs.readFileSync(path.resolve(process.env.OWNER_JSON_LOCATION || "~/.aos.json"), 'utf-8'))
  const address = await _arweave.wallets.jwkToAddress(jwk)
  return { jwk, address }
}

async function _sendMessageAndGetResult(process, data, tags) {
  const { jwk, address } = await _getAOWallet()
  const signer = createDataItemSigner(jwk)
  const message = await connect().message({
    process,
    signer,
    tags: tags || [
      {
        name: 'Action', value: 'Eval'
      }
    ],
    data
  })
  const result = await connect().result({
    process,
    message
  })
  return result
}

async function _getProcessIDByName(name) {
  const { jwk, address } = await _getAOWallet()
  const query = `query ($owners: [String!]!) {
    transactions(
      first: 1,
      owners: $owners,
      tags: [
        { name: "Data-Protocol", values: ["ao"] },
        { name: "Type", values: ["Process"]},
        { name: "Name", values: ["${name}"]}
      ]
    ) {
      edges {
        node {
          id
        }
      }
    }
  }`

  const body = { query, variables: { owners: [address] } }

  const res = await fetch("https://arweave.net/graphql", {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json'
    },
    body: JSON.stringify(body)
  })

  const result = await res.json();

  if ((result?.data?.transactions?.edges ?? []).length == 0) {
    return null
  } else {
    return result?.data?.transactions?.edges[0].node.id
  }
}

async function _createProcess({ name, cron, ifSqlite }) {
  const { jwk, address } = await _getAOWallet()
  const scheduler = process.env.SCHEDULER || "_GQ33BkPtZrqxA84vM8Zk-N2aO0toNNu_C-l-rawrBA"
  const module = process.env.MODULE || (ifSqlite ? "GuzQrkf50rBUqz3uUgjOIFOL1XmW9nSNysTBC-wyiWM" : "Do_Uc2Sju_ffp6Ev0AnLVdPtot15rvMjP-a9VVaA5fM")
  const signer = createDataItemSigner(jwk)

  let tags = [
    { name: 'App-Name', value: 'aos' },
    { name: 'Name', value: name },
    { name: 'Authority', value: 'fcoN_xJeisVsPXA-trzVAuIiqO3ydLQxM-L4XbrQKzY' },
    ...[]
  ]

  if (cron) {
    if (/^\d+\-(second|seconds|minute|minutes|hour|hours|day|days|month|months|year|years|block|blocks|Second|Seconds|Minute|Minutes|Hour|Hours|Day|Days|Month|Months|Year|Years|Block|Blocks)$/.test(cron)) {
      tags = [...tags,
      { name: 'Cron-Interval', value: cron },
      { name: 'Cron-Tag-Action', value: 'Cron' }
      ]
    } else {
      throw Error('Invalid cron flag!')
    }
  }

  tags = tags.concat([{ name: 'aos-Version', value: "1.12.1" }])  // aos version

  const res = await connect().spawn({
    module, scheduler: scheduler, signer, tags, data: "1984"
  })

  return res;
}

async function _sendMonitorCommand(process) {
  const { jwk, address } = await _getAOWallet()
  const signer = createDataItemSigner(jwk)
  const res = await connect().monitor({ process, signer })
  return res
}

const Config = {
  ApusTokenProcessName: "ATPN-0.0.19",
  ApusStatsProcessName: 'ASPN-0.0.19',
  DeployDelayMs: 5000
}

async function preparationCheck() {
  // make sure target process not exist
  if (!CHECKINGS.APUS_TOKEN_PROCESS.PROCESS) {
    let checkProcessExistRes
    checkProcessExistRes = await _getProcessIDByName(Config.ApusTokenProcessName)
    if (checkProcessExistRes) {
      return `Process named with '${Config.ApusTokenProcessName}' exists, process: ${checkProcessExistRes}, please check.`
    }
  }
  if (!CHECKINGS.APUS_STATS_PROCESS.PROCESS) {
    let checkProcessExistRes
    checkProcessExistRes = await _getProcessIDByName(Config.ApusStatsProcessName)
    if (checkProcessExistRes) {
      return `Process named with '${Config.ApusStatsProcessName}' exists, process: ${checkProcessExistRes}, please check.`
    }
  }
  return null
}

async function deployProcess() {
  if (CHECKINGS.APUS_TOKEN_PROCESS.DEPLOY != 'OK') {
    const apusTokenProcess = await _createProcess({
      name: Config.ApusTokenProcessName,
      cron: "5-minutes",
      ifSqlite: true
    })

    CHECKINGS.APUS_TOKEN_PROCESS.PROCESS = apusTokenProcess
    CHECKINGS.APUS_TOKEN_PROCESS.NAME = Config.ApusTokenProcessName
    CHECKINGS.APUS_TOKEN_PROCESS.DEPLOY = "OK"
    fs.writeFileSync('tmp/deploy_progress.yml', yaml.dump(CHECKINGS))

    console.log("PASS APUS_TOKEN_PROCESS DEPLOYMENT.")
    await delay(Config.DeployDelayMs)
  } else {
    console.log("SKIP APUS_TOKEN_PROCESS DEPLOYMENT.")
  }

  if (CHECKINGS.APUS_TOKEN_PROCESS.LOAD_LUA != 'OK') {
    await _sendMessageAndGetResult(CHECKINGS.APUS_TOKEN_PROCESS.PROCESS, _load('apus_token/main.lua')[0])
    CHECKINGS.APUS_TOKEN_PROCESS.LOAD_LUA = 'OK'
    fs.writeFileSync('tmp/deploy_progress.yml', yaml.dump(CHECKINGS))
    console.log("PASS APUS_TOKEN_PROCESS LOAD_LUA.")
  } else {
    console.log("SKIP APUS_TOKEN_PROCESS LOAD_LUA.")
  }

  if (CHECKINGS.APUS_TOKEN_PROCESS.MONITOR != 'OK') {
    await _sendMonitorCommand(CHECKINGS.APUS_TOKEN_PROCESS.PROCESS)
    CHECKINGS.APUS_TOKEN_PROCESS.MONITOR = 'OK'
    fs.writeFileSync('tmp/deploy_progress.yml', yaml.dump(CHECKINGS))
    console.log("PASS APUS_TOKEN_PROCESS MONITOR.")
  } else {
    console.log("SKIP APUS_TOKEN_PROCESS MONITOR.")
  }

  if (CHECKINGS.APUS_STATS_PROCESS.DEPLOY != 'OK') {
    const apusStatsProcess = await _createProcess({
      name: Config.ApusStatsProcessName,
      cron: "5-minutes",
      ifSqlite: false
    })

    CHECKINGS.APUS_STATS_PROCESS.PROCESS = apusStatsProcess
    CHECKINGS.APUS_STATS_PROCESS.NAME = Config.ApusStatsProcessName
    CHECKINGS.APUS_STATS_PROCESS.DEPLOY = "OK"
    fs.writeFileSync('tmp/deploy_progress.yml', yaml.dump(CHECKINGS))

    console.log("PASS APUS_STATS_PROCESS DEPLOYMENT.")
    await delay(Config.DeployDelayMs)
  } else {
    console.log("SKIP APUS_STATS_PROCESS DEPLOYMENT.")
  }


  if (CHECKINGS.APUS_STATS_PROCESS.LOAD_LUA != 'OK') {
    await _sendMessageAndGetResult(CHECKINGS.APUS_STATS_PROCESS.PROCESS, _load('apus_statistics/main.lua')[0])
    CHECKINGS.APUS_STATS_PROCESS.LOAD_LUA = 'OK'
    fs.writeFileSync('tmp/deploy_progress.yml', yaml.dump(CHECKINGS))
    console.log("PASS APUS_STATS_PROCESS LOAD_LUA.")
  } else {
    console.log("SKIP APUS_STATS_PROCESS LOAD_LUA.")
  }
  if (CHECKINGS.APUS_STATS_PROCESS.MONITOR != 'OK') {
    await _sendMonitorCommand(CHECKINGS.APUS_STATS_PROCESS.PROCESS)
    CHECKINGS.APUS_STATS_PROCESS.MONITOR = 'OK'
    fs.writeFileSync('tmp/deploy_progress.yml', yaml.dump(CHECKINGS))
    console.log("PASS APUS_STATS_PROCESS MONITOR.")
  } else {
    console.log("SKIP APUS_STATS_PROCESS MONITOR.")
  }
}

async function initializeProcess() {
  if (CHECKINGS.APUS_TOKEN_PROCESS.INITIALIZE != 'OK') {
    await _sendMessageAndGetResult(CHECKINGS.APUS_TOKEN_PROCESS.PROCESS, `AO_MINT_PROCESS = "${"LPK-D_3gZkXtia6ywwU1wRwgFOZ-eLFRMP9pfAFRfuw"}"`)
    await _sendMessageAndGetResult(CHECKINGS.APUS_TOKEN_PROCESS.PROCESS, `APUS_STATS_PROCESS = "${CHECKINGS.APUS_STATS_PROCESS.PROCESS}"`)
    await _sendMessageAndGetResult(CHECKINGS.APUS_TOKEN_PROCESS.PROCESS, `MODE = "ON"`)
    CHECKINGS.APUS_TOKEN_PROCESS.INITIALIZE = "OK"
    fs.writeFileSync('tmp/deploy_progress.yml', yaml.dump(CHECKINGS))

    console.log("PASS APUS_TOKEN_PROCESS INITIALIZE.")
  } else {
    console.log("SKIP APUS_TOKEN_PROCESS INITIALIZE.")
  }

  if (CHECKINGS.APUS_STATS_PROCESS.INITIALIZE != 'OK') {
    const result = await _sendMessageAndGetResult(CHECKINGS.APUS_STATS_PROCESS.PROCESS, `APUS_MINT_PROCESS = "${CHECKINGS.APUS_TOKEN_PROCESS.PROCESS}"`)
    CHECKINGS.APUS_STATS_PROCESS.INITIALIZE = "OK"
    fs.writeFileSync('tmp/deploy_progress.yml', yaml.dump(CHECKINGS))

    console.log("PASS APUS_STATS_PROCESS INITIALIZE.")
  } else {
    console.log("SKIP APUS_STATS_PROCESS INITIALIZE.")
  }
}


function delay(ms) {
  return new Promise(resolve => setTimeout(resolve, ms));
}

(async function main() {
  if (!fs.existsSync('tmp/')) {
    fs.mkdirSync('tmp/')
  }
  if (!fs.existsSync('tmp/deploy_progress.yml', 'utf-8')) {
    fs.writeFileSync('tmp/deploy_progress.yml', yaml.dump({
      APUS_TOKEN_PROCESS: {
        NAME: null,
        PROCESS: null,
        DEPLOY: 'PENDING',
        LOAD_LUA: 'PENDING',
        MONITOR: 'PENDING',
        INITIALIZE: 'PENDING'
      },
      APUS_STATS_PROCESS: {
        NAME: null,
        PROCESS: null,
        DEPLOY: 'PENDING',
        LOAD_LUA: 'PENDING',
        MONITOR: 'PENDING',
        INITIALIZE: 'PENDING'
      }
    }))
  }
  CHECKINGS = yaml.load(fs.readFileSync('tmp/deploy_progress.yml', "utf-8"))
  let res = await preparationCheck()
  if (res) {
    console.log(`Preparation Check Failed: ${res}`)
    return
  }

  await deployProcess()
  await initializeProcess()
})()