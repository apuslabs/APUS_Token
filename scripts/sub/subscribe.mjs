import fs from 'fs';
import { asyncWithBreathingLog, simpleError, simpleSuccess } from '../lib/async_with_log.mjs';
import Arweave from 'arweave';
import path from 'path';
import { connect, createDataItemSigner, dryrun, results } from "@permaweb/aoconnect"
import yaml from 'js-yaml'

let JWK = ''
let WALLET = ''
let AO_MINT_PROCESS = ''
let ConfigPath = 'scripts/tmp/conf'


function _readRuntime() {
  if (!fs.existsSync(path.join(ConfigPath, "runtime.yml"))) {
    fs.writeFileSync(path.join(ConfigPath, "runtime.yml"), '')
  }
  return yaml.load(fs.readFileSync(path.join(ConfigPath, "runtime.yml"), 'utf-8'))
}

async function _getAOWallet(keyFile) {
  const _arweave = Arweave.init()
  const jwk = keyFile ? JSON.parse(fs.readFileSync(keyFile, 'utf-8')) : JWK
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

async function sendSubscribeAndCheckRes(argv) {
  try {
    const reportTo = argv.reportTo ?? _readRuntime().APUS_TOKEN_PROCESS_ID
    const res = await asyncWithBreathingLog(_sendMessageAndGetResult, [AO_MINT_PROCESS, "", [
      { name: 'Action', value: "Report.Subscribe" },
      { name: 'Report-To', value: reportTo }
    ]], `Send subscribe message to ${AO_MINT_PROCESS}, report-to:${reportTo}`)
    if (res.Error) {
      throw Error('Message error')
    }
    if ((res?.Messages?.[0]?.Data ?? '') != `Successfully subscribed to ${(await _getAOWallet()).address}`) {
      throw Error('Subscribe not successful')
    }
  } catch (error) {
    throw error
  }
}

export default async function subscribe(argv) {
  try {
    if (!fs.existsSync(argv.keyFile)) {
      simpleError(`Key file not exist: "${argv.keyFile}", please check.`)
      return
    }

    const { jwk, address } = await asyncWithBreathingLog(_getAOWallet, [argv.keyFile], "Get AO Wallet")

    // assign global variables
    JWK = jwk
    WALLET = address

    simpleSuccess(`Get target wallet ${address}`, true)

    if (argv.env == 'test') {
      AO_MINT_PROCESS = "LPK-D_3gZkXtia6ywwU1wRwgFOZ-eLFRMP9pfAFRfuw"
    } else if (argv.env == "production") {
      AO_MINT_PROCESS = "1OEAToQGhSKV76oa1MFIGZ9bYxCJoxpXqtksApDdcu8"
    } else if (argv.env == 'mock') {
      AO_MINT_PROCESS = 'VhadaUKwZVN9mWp3_4fIlfuBeGW19FzNgyvpfcNGi0E'
    }

    if (AO_MINT_PROCESS == '') {
      simpleError(`Failed to set AO_MINT_PROCESS, please check env: ${argv.env}`)
      return
    } else {
      simpleSuccess(`Set AO_MINT_PROCESS: ${AO_MINT_PROCESS}`)
    }

    await sendSubscribeAndCheckRes(argv)

    simpleSuccess(`Complete`)
  } catch (error) {
    simpleError(error.message, true)
  }
}