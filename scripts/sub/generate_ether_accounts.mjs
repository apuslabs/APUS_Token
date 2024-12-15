import { ethers } from "ethers";

// 批量生成地址和私钥
export default function generateTestAddresses(count) {
  const addresses = [];
  for (let i = 0; i < count; i++) {
    const wallet = ethers.Wallet.createRandom(); // 创建随机钱包
    addresses.push({
      address: wallet.address,
      privateKey: wallet.privateKey,
    });
  }
  return addresses;
}