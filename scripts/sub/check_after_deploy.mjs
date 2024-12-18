import fs from 'fs'
import path from 'path'
import yaml from 'js-yaml'
import { asyncWithBreathingLog, simpleError, simpleSuccess } from '../lib/async_with_log.mjs'
import { connect, createDataItemSigner, dryrun, results } from "@permaweb/aoconnect"
import Arweave from 'arweave'
import os from 'os'
import { deepEqual } from '../lib/deep_equal.mjs'
import { containsSubset } from '../lib/obj_contain.mjs'

let ConfigPath = 'scripts/tmp/conf'
let AO_MINT_PROCESS = ''
let AO_RECEIVER = process.env.AO_RECEIVER || 'gd66FHg7Q1nMYm25lRzXuUGZv5jw5d0bKaPhHp9mkBI'
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


function _readCheckings() {
  if (!fs.existsSync(path.join(ConfigPath, "checkings.yml"))) {
    fs.writeFileSync(path.join(ConfigPath, "checkings.yml"), '')
  }
  return yaml.load(fs.readFileSync(path.join(ConfigPath, "checkings.yml"), 'utf-8'))
}

function _getTagsFromObj(obj) {
  return Object.entries(obj).map(([k, v]) => {
    return {
      name: k,
      value: v
    }
  })
}

function _insertChecking(checking) {
  if (!fs.existsSync(path.join(ConfigPath, "checkings.yml"))) {
    fs.writeFileSync(path.join(ConfigPath, "checkings.yml"), '')
  }
  const curCheckings = yaml.load(fs.readFileSync(path.join(ConfigPath, "checkings.yml"), 'utf-8')) || []
  curCheckings.push(checking)
  fs.writeFileSync(path.join(ConfigPath, "checkings.yml"), yaml.dump(curCheckings))
}



function _readT0Allocation() {
  if (!fs.existsSync(path.join(ConfigPath, "T0_allocation.yml"))) {
    fs.writeFileSync(path.join(ConfigPath, "T0_allocation.yml"), '')
  }
  return yaml.load(fs.readFileSync(path.join(ConfigPath, "T0_allocation.yml"), 'utf-8'))
}

function _readStartTime() {
  const sourceCode = fs.readFileSync('apus_token/config.lua', 'utf-8')
  const matchRes = sourceCode.match(/StartMintTime\s+=\s+StartMintTime\s+or\s+(\d+)/)
  return parseInt(matchRes[1])
}


async function _getAOWallet() {
  const _arweave = Arweave.init()
  const jwk = JSON.parse(fs.readFileSync(path.resolve(process.env.OWNER_JSON_LOCATION || `${os.homedir()}/.aos.json`), 'utf-8'))
  const address = await _arweave.wallets.jwkToAddress(jwk)
  return { jwk, address }
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


async function sendDryRunAndCheckTags({ process, line, assertion, tags }) {
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
    const res = await _sendDryRunAndGetResult(process, line, tags)
    if (res.Error) {
      throw Error('internal error')
    }
    const ret = res?.Messages?.[0]?.Tags || []
    const tagObj = ret.reduce(function (acc, v) {
      acc[v.name] = v.value
      return acc
    }, {})
    if (typeof assertion == 'string') {
    } else if (typeof assertion == 'number') {
    } else if (typeof assertion == 'object') {
      if (!containsSubset(tagObj, assertion)) {
        throw Error(`${checkingName}`)
      }
    } else if (typeof assertion == 'boolean') {
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

async function sendDryRunAndCheckRes({ process, line, assertion, tags, checking }) {
  let checkingName = checking
  if (!checkingName || checkingName == '') {
    if (typeof assertion == 'number') {
      checkingName = `[${process}] Assert ${line} == ${assertion}`
    } else if (typeof assertion == 'string') {
      checkingName = `[${process}] Assert ${line} == "${assertion}"`
    } else {
      checkingName = `[${process}] Assert ${line}`
    }
  }
  const checkings = _readCheckings() || []
  async function _internal() {
    const res = await _sendDryRunAndGetResult(process, line, tags)
    if (res.Error) {
      throw Error('internal error')
    }
    const ret = res?.Messages?.[0]?.Data || ''
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
    { process: apusTokenProcess, line: "LogLevel", assertion: "info" }
  )
  await sendEvalAndCheckRes(
    { process: apusTokenProcess, line: "MINT_COOL_DOWN", assertion: 300 }
  )
  await sendEvalAndCheckRes(
    { process: apusTokenProcess, line: "StartMintTime", assertion: _readStartTime() }
  )
  await sendEvalAndCheckRes(
    { process: apusTokenProcess, line: "Name", assertion: conf.APUS_TOKEN_NAME }
  )
  await sendEvalAndCheckRes(
    { process: apusTokenProcess, line: "Ticker", assertion: conf.APUS_TOKEN_TICKER }
  )
  await sendEvalAndCheckRes(
    { process: apusTokenProcess, line: "Logo", assertion: "FpZ540mGWcWQmiWAWzW4oREUyrF2CxLGwgZwbxhK-9g" }
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

  await sendDryRunAndCheckTags({
    process: apusTokenProcess, line: 'Token.info', assertion: { Name: _readConfig().APUS_TOKEN_NAME, Logo: 'FpZ540mGWcWQmiWAWzW4oREUyrF2CxLGwgZwbxhK-9g', Denomination: '12', Ticker: _readConfig().APUS_TOKEN_TICKER }, tags: _getTagsFromObj({ Action: 'Info' })
  })

  await sendDryRunAndCheckRes({
    process: apusTokenProcess, line: 'Token.balances', assertion: _readT0Allocation().reduce(function (acc, v) { acc[v.Author] = v.Amount; return acc }, {}), tags: _getTagsFromObj({ Action: 'Balances' })
  })

  await sendDryRunAndCheckRes({
    process: apusTokenProcess, line: `Token.balance of 'POJfk-XpD1ghZLIZwuSCD8JFDh_FPOZYbizp5MWxczQ'`, assertion: "50000000000000000000", tags: _getTagsFromObj({
      Action: 'Balance', Recipient: 'POJfk-XpD1ghZLIZwuSCD8JFDh_FPOZYbizp5MWxczQ'
    })
  })

  await sendDryRunAndCheckRes({
    process: apusTokenProcess, line: `Token.totalSupply`, assertion: "1000000000000000000000", tags: _getTagsFromObj({
      Action: 'Total-Supply'
    })
  })

  await sendDryRunAndCheckRes({
    process: apusTokenProcess, line: `Token.totalSupply`, assertion: "80000000000000000000", tags: _getTagsFromObj({
      Action: 'Minted-Supply'
    })
  })
}

export async function checkAfterDeploy(argv) {
  if (argv.env == 'test') {
    AO_MINT_PROCESS = "LPK-D_3gZkXtia6ywwU1wRwgFOZ-eLFRMP9pfAFRfuw"
  } else if (argv.env == "production") {
    AO_MINT_PROCESS = "1OEAToQGhSKV76oa1MFIGZ9bYxCJoxpXqtksApDdcu8"
  } else if (argv.env == 'mock') {
    AO_MINT_PROCESS = 'VhadaUKwZVN9mWp3_4fIlfuBeGW19FzNgyvpfcNGi0E'
  }

  try {
    await afterCheck(argv)
    simpleSuccess('Complete!')
  } catch (err) {
    console.log(err)
  }
}