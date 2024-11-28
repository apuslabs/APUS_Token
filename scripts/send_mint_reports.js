import Arweave from 'arweave'
import fs from 'fs'
import path from 'path'
import os from 'os'
import { connect, createDataItemSigner } from "@permaweb/aoconnect"

const PROCESS_ID = "8Dty73vZSUPPRgnFtRgCa4Qa_55gOKef-PFnb57F_FQ"

function getInfo() {
  return {
    GATEWAY_URL: 'https://arweave.net',
    CU_URL: 'https://ao-cu-0.ao-devnet.xyz',
    MU_URL: 'https://ao-mu-0.ao-devnet.xyz'
  }
}

export async function test() {
  const jwk = fs.readFileSync("/Users/liweizhi/.aos.json").toString("utf-8")
  const signer = createDataItemSigner(JSON.parse(jwk))
  const message = await connect().message({
    process: PROCESS_ID,
    signer,
    tags: [
      { name: 'Action', value: 'Report.Mint' },
    ],
    data: fs.readFileSync('scripts/mint-report.json', { encoding: 'utf-8' })
  })

  const res = await connect().result({ process: PROCESS_ID, message })
  console.log(res.Error);
  return res;
}

test()