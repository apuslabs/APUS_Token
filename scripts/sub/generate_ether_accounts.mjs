import { ethers } from "ethers";

export default function generateTestAddresses(count) {
  const addresses = [];
  for (let i = 0; i < count; i++) {
    const wallet = ethers.Wallet.createRandom();
    addresses.push({
      address: wallet.address,
      privateKey: wallet.privateKey,
    });
  }
  return addresses;
}