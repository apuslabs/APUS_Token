import fs from 'fs';
import path from 'path';
import { asyncWithBreathingLog, simpleError, simpleSuccess } from '../lib/async_with_log.mjs';
import yaml from 'js-yaml';
import { connect, createDataItemSigner, dryrun, results } from "@permaweb/aoconnect"
import Arweave from 'arweave'
import { deepEqual } from '../lib/deep_equal.mjs';
import os from 'os'
import dotenv from 'dotenv'

dotenv.config()

let ConfigPath = 'scripts/tmp/conf'
let AO_MINT_PROCESS = ''
let AO_RECEIVER = process.env.AO_RECEIVER || 'gd66FHg7Q1nMYm25lRzXuUGZv5jw5d0bKaPhHp9mkBI'

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

async function _sendDryRunAndGetResult(process, data, tags) {
  const result = await dryrun({
    process: process,
    data,
    tags: tags || [
      {
        name: 'Action', value: 'Eval'
      }
    ],
  })
  return result
}

async function _getProcessResults(process) {
  // fetching the first page of results
  let resultsOut = await results({
    process: process,
    sort: "ASC",
    limit: 25,
  });

  return resultsOut
}


function delay(ms) {
  return new Promise(resolve => setTimeout(resolve, ms));
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

function _readConfig() {
  if (!fs.existsSync(path.join(ConfigPath, "config.yml"))) {
    fs.writeFileSync(path.join(ConfigPath, "config.yml"), '')
  }
  return yaml.load(fs.readFileSync(path.join(ConfigPath, "config.yml"), 'utf-8'))
}

function _readRuntime() {
  if (!fs.existsSync(path.join(ConfigPath, "runtime.yml"))) {
    fs.writeFileSync(path.join(ConfigPath, "runtime.yml"), '')
  }
  return yaml.load(fs.readFileSync(path.join(ConfigPath, "runtime.yml"), 'utf-8'))
}

function _readT0Allocation() {
  if (!fs.existsSync(path.join(ConfigPath, "T0_allocation.yml"))) {
    fs.writeFileSync(path.join(ConfigPath, "T0_allocation.yml"), '')
  }
  return yaml.load(fs.readFileSync(path.join(ConfigPath, "T0_allocation.yml"), 'utf-8'))
}

function _readProgress() {
  const defaultProgress = `APUS_TOKEN:
  Deploy: Pending
  LoadLua: Pending
  Monitor: Pending
  Initialize: Pending
APUS_STATS:
  Deploy: Pending
  LoadLua: Pending
  Monitor: Pending
  Initialize: Pending`
  if (!fs.existsSync(path.join(ConfigPath, "progress.yml"))) {
    fs.writeFileSync(path.join(ConfigPath, "progress.yml"), defaultProgress)
  }

  return yaml.load(fs.readFileSync(path.join(ConfigPath, "progress.yml"), 'utf-8'))
}

function _readCheckings() {
  if (!fs.existsSync(path.join(ConfigPath, "checkings.yml"))) {
    fs.writeFileSync(path.join(ConfigPath, "checkings.yml"), '')
  }
  return yaml.load(fs.readFileSync(path.join(ConfigPath, "checkings.yml"), 'utf-8'))
}

function _insertChecking(checking) {
  if (!fs.existsSync(path.join(ConfigPath, "checkings.yml"))) {
    fs.writeFileSync(path.join(ConfigPath, "checkings.yml"), '')
  }
  const curCheckings = yaml.load(fs.readFileSync(path.join(ConfigPath, "checkings.yml"), 'utf-8')) || []
  curCheckings.push(checking)
  fs.writeFileSync(path.join(ConfigPath, "checkings.yml"), yaml.dump(curCheckings))
}

function _updateApusTokenProcessAndName(process, name) {
  if (!fs.existsSync(path.join(ConfigPath, "runtime.yml"))) {
    fs.writeFileSync(path.join(ConfigPath, "runtime.yml"), '')
  }

  const curRuntime = yaml.load(fs.readFileSync(path.join(ConfigPath, "runtime.yml"), 'utf-8')) || {}
  curRuntime.APUS_TOKEN_PROCESS_ID = process;
  curRuntime.APUS_TOKEN_PROCESS_NAME = name;
  fs.writeFileSync(path.join(ConfigPath, "runtime.yml"), yaml.dump(curRuntime))
}

function _updateProgress(paths, str) {
  const defaultProgress = `APUS_TOKEN:
  Deploy: Pending
  LoadLua: Pending
  Monitor: Pending
  Initialize: Pending
APUS_STATS:
  Deploy: Pending
  LoadLua: Pending
  Monitor: Pending
  Initialize: Pending`
  if (!fs.existsSync(path.join(ConfigPath, "progress.yml"))) {
    fs.writeFileSync(path.join(ConfigPath, "progress.yml"), defaultProgress)
  }

  const curRuntime = yaml.load(fs.readFileSync(path.join(ConfigPath, "progress.yml"), 'utf-8')) || {}

  paths.reduce((acc, key, index) => {
    if (index === paths.length - 1) {
      acc[key] = str;
    } else {
      if (!acc[key] || typeof acc[key] !== 'object') {
        acc[key] = {};
      }
    }
    return acc[key];
  }, curRuntime);

  fs.writeFileSync(path.join(ConfigPath, "progress.yml"), yaml.dump(curRuntime))
}

function _updateApusStatsProcessAndName(process, name) {
  if (!fs.existsSync(path.join(ConfigPath, "runtime.yml"))) {
    fs.writeFileSync(path.join(ConfigPath, "runtime.yml"), '')
  }

  const curRuntime = yaml.load(fs.readFileSync(path.join(ConfigPath, "runtime.yml"), 'utf-8')) || {}
  curRuntime.APUS_STATS_PROCESS_ID = process;
  curRuntime.APUS_STATS_PROCESS_NAME = name;
  fs.writeFileSync(path.join(ConfigPath, "runtime.yml"), yaml.dump(curRuntime))
}

async function prepareConfig(argv) {
  const defaultT0Allocation = `- Author: zxom15ySOXLhpasi8ian4eoKmocUpNpi5BHE1g0Uqas
  Amount: "10000000000000000000"
- Author: POJfk-XpD1ghZLIZwuSCD8JFDh_FPOZYbizp5MWxczQ
  Amount: "50000000000000000000"
- Author: shUfg1ovwx0J-5y6A4HUOWJ485XHBZXoLe4vS2iOurU
  Amount: "10000000000000000000"
- Author: JyQiTvqKIXZczY57PWOnhELUBIIKc56xWAbcM2_MXrk
  Amount: "10000000000000000000"`

  function _checkConfigPath(argv) {
    if (!fs.existsSync(ConfigPath) || !fs.statSync(ConfigPath).isDirectory()) {
      throw Error(`Config location '${argv.config}' not exist or is not directory, please check parameter`)
    }
  }

  function _createConfigIfNotExist(argv) {
    const configPath = path.join(ConfigPath, "config.yml")
    if (!fs.existsSync(configPath)) {
      return -2
    }
  }

  function _createT0AllocationIfNotExist(argv) {
    const t0AllocationPath = path.join(ConfigPath, "T0_allocation.yml")
    if (!fs.existsSync(t0AllocationPath)) {
      // Create a default one.
      asyncWithBreathingLog(fs.writeFileSync, [t0AllocationPath, defaultT0Allocation], "T0 Allocation Config Not Exist, Create One.")
      fs.writeFileSync(t0AllocationPath, defaultT0Allocation)
    }
  }

  function _cleanProgressIfProcessNameChanged(argv) {
    const config = _readConfig() || {}
    const runtime = _readRuntime() || {}

    const apusName = config.APUS_TOKEN_PROCESS_NAME
    const statsName = config.APUS_STATS_PROCESS_NAME

    if (runtime.APUS_TOKEN_PROCESS_NAME == apusName || runtime.APUS_STATS_PROCESS_NAME == statsName) {
      simpleSuccess('Exists same name process in config, not clearing')
    } else {
      simpleSuccess('Two names changed, clear cache')
      if (fs.existsSync(path.join(ConfigPath, "runtime.yml"))) {
        fs.rmSync(path.join(ConfigPath, "runtime.yml"))
      }
      if (fs.existsSync(path.join(ConfigPath, "progress.yml"))) {
        fs.rmSync(path.join(ConfigPath, "progress.yml"))
      }
      if (fs.existsSync(path.join(ConfigPath, "checkings.yml"))) {
        fs.rmSync(path.join(ConfigPath, "checkings.yml"))
      }
      if (fs.existsSync(path.join(ConfigPath, "T0_allocation.yml"))) {
        fs.rmSync(path.join(ConfigPath, "T0_allocation.yml"))
      }
    }
  }

  function _overwriteConfig(argv) {
    if (!fs.existsSync(ConfigPath)) {
      fs.mkdirSync(ConfigPath, { recursive: true })
    }
    const configPath = path.join(ConfigPath, "config.yml")
    fs.writeFileSync(configPath, yaml.dump({
      APUS_TOKEN_NAME: argv["_"][1],
      APUS_TOKEN_TICKER: argv["_"][2],
      APUS_STATS_PROCESS_NAME: argv["_"][3],
      APUS_TOKEN_PROCESS_NAME: argv["_"][4],
    }))
  }

  try {
    if (argv.config) {
      ConfigPath = argv.config
      if (!fs.existsSync(ConfigPath)) {
        fs.mkdirSync(ConfigPath, { recursive: true })
      }
      await _cleanProgressIfProcessNameChanged(argv)
      await asyncWithBreathingLog(_checkConfigPath, [argv], `Check if config ${argv.config} exist`);
      await asyncWithBreathingLog(_createConfigIfNotExist, [argv], `Create config if not exist ${path.join(argv.config, "config.yml")}`)
      await asyncWithBreathingLog(_createT0AllocationIfNotExist, [argv], `Create t0 allocation if not exist ${path.join(argv.config, "T0_allocation.yml")}`)
    } else {
      if (argv["_"].length == 1) {
        await asyncWithBreathingLog(_createConfigIfNotExist, [argv], `Create config if not exist ${path.join(ConfigPath, "config.yml")}`)
      } else if (argv["_"].length < 5) {
        simpleError('Number of parameters is less than 5, please check.')
        throw Error('Number of parameters is less than 5')
      } else {
        await asyncWithBreathingLog(_overwriteConfig, [argv], `Create the config.`)
      }
      await _cleanProgressIfProcessNameChanged(argv)
      await asyncWithBreathingLog(_createT0AllocationIfNotExist, [argv], `Create t0 allocation if not exist ${path.join(ConfigPath, "T0_allocation.yml")}`)
    }
  } catch (error) {
    throw error
  }
}

async function deployCheckNameDuplicate(processName) {
  const res = await _getProcessIDByName(processName)
  if (res) {
    throw Error('Name exists')
  }
}

async function deployProcesses() {
  const progress = _readProgress()
  const conf = _readConfig()

  try {
    if (progress.APUS_TOKEN.Deploy == "Pending") {
      await asyncWithBreathingLog(deployCheckNameDuplicate, [conf.APUS_TOKEN_PROCESS_NAME], `Check if Process with "${conf.APUS_TOKEN_PROCESS_NAME}" exist`)
      const apusTokenProcess = await asyncWithBreathingLog(_createProcess, {
        name: conf.APUS_TOKEN_PROCESS_NAME,
        cron: "5-minutes",
        ifSqlite: true
      }, "Deploy Apus Token")
      _updateApusTokenProcessAndName(apusTokenProcess, conf.APUS_TOKEN_PROCESS_NAME)
      _updateProgress(["APUS_TOKEN", "Deploy"], "OK")
      await asyncWithBreathingLog(async () => { await delay(5000) }, [], "Wait 5 seconds for deployment.")
    } else {
      simpleSuccess(`SKIP Deploying Apus Token.`)
    }

    if (progress.APUS_STATS.Deploy == "Pending") {
      await asyncWithBreathingLog(deployCheckNameDuplicate, [conf.APUS_STATS_PROCESS_NAME], `Check if Process with "${conf.APUS_STATS_PROCESS_NAME}" exist`)
      const apusTokenProcess = await asyncWithBreathingLog(_createProcess, {
        name: conf.APUS_STATS_PROCESS_NAME,
        cron: "5-minutes",
        ifSqlite: true
      }, "Deploy Apus Stats Process")
      _updateApusStatsProcessAndName(apusTokenProcess, conf.APUS_STATS_PROCESS_NAME)
      _updateProgress(["APUS_STATS", "Deploy"], "OK")
      await asyncWithBreathingLog(async () => { await delay(5000) }, [], "Wait 5 seconds for deployment.")
    } else {
      simpleSuccess(`SKIP Deploying Apus Stats.`)
    }

  } catch (error) {
    throw error
  }
}

async function updateSourceFiles(argv) {
  const runtime = _readRuntime()
  const conf = _readConfig()
  const t0Allocation = _readT0Allocation()

  if (argv.env == 'test') {
    AO_MINT_PROCESS = "LPK-D_3gZkXtia6ywwU1wRwgFOZ-eLFRMP9pfAFRfuw"
  } else if (argv.env == "production") {
    AO_MINT_PROCESS = "1OEAToQGhSKV76oa1MFIGZ9bYxCJoxpXqtksApDdcu8"
  } else if (argv.env == 'mock') {
    AO_MINT_PROCESS = 'VhadaUKwZVN9mWp3_4fIlfuBeGW19FzNgyvpfcNGi0E'
  }

  if (AO_MINT_PROCESS == "") {
    simpleError(`Get AO_MINT_PROCESS Failed, check env(current: ${argv.env})`)
  } else {
    simpleSuccess(`AO_MINT_PROCESS: ${AO_MINT_PROCESS}`)
  }

  function _generateConfigLua() {
    return `-- AO Addresses
AO_MINT_PROCESS = "${AO_MINT_PROCESS}"
APUS_STATS_PROCESS = "${runtime.APUS_STATS_PROCESS_ID}"
APUS_MINT_TRIGGER = "${runtime.APUS_STATS_PROCESS_ID}"
AO_RECEIVER = "${AO_RECEIVER}"

--Minting cycle interval in seconds
MINT_COOL_DOWN = 300

--Tokenomics
Name = "${conf.APUS_TOKEN_NAME}"
Ticker = "${conf.APUS_TOKEN_TICKER}"
Logo = "tesHcQpU6KWRMflKUnJpcsTCVwjV6BTaWLx_BV233JU"

-- Current minting mode ("ON" or "OFF"), ON: auto-mint; OFF: manual-mint
MODE = MODE or "ON"

--T0 token receivers
T0_ALLOCATION = {
  --1 % to liquidity
  { Author = "${t0Allocation[0].Author}", Amount = "${t0Allocation[0].Amount}" },

  --5 % to pool bootstrap
  { Author = "${t0Allocation[1].Author}", Amount = "${t0Allocation[1].Amount}" },

  --2 % to contributors
${t0Allocation.slice(2).map((r) => {
      return `  { Author = "${r.Author}", Amount = "${r.Amount}" }`
    }).join(",\n")
      }
}

return {}`
  }

  fs.writeFileSync("apus_token/config.lua", _generateConfigLua())
  fs.writeFileSync("apus_statistics/main.lua", fs.readFileSync('apus_statistics/main.lua', 'utf-8').replace(/APUS_MINT_PROCESS = APUS_MINT_PROCESS or "[a-z0-9A-Z\-_]+"/, `APUS_MINT_PROCESS = APUS_MINT_PROCESS or "${runtime.APUS_TOKEN_PROCESS_ID}"`))
  simpleSuccess('Update source file apus_token/config.lua & apus_statistics/main.lua')
}

async function loadLua() {
  const runtime = _readRuntime()
  const progress = _readProgress()

  async function loadLuaForApusToken() {
    const res = await _sendMessageAndGetResult(runtime.APUS_TOKEN_PROCESS_ID, _load('apus_token/main.lua')[0])
    if (res.Error) {
      throw Error('Load lua for apus token failed')
    }
  }
  async function loadLuaForApusStats() {
    const res = await _sendMessageAndGetResult(runtime.APUS_STATS_PROCESS_ID, _load('apus_statistics/main.lua')[0])
    if (res.Error) {
      throw Error('Load lua for apus stats failed')
    }
  }
  if (progress.APUS_TOKEN.LoadLua == 'Pending') {
    await asyncWithBreathingLog(loadLuaForApusToken, [], `Load lua for process ${runtime.APUS_TOKEN_PROCESS_NAME}(${runtime.APUS_TOKEN_PROCESS_ID})`)
    _updateProgress(["APUS_TOKEN", "LoadLua"], "OK")
  } else {
    simpleSuccess("SKIP Loading lua for Apus Token.")
  }
  if (progress.APUS_STATS.LoadLua == 'Pending') {
    await asyncWithBreathingLog(loadLuaForApusStats, [], `Load lua for process ${runtime.APUS_STATS_PROCESS_NAME}(${runtime.APUS_STATS_PROCESS_ID})`)
    _updateProgress(["APUS_STATS", "LoadLua"], "OK")
  } else {
    simpleSuccess("SKIP Loading lua for Apus Stats.")
  }
}

async function monitorProcesses() {
  const progress = _readProgress()
  const runtime = _readRuntime()
  async function monitorTokenProcess() {
    const res = await _sendMonitorCommand(runtime.APUS_TOKEN_PROCESS_ID)
    if (res.Error) {
      throw Error('Load lua for apus stats failed')
    }
  }
  async function monitorStatsProcess() {
    const res = await _sendMonitorCommand(runtime.APUS_STATS_PROCESS_ID)
    if (res.Error) {
      throw Error('Load lua for apus stats failed')
    }
  }
  if (progress.APUS_TOKEN.Monitor == 'Pending') {
    await asyncWithBreathingLog(monitorTokenProcess, [], "Monitor APUS_TOKEN Process.")
    _updateProgress(["APUS_TOKEN", "Monitor"], "OK")
  } else {
    simpleSuccess("SKIP Monitoring APUS_TOKEN Process.")
  }
  if (progress.APUS_STATS.Monitor == 'Pending') {
    await asyncWithBreathingLog(monitorStatsProcess, [], "Monitor APUS_STATS Process.")
    _updateProgress(["APUS_STATS", "Monitor"], "OK")
  } else {
    simpleSuccess("SKIP Monitoring APUS_STATS Process.")
  }
}

async function sendEvalAndCheckRes({ process, line, assertion }) {
  let checkingName = ''
  const checkings = _readCheckings() || []
  if (typeof assertion == 'number') {
    checkingName = `[${process}] Assert ${line} == ${assertion}`
  } else if (typeof assertion == 'string') {
    checkingName = `[${process}] Assert ${line} == "${assertion}"`
  } else {
    checkingName = `[${process}] Assert ${line}`
  }
  async function _internal() {
    const res = await _sendMessageAndGetResult(process, line)
    if (res.Error) {
      throw Error('internal error')
    }
    const ret = res?.Output?.data || ''
    if (typeof assertion == 'string') {
      if (assertion.trim() !== ret.trim()) {
        throw Error(`${checkingName}, actual: "${res.Output.data.trim()}", "${assertion.trim()}"`)
      }
    } else if (typeof assertion == 'number') {
      if (assertion != ret) {
        throw Error(`${checkingName}, actual: ${res.Output.data}, ${assertion}`)
      }
    } else if (typeof assertion == 'object') {
      if (!deepEqual(assertion, JSON.parse(ret))) {
        throw Error(`${checkingName}`)
      }
    } else if (typeof assertion == 'boolean') {
      const retValue = ret == 'true' ? true : false
      if (assertion != retValue) {
        throw Error(`${checkingName}, actual: ${res.Output.data}, ${assertion}`)
      }
    }
  }
  try {
    if (checkings.includes(checkingName)) {
      simpleSuccess(checkingName)
    } else {
      await asyncWithBreathingLog(_internal, [], checkingName)
      _insertChecking(checkingName)
    }
  } catch (error) {
    simpleError(`${error.message}`, true)
    throw error
  }
}

async function afterCheck(argv) {
  // if (argv.env == "production") {
  //   simpleSuccess(`Skip after check in env ${argv.env}`)
  //   return
  // }
  console.log("\nStart checking...")
  const runtime = _readRuntime();
  const conf = _readConfig();
  const apusTokenProcess = runtime.APUS_TOKEN_PROCESS_ID;
  const apusStatsProcess = runtime.APUS_STATS_PROCESS_ID;

  async function checkIfSubscribed() {
    const results = (await _getProcessResults(apusTokenProcess) ?? { edges: [] }).edges
    const target = results.find((r) => {
      return r.node?.Messages?.[0] && r.node.Messages[0].Target == AO_MINT_PROCESS && r.node.Messages[0].Tags.find((t) => { return t.name == "Action" && t.value == "Recipient.Subscribe-Report" })
    })
    if (!target) {
      throw Error(`Not subscribed`)
    }
  }

  // try {
  //   if ((_readCheckings() || []).includes(`[${apusTokenProcess}] Check if Subscribed`)) {
  //     simpleSuccess(`[${apusTokenProcess}] Check if Subscribed`)
  //   } else {
  //     await asyncWithBreathingLog(checkIfSubscribed, [], `[${apusTokenProcess}] Check if Subscribed`)
  //     _insertChecking(`[${apusTokenProcess}] Check if Subscribed`)
  //   }
  // } catch (error) {
  //   throw error
  // }

  await sendEvalAndCheckRes(
    { process: apusTokenProcess, line: "INITIAL_MINT_AMOUNT", assertion: "80000000000000000000" }
  )
  await sendEvalAndCheckRes(
    { process: apusTokenProcess, line: "AO_MINT_PROCESS", assertion: AO_MINT_PROCESS }
  )
  await sendEvalAndCheckRes(
    { process: apusTokenProcess, line: "APUS_STATS_PROCESS", assertion: runtime.APUS_STATS_PROCESS_ID }
  )
  await sendEvalAndCheckRes(
    { process: apusTokenProcess, line: "APUS_MINT_TRIGGER", assertion: runtime.APUS_STATS_PROCESS_ID }
  )
  await sendEvalAndCheckRes(
    { process: apusTokenProcess, line: "AO_RECEIVER", assertion: AO_RECEIVER }
  )
  await sendEvalAndCheckRes(
    { process: apusTokenProcess, line: "MINT_COOL_DOWN", assertion: 300 }
  )
  await sendEvalAndCheckRes(
    { process: apusTokenProcess, line: "Name", assertion: conf.APUS_TOKEN_NAME }
  )
  await sendEvalAndCheckRes(
    { process: apusTokenProcess, line: "Ticker", assertion: conf.APUS_TOKEN_TICKER }
  )
  await sendEvalAndCheckRes(
    { process: apusTokenProcess, line: "Logo", assertion: "tesHcQpU6KWRMflKUnJpcsTCVwjV6BTaWLx_BV233JU" }
  )
  await sendEvalAndCheckRes(
    { process: apusTokenProcess, line: "MODE", assertion: "ON" }
  )
  await sendEvalAndCheckRes(
    { process: apusTokenProcess, line: "Variant", assertion: "0.0.3" }
  )
  await sendEvalAndCheckRes(
    { process: apusTokenProcess, line: "Denomination", assertion: 12 }
  )
  await sendEvalAndCheckRes(
    { process: apusTokenProcess, line: "TotalSupply", assertion: "1000000000000000000000" }
  )
  await sendEvalAndCheckRes(
    { process: apusTokenProcess, line: "IsTNComing", assertion: "" }
  )
  await sendEvalAndCheckRes(
    { process: apusTokenProcess, line: "MINT_CAPACITY", assertion: "1000000000000000000000" }
  )
  await sendEvalAndCheckRes(
    { process: apusTokenProcess, line: "APUS_MINT_PCT_1", assertion: 19421654225 }
  )
  await sendEvalAndCheckRes(
    { process: apusTokenProcess, line: "APUS_MINT_PCT_2", assertion: 16473367976 }
  )
  await sendEvalAndCheckRes(
    { process: apusTokenProcess, line: "APUS_MINT_UNIT", assertion: 10000000000000000 }
  )
  await sendEvalAndCheckRes(
    { process: apusTokenProcess, line: "INTERVALS_PER_YEAR", assertion: 365.25 * 24 * 12 }
  )
  await sendEvalAndCheckRes(
    { process: apusTokenProcess, line: "DAYS_PER_MONTH", assertion: 30.4375 }
  )
  await sendEvalAndCheckRes(
    { process: apusTokenProcess, line: "INTERVALS_PER_MONTH", assertion: 8766 }
  )
  await sendEvalAndCheckRes(
    { process: apusTokenProcess, line: "INITIAL_MINT_AMOUNT", assertion: "80000000000000000000" }
  )
  await sendEvalAndCheckRes(
    { process: apusTokenProcess, line: "MintedSupply", assertion: "80000000000000000000" }
  )
  await sendEvalAndCheckRes(
    { process: apusTokenProcess, line: "MintTimes", assertion: 1 }
  )
  await sendEvalAndCheckRes(
    { process: apusTokenProcess, line: "LastMintTime", assertion: 0 }
  )
  await sendEvalAndCheckRes(
    { process: apusTokenProcess, line: "Initialized", assertion: true }
  )
  await sendEvalAndCheckRes(
    { process: apusTokenProcess, line: "require('json').encode(T0_ALLOCATION)", assertion: _readT0Allocation() }
  )
  await sendEvalAndCheckRes(
    { process: apusTokenProcess, line: "require('json').encode(Balances)", assertion: _readT0Allocation().reduce(function (acc, v) { acc[v.Author] = v.Amount; return acc }, {}) }
  )
  await sendEvalAndCheckRes(
    { process: apusStatsProcess, line: "APUS_MINT_PROCESS", assertion: runtime.APUS_TOKEN_PROCESS_ID }
  )
  await sendEvalAndCheckRes(
    { process: apusStatsProcess, line: "require('json').encode(CycleInfo)", assertion: [] }
  )
  await sendEvalAndCheckRes(
    { process: apusStatsProcess, line: "Capacity", assertion: 1 }
  )
  await sendEvalAndCheckRes(
    { process: apusStatsProcess, line: "TotalMint", assertion: "0" }
  )
  await sendEvalAndCheckRes(
    { process: apusStatsProcess, line: "MintedSupply", assertion: "0" }
  )
  await sendEvalAndCheckRes(
    { process: apusStatsProcess, line: "MintCapacity", assertion: "1000000000000000000000" }
  )
  await sendEvalAndCheckRes(
    { process: apusStatsProcess, line: "require('json').encode(AssetStaking)", assertion: [] }  // empty table is treated as list
  )
  await sendEvalAndCheckRes(
    { process: apusStatsProcess, line: "require('json').encode(AssetAOAmount)", assertion: [] }  // empty table is treated as list
  )
  await sendEvalAndCheckRes(
    { process: apusStatsProcess, line: "require('json').encode(AssetWeight)", assertion: [] }  // empty table is treated as list
  )
  await sendEvalAndCheckRes(
    { process: apusStatsProcess, line: "require('json').encode(UserMint)", assertion: [] }  // empty table is treated as list
  )
}

async function showResult() {
  simpleSuccess(`Complete!\n`)
  console.log(`Apus Token Process:\t${_readRuntime().APUS_TOKEN_PROCESS_ID}`)
  console.log(`Apus Stats Process:\t${_readRuntime().APUS_STATS_PROCESS_ID}`)
  console.log(`Test link:\thttps://test.apus.network/#/mint?apus_process=${_readRuntime().APUS_TOKEN_PROCESS_ID}&mirror_process=${_readRuntime().APUS_STATS_PROCESS_ID}&tge_time=2024-12-13T08:00:00Z`)
}

export default async function deploy(argv) {
  try {
    await prepareConfig(argv)
    await deployProcesses()
    await updateSourceFiles(argv) // get env to set AO_MINT_PROCESS
    await loadLua()
    await monitorProcesses()
    await afterCheck(argv)
    await showResult()
  } catch (error) {
    console.log(error)
  }
}