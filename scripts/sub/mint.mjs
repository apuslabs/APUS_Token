
import { connect, createDataItemSigner, dryrun, results } from "@permaweb/aoconnect"
import Arweave from 'arweave'
import { asyncWithBreathingLog } from "../lib/async_with_log.mjs"
import fs from 'fs'
import path from 'path'
import yaml from 'js-yaml'
import os from 'os'

let ConfigPath = 'scripts/tmp/conf'

async function _getAOWallet() {
  const _arweave = Arweave.init()
  const jwk = JSON.parse(fs.readFileSync(path.resolve(process.env.OWNER_JSON_LOCATION || `${os.homedir()}/.aos.json`), 'utf-8'))
  const address = await _arweave.wallets.jwkToAddress(jwk)
  return { jwk, address }
}

function _readRuntime() {
  if (!fs.existsSync(path.join(ConfigPath, "runtime.yml"))) {
    fs.writeFileSync(path.join(ConfigPath, "runtime.yml"), '')
  }
  return yaml.load(fs.readFileSync(path.join(ConfigPath, "runtime.yml"), 'utf-8'))
}

function _getTagsFromObj(obj) {
  return Object.entries(obj).map(([k, v]) => {
    return {
      name: k,
      value: v
    }
  })
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

export default async function mint(argv) {
  const token_process = _readRuntime().APUS_TOKEN_PROCESS_ID;
  console.log(token_process)
  try {
    await asyncWithBreathingLog(_sendMessageAndGetResult, [token_process, "", _getTagsFromObj({ Action: "Mint.Backup" })], "send message to trigger mint")
  } catch (err) {
    console.log(err)
  }
}