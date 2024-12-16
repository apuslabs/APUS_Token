import fs from 'fs';
import { asyncWithBreathingLog, simpleError, simpleSuccess } from '../lib/async_with_log.mjs';
import Arweave from 'arweave';
import path from 'path'
import { connect, createDataItemSigner, dryrun, results } from "@permaweb/aoconnect"
import yaml from 'js-yaml';
import os from 'os'

let JWK = ''
let WALLET = ''
let AO_MINT_PROCESS = ''
let ConfigPath = 'scripts/tmp/conf'


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

function _readRuntime() {
  if (!fs.existsSync(path.join(ConfigPath, "runtime.yml"))) {
    fs.writeFileSync(path.join(ConfigPath, "runtime.yml"), '')
  }
  return yaml.load(fs.readFileSync(path.join(ConfigPath, "runtime.yml"), 'utf-8'))
}

async function sendSubscribeAndCheckRes(argv) {
  try {
    const res = await asyncWithBreathingLog(_sendMessageAndGetResult, [AO_MINT_PROCESS, "", [
      { name: 'Action', value: "Recipient.Subscribe-Report" },
      { name: 'Report-To', value: argv.reportTo }
    ]], `Send subscribe message to ${AO_MINT_PROCESS}, report-to:${argv.reportTo}`)
    if (res.Error) {
      throw Error('Message error')
    }
  } catch (error) {
    throw error
  }
}

export default async function allowMintReport(argv) {
  try {
    const runtime = _readRuntime()
    const token_process = runtime.APUS_TOKEN_PROCESS_ID
    await asyncWithBreathingLog(_sendMessageAndGetResult, [token_process, "AllowMintReport = true"], "Allow Mint Report")
  } catch (error) {
    simpleError(error.message, true)
  }
}