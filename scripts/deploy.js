import Arweave from 'arweave'
import fs from 'fs'
import path from 'path'
import yaml from 'js-yaml';
import { connect, createDataItemSigner } from "@permaweb/aoconnect"
import os from 'os';

const _arweave = Arweave.init()

let ConfigWithoutT0Allocation = {}
let T0Allocation = {}

const DELAY_MS = 5000

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
  const jwk = JSON.parse(fs.readFileSync(path.resolve(process.env.OWNER_JSON_LOCATION || `${os.homedir()}/.aos.json`), 'utf-8'))
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

function getEntireConfig() {
  const _conf = JSON.parse(JSON.stringify(ConfigWithoutT0Allocation));
  _conf.APUS_TOKEN_PROCESS.Config.T0Allocation = T0Allocation
  return _conf
}

function generateConfigLua(config) {
  const apusTokenConfig = config.APUS_TOKEN_PROCESS.Config
  return `-- AO Addresses
AO_MINT_PROCESS = "${apusTokenConfig.Main.AO_MINT_PROCESS}"
APUS_STATS_PROCESS = "${apusTokenConfig.Main.APUS_STATS_PROCESS} "

--Minting cycle interval in seconds
MINT_COOL_DOWN = ${apusTokenConfig.Mint.MINT_COOL_DOWN}

--Tokenomics
Name = "${apusTokenConfig.Token.Name}"
Ticker = "${apusTokenConfig.Token.Ticker}"
Logo = "${apusTokenConfig.Token.Logo}"

-- Current minting mode ("ON" or "OFF"), ON: auto-mint; OFF: manual-mint
MODE = MODE or "ON"

--T0 token receivers
T0_ALLOCATION = {
  --1 % to liquidity
  { Author = "${apusTokenConfig.T0Allocation[0].Author}", Amount = "${apusTokenConfig.T0Allocation[0].Amount}" },

  --5 % to pool bootstrap
  { Author = "${apusTokenConfig.T0Allocation[1].Author}", Amount = "${apusTokenConfig.T0Allocation[1].Amount}" },

  --2 % to contributors
${apusTokenConfig.T0Allocation.slice(2).map((r) => {
    return `  { Author = "${r.Author}", Amount = "${r.Amount}" }`
  }).join(",\n")
    }
}

return {}`
}

async function prepareConfig() {
  if (!fs.existsSync('deploy/')) {
    fs.mkdirSync('deploy/')
  }
  if (!fs.existsSync('deploy/config.yml', 'utf-8')) {
    fs.writeFileSync('deploy/config.yml', yaml.dump({
      APUS_TOKEN_PROCESS: {
        Name: "APUS_RC0",
        Config: {
          Token: {
            Name: "APUS Release Candidate 0",
            Ticker: "APUS_RC0",
            Logo: "tesHcQpU6KWRMflKUnJpcsTCVwjV6BTaWLx_BV233JU"
          },
          Mint: {
            MINT_COOL_DOWN: 300
          },
          Main: {
            AO_MINT_PROCESS: "LPK-D_3gZkXtia6ywwU1wRwgFOZ-eLFRMP9pfAFRfuw",
            APUS_STATS_PROCESS: "zmr4sqL_fQjjvHoUJDkT8eqCiLFEM3RV5M96Wd59ffU"
          }
        },
        Process: {
          ID: null
        },
        DeployProgress: {
          DEPLOY: "PENDING",
          LOAD_LUA: "PENDING",
          MONITOR: "PENDING",
          INITIALIZE: "PENDING"
        }
      },
      APUS_STATS_PROCESS: {
        Name: "APUS_STATS_RC0",
        Config: {
          Main: {
            APUS_MINT_PROCESS: ""
          }
        },
        Process: {
          ID: null
        },
        DeployProgress: {
          DEPLOY: "PENDING",
          LOAD_LUA: "PENDING",
          MONITOR: "PENDING",
          INITIALIZE: "PENDING"
        }
      }
    }))
    return "Created default config, please set the config for it"
  }

  ConfigWithoutT0Allocation = yaml.load(fs.readFileSync('deploy/config.yml', 'utf-8'))
  T0Allocation = yaml.load(fs.readFileSync('deploy/T0_allocation.yml', 'utf-8'))

  // console.log(generateConfigLua(getEntireConfig()))
}

async function preparationCheck() {
  // make sure target process not exist
  if (!ConfigWithoutT0Allocation.APUS_TOKEN_PROCESS.Process.ID) {
    console.log("START APUS_TOKEN_PROCESS NAME_DUPLICATE_CHECK")
    let checkProcessExistRes
    checkProcessExistRes = await _getProcessIDByName(ConfigWithoutT0Allocation.APUS_TOKEN_PROCESS.Name)
    if (checkProcessExistRes) {
      return `FAIL APUS_TOKEN_PROCESS NAME_DUPLICATE_CHECK`
    }
    console.log("PASS APUS_TOKEN_PROCESS NAME_DUPLICATE_CHECK")
  }
  if (!ConfigWithoutT0Allocation.APUS_STATS_PROCESS.Process.ID) {
    console.log("START APUS_STATS_PROCESS NAME_DUPLICATE_CHECK")
    let checkProcessExistRes
    checkProcessExistRes = await _getProcessIDByName(ConfigWithoutT0Allocation.APUS_STATS_PROCESS.Name)
    if (checkProcessExistRes) {
      return `FAIL APUS_STATS_PROCESS NAME_DUPLICATE_CHECK`
    }
    console.log("PASS APUS_STATS_PROCESS NAME_DUPLICATE_CHECK")
  }
  return null
}

async function deployProcess() {
  if (ConfigWithoutT0Allocation.APUS_TOKEN_PROCESS.DeployProgress.DEPLOY != 'OK') {
    console.log("START APUS_TOKEN_PROCESS DEPLOYMENT.")
    const apusTokenProcess = await _createProcess({
      name: ConfigWithoutT0Allocation.APUS_TOKEN_PROCESS.Name,
      cron: "5-minutes",
      ifSqlite: true
    })

    ConfigWithoutT0Allocation.APUS_TOKEN_PROCESS.Process.ID = apusTokenProcess
    ConfigWithoutT0Allocation.APUS_TOKEN_PROCESS.DeployProgress.DEPLOY = "OK"
    fs.writeFileSync('deploy/config.yml', yaml.dump(ConfigWithoutT0Allocation))

    console.log("PASS APUS_TOKEN_PROCESS DEPLOYMENT.")
    await delay(DELAY_MS)
  } else {
    console.log("SKIP APUS_TOKEN_PROCESS DEPLOYMENT.")
  }

  if (ConfigWithoutT0Allocation.APUS_STATS_PROCESS.DeployProgress.DEPLOY != 'OK') {
    console.log("START APUS_STATS_PROCESS DEPLOYMENT.")
    const apusStatsProcess = await _createProcess({
      name: ConfigWithoutT0Allocation.APUS_STATS_PROCESS.Name,
      cron: "5-minutes",
      ifSqlite: false
    })

    ConfigWithoutT0Allocation.APUS_STATS_PROCESS.Process.ID = apusStatsProcess
    ConfigWithoutT0Allocation.APUS_STATS_PROCESS.DeployProgress.DEPLOY = "OK"
    fs.writeFileSync('deploy/config.yml', yaml.dump(ConfigWithoutT0Allocation))

    console.log("PASS APUS_STATS_PROCESS DEPLOYMENT.")
    await delay(DELAY_MS)
  } else {
    console.log("SKIP APUS_STATS_PROCESS DEPLOYMENT.")
  }

  ConfigWithoutT0Allocation.APUS_TOKEN_PROCESS.Config.Main.APUS_STATS_PROCESS = ConfigWithoutT0Allocation.APUS_STATS_PROCESS.Process.ID
  ConfigWithoutT0Allocation.APUS_STATS_PROCESS.Config.Main.APUS_MINT_PROCESS = ConfigWithoutT0Allocation.APUS_TOKEN_PROCESS.Process.ID

  // overwrite the apus_token/main.lua
  fs.writeFileSync("apus_token/config.lua", generateConfigLua(getEntireConfig()))
  fs.writeFileSync("apus_statistics/main.lua", fs.readFileSync('apus_statistics/main.lua', 'utf-8').replace(/APUS_MINT_PROCESS = APUS_MINT_PROCESS or "[a-z0-9A-Z\-_]+"/, `APUS_MINT_PROCESS = APUS_MINT_PROCESS or "${ConfigWithoutT0Allocation.APUS_TOKEN_PROCESS.Process.ID}"`))

  if (ConfigWithoutT0Allocation.APUS_TOKEN_PROCESS.DeployProgress.LOAD_LUA != 'OK') {
    console.log("START APUS_TOKEN_PROCESS LOAD_LUA.")
    await _sendMessageAndGetResult(ConfigWithoutT0Allocation.APUS_TOKEN_PROCESS.Process.ID, _load('apus_token/main.lua')[0])
    ConfigWithoutT0Allocation.APUS_TOKEN_PROCESS.DeployProgress.LOAD_LUA = 'OK'
    fs.writeFileSync('deploy/config.yml', yaml.dump(ConfigWithoutT0Allocation))
    console.log("PASS APUS_TOKEN_PROCESS LOAD_LUA.")
  } else {
    console.log("SKIP APUS_TOKEN_PROCESS LOAD_LUA.")
  }

  if (ConfigWithoutT0Allocation.APUS_TOKEN_PROCESS.DeployProgress.MONITOR != 'OK') {
    console.log("START APUS_TOKEN_PROCESS MONITOR.")
    await _sendMonitorCommand(ConfigWithoutT0Allocation.APUS_TOKEN_PROCESS.Process.ID)
    ConfigWithoutT0Allocation.APUS_TOKEN_PROCESS.DeployProgress.MONITOR = 'OK'
    fs.writeFileSync('deploy/config.yml', yaml.dump(ConfigWithoutT0Allocation))
    console.log("PASS APUS_TOKEN_PROCESS MONITOR.")
  } else {
    console.log("SKIP APUS_TOKEN_PROCESS MONITOR.")
  }

  if (ConfigWithoutT0Allocation.APUS_STATS_PROCESS.DeployProgress.LOAD_LUA != 'OK') {
    console.log("START APUS_STATS_PROCESS LOAD_LUA.")
    await _sendMessageAndGetResult(ConfigWithoutT0Allocation.APUS_STATS_PROCESS.Process.ID, _load('apus_statistics/main.lua')[0])
    ConfigWithoutT0Allocation.APUS_STATS_PROCESS.DeployProgress.LOAD_LUA = 'OK'
    fs.writeFileSync('deploy/config.yml', yaml.dump(ConfigWithoutT0Allocation))
    console.log("PASS APUS_STATS_PROCESS LOAD_LUA.")
  } else {
    console.log("SKIP APUS_STATS_PROCESS LOAD_LUA.")
  }
  if (ConfigWithoutT0Allocation.APUS_STATS_PROCESS.DeployProgress.MONITOR != 'OK') {
    console.log("START APUS_STATS_PROCESS MONITOR.")
    await _sendMonitorCommand(ConfigWithoutT0Allocation.APUS_STATS_PROCESS.Process.ID)
    ConfigWithoutT0Allocation.APUS_STATS_PROCESS.DeployProgress.MONITOR = 'OK'
    fs.writeFileSync('deploy/config.yml', yaml.dump(ConfigWithoutT0Allocation))
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
  if ((process.argv?.[2] || "") == "clear") {
    if (fs.existsSync('deploy/config.yml')) {
      fs.rmSync('deploy/config.yml');
    }
    return
  }

  // substract process_name from source codes.
  const prepareConfigRes = await prepareConfig()
  if (prepareConfigRes) {
    console.log(prepareConfigRes)
    return
  }

  const preparationCheckRes = await preparationCheck()
  if (preparationCheckRes) {
    console.log(preparationCheckRes)
    return
  }

  const deployRes = await deployProcess()
  if (deployRes) {
    console.log(deployRes)
    return
  }
})()