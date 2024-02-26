const hre = require("hardhat");

async function main() {
  const easaddress = "0xC2679fBD37d54388Ce493F1DB75320D236e1815e";
  //const easaddress = "0xbD75f629A22Dc1ceD33dDA0b68c546A1c035c458";
  const fee = "60000000000000";
  const receiveAddr = "0x628aA2FA4AFd4363A731a6a99448e6cf4b3E1Fcf";
  const proxycontract = await hre.ethers.deployContract("PermissionedEIP712Proxy", [easaddress, "PermissionedEIP712Proxy", fee, receiveAddr]);
  await proxycontract.waitForDeployment();
  console.log(`nftcontract deployed to ${proxycontract.target}`);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});

