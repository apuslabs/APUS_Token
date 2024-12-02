import { load } from '../vendor/aos/src/commands/load.js'
import { getWallet, getWalletFromArgs } from "../vendor/aos/src/services/wallets.js"
import Arweave from 'arweave'
import fs from 'fs'
import path from 'path'
import os from 'os'
import { connect, createDataItemSigner } from "@permaweb/aoconnect"

function getInfo() {
  return {
    GATEWAY_URL: 'https://arweave.net',
    CU_URL: 'https://ao-cu-0.ao-devnet.xyz',
    MU_URL: 'https://ao-mu-0.ao-devnet.xyz'
  }
}

function delay(ms) {
  return new Promise(resolve => setTimeout(resolve, ms));
}
const _arweave = Arweave.init()

async function __getJWKAndWallet() {
  const jwk = await getWallet()
  const address = await _arweave.wallets.jwkToAddress(jwk)
  return { jwk, address }
}

async function __getProcessIDByName(name) {
  const { jwk, address } = await __getJWKAndWallet()
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

  return result
}

// export function spawnProcess({ wallet, src, tags, data }) {
//   const SCHEDULER = process.env.SCHEDULER || "_GQ33BkPtZrqxA84vM8Zk-N2aO0toNNu_C-l-rawrBA"
//   const signer = createDataItemSigner(wallet)

//   tags = tags.concat([{ name: 'aos-Version', value: pkg.version }])
//   return fromPromise(() => connect(getInfo()).spawn({
//     module: src, scheduler: SCHEDULER, signer, tags, data
//   })
//     .then(result => new Promise((resolve) => setTimeout(() => resolve(result), 500)))
//   )()

// }
async function __createOrGetProcess({ name, cron, data, spawnTags }) {
  const findProcessRes = await __getProcessIDByName(name)

  if ((findProcessRes["data"]["transactions"]["edges"] ?? []).length > 0) {
    const target = findProcessRes["data"]["transactions"]["edges"][0].node.id
    console.log(`Target process ${name} exist, process id: ${target}`);
    return target
  }

  const { jwk, address } = await __getJWKAndWallet()
  const scheduler = process.env.SCHEDULER || "_GQ33BkPtZrqxA84vM8Zk-N2aO0toNNu_C-l-rawrBA"  // aos package json 
  const module = process.env.MODULE || "GuzQrkf50rBUqz3uUgjOIFOL1XmW9nSNysTBC-wyiWM"  // aos package json 
  const signer = createDataItemSigner(jwk)


  let tags = [
    { name: 'App-Name', value: 'aos' },
    { name: 'Name', value: name },
    { name: 'Authority', value: 'fcoN_xJeisVsPXA-trzVAuIiqO3ydLQxM-L4XbrQKzY' },
    ...(spawnTags || [])
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
    module, scheduler: scheduler, signer, tags, data
  })

  console.log(`Process ${name} created successfully, id: ${res}`);
  return res;
}

async function __getLuaLines(filename) {
  return load(`.load ${filename}`)
}

async function __sendMessage({ process, signer, tags, data }) {
  const res = await connect().message({
    process,
    signer,
    tags,
    data
  })()
  return res;
}

async function _sendEvalMessage({ process, data }) {
  const { jwk, address } = await __getJWKAndWallet()
  const signer = createDataItemSigner(jwk)
  const res = await connect().message({
    process,
    signer,
    tags: [
      { name: 'Action', value: 'Eval' }
    ],
    data
  })
  return res
}

async function _sendMessageByName({ name, tags, data }) {
  // connect(getInfo()).message({ process: processId, signer, tags, data })))
  const process = __getProcessIDByName(name)
  const { jwk, address } = __getJWKAndWallet()
  const signer = createDataItemSigner(jwk)
  __sendMessage({ process, signer, tags, data })
}
// load_lua()

async function __readResult({ process, message }) {
  const res = await connect().result({ process, message })
  return res
}

export async function deployProcessWithLua({ name, cron,/* spawnTags, */ luaLocation, delayTime = 1500 }) {
  if (!fs.existsSync(luaLocation)) {
    console.log(`File ${luaLocation} not exist`)
    return
  }

  const spawnTags = []  // tags added in spawning procees

  const processId = await __createOrGetProcess({ name, cron, data: "1984", spawnTags })

  await delay(4000)

  let res = await __getLuaLines(luaLocation)
  const line = res[0]
  const modules = res[1]


  res = await _sendEvalMessage({
    process: processId,
    data: line
  })

  let message = res;

  const result = await __readResult({ process: processId, message: message })
  return processId
}

export async function deployProcess({ name, cron }) {
  const processId = await __createOrGetProcess({ name, cron, data: "1984", spawnTags })
  return processId
}

export async function updateProcessWithLua({ name, lua }) {
  let res = await __getLuaLines(lua)
  const line = res[0]
  const modules = res[1]

  const process = __getProcessIDByName(name)
  res = await _sendEvalMessage({
    process,
    data: line
  })

  let message = res;

  const result = await __readResult({ process: processId, message: message })
  return processId
}

export async function sendMonitorCommand({ process }) {
  const { jwk, address } = await __getJWKAndWallet()
  const signer = createDataItemSigner(jwk)
  const res = await connect().monitor({ process, signer })
  return res
}

export async function sendEvalMessage({ process, data }) {
  const res = await _sendEvalMessage({ process, data })
  const result = await __readResult({ process, message: res })
  return result
}

export async function getAddress() {
  const { jwk, address } = await __getJWKAndWallet()
  return address
}


deployProcessWithLua({
  name: "v1.0.3",
  cron: "5-minute",
  luaLocation: "apus_token/main.lua",
  delayTime: "0"
})