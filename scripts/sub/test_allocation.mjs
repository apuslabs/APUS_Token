import { EthereumSigner, createData } from '@dha-team/arbundles'
import { connect } from '@permaweb/aoconnect'
import fs from 'fs'
import { ethers } from 'ethers';
import Big from 'big.js'
import { asyncWithBreathingLog, simpleSuccess } from '../lib/async_with_log.mjs';

//const key = fs.readFileSync("./pkey", "utf-8").replace("\n", "")
const keys = [
  '31d4bef2cb8175914e82ca90b66b68f6b073109c8cd153126d168275eea46887',
  'cc2251a5e7888efaa9988c1eb1c6dbfd6de10b922973dc305e42a6636924c97a',
  'd1deda9151376dbf0e2f0f7ab6c37dfaac52041e7460d35432c101d6c1aa789c',
  'ba2c54a98cd30791096414fbd91dac021206e01933f621d102cc061c110dd16f',
  'd773446a849571bf188f30dbaf66c0b107df0af391b5bbbfb58aaa64b8c83d20',
  '8f44aad553dbb3aa5447115fc742663f3527d5c66d74a0048b304e72fec770ad',
  '51fb2f65003bc5278a107a111d1e1246cc28210fe635800f088f602d1f037823',
  '39de1353f76e252fd3c3c0d9365e9a6cd91326ed375581396116d2495d22be02',
  '2ade6930adc8a79f8d53a9c833bf2deb035466374946ce0207db7682f0459515',
  '9eb2890c60f8c784419fff781418e9b0d3734c677e3753cf7dd95b2afb9ce312'
]

// const AO_MINT = "LPK-D_3gZkXtia6ywwU1wRwgFOZ-eLFRMP9pfAFRfuw" // only env
const AO_MINT = "VhadaUKwZVN9mWp3_4fIlfuBeGW19FzNgyvpfcNGi0E"

const TargetValue = new Big('1' + "0".repeat(33))

function generateRandomString(length) {
  const characters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
  let result = '';
  for (let i = 0; i < length; i++) {
    const randomIndex = Math.floor(Math.random() * characters.length);
    result += characters[randomIndex];
  }
  return result;
}

export async function sendMessage(msg, key) {
  function createDataItemSigner(wallet) {
    const signer = async ({ data, tags, target, anchor }) => {
      const signer = new EthereumSigner(wallet)
      const dataItem = createData(data, signer, { tags, target, anchor })
      return dataItem.sign(signer)
        .then(async () => ({
          id: await dataItem.id,
          raw: await dataItem.getRaw()
        }))
    }

    return signer
  }

  const signer = createDataItemSigner(key)
  const message = await connect().message({
    process: AO_MINT,
    signer,
    data: msg.Data || Date.now().toString(),
    tags: msg.Tags
  })
  return await connect().result({ process: AO_MINT, message })
}


export async function getAllocationTable(key, asset) {
  try {
    // 创建钱包对象
    const wallet = new ethers.Wallet(key);

    // 获取地址
    const address = wallet.address;
    const result = await sendMessage({
      Tags: [
        { name: 'Action', value: 'User.Get-Allocation' },
        { name: 'Token', value: asset },
        { name: 'User', value: address },
        { name: "_n", value: generateRandomString(32) },
      ]
    }, key);
    if (result && result.Messages && Array.isArray(result.Messages) && result.Messages.length > 0) {
      return JSON.parse(result.Messages[0].Data)
    } else {
      throw Error(JSON.stringify(result.Error))
    }
  } catch (error) {
    throw error
  }
}


export async function setAllocationTable(key, allocationTable, asset) {
  try {
    // 创建钱包对象
    const wallet = new ethers.Wallet(key);

    // 获取地址
    const address = wallet.address;
    const result = await sendMessage({
      Tags: [
        { name: 'Action', value: 'User.Update-Allocation' },
        { name: 'Token', value: asset },
        { name: 'User', value: address },
        { name: "_n", value: generateRandomString(32) },
      ],
      Data: JSON.stringify(allocationTable)
    }, key);
    if (result && result.Messages && Array.isArray(result.Messages) && result.Messages.length > 0) {
      return JSON.parse(result.Messages[0].Data)
    } else {
      throw Error(JSON.stringify(result.Error))
    }
  } catch (error) {
    throw error
  }
}

export async function testDeposit(amount, key, asset, target) {
  try {
    // 创建钱包对象
    const wallet = new ethers.Wallet(key);

    // 获取地址
    const address = wallet.address;
    const result = await sendMessage({
      Tags: [
        { name: 'Action', value: 'Test.Deposit' },
        { name: 'Token', value: asset },
        { name: 'User', value: address },
        {
          name: 'Recipient', value: target
        },
        { name: "_n", value: generateRandomString(32) },
      ],
      Data: amount + "0".repeat(16)
    }, key);

    if (result && result.Messages && Array.isArray(result.Messages) && result.Messages.length > 0) {
      return result.Messages[0].Data
    } else {
      throw Error("Deposit failed")
    }
  } catch (error) {
    console.error('Error:', error);
  }
}

async function checkSingleUserBalance(key, asset, argv) {
  try {
    const wallet = new ethers.Wallet(key);
    const allocationTable = await asyncWithBreathingLog(getAllocationTable, [key, asset], `Fetch allocation table of User ${wallet.address}`)
    let totalBalance = (allocationTable ?? []).reduce(function (acc, v) {
      return Big(acc).plus(Big(v.Amount)).toFixed(); // 累加并转换回字符串
    }, "0")

    let totalBalanceForTarget = (allocationTable ?? []).reduce(function (acc, v) {
      if (v.Recipient == argv.target) {
        return Big(acc).plus(Big(v.Amount)).toFixed(); // 累加并转换回字符串
      } else {
        return acc
      }
    }, "0")

    if (Big(totalBalance).lt(TargetValue)) {
      const subtractValue = Big(TargetValue).minus(totalBalance).toFixed()

      totalBalance = Big(totalBalance).plus(subtractValue).toFixed()
      totalBalanceForTarget = Big(totalBalanceForTarget).plus(subtractValue).toFixed()
      await asyncWithBreathingLog(testDeposit, [subtractValue, key, asset, argv.target], `Add Deposit for user ${wallet.address}`)
    }
    if (totalBalance == totalBalanceForTarget) {
      simpleSuccess(`Allocation complete`)
    } else {
      const newAllocationTable = [
        {
          "Recipient": argv.target,
          "Amount": totalBalance
        }
      ]
      await asyncWithBreathingLog(setAllocationTable, [key, newAllocationTable, asset], `Update allocation table for user ${wallet.address} recipient: ${argv.target}`)
    }
  } catch (err) {
    throw err
  }
}

async function checkBalance(argv) {
  for (let i = 0; i < keys.length; i++) {
    const asset = i % 2 == 0 ? "stETH" : 'DAI'
    await checkSingleUserBalance(keys[i], asset, argv)
  }
}

export async function testAllocation(argv) {
  checkBalance(argv)
  // console.log(TargetValue.toFixed())
  //arweave-keyfile-wU4TFTVHL8vNuw8tNgab6bimvOh1S-V4I1xkYEQTDFQ.json
}