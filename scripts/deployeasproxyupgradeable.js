const hre = require("hardhat");

async function main() {
  const [deployer] = await hre.ethers.getSigners();
  console.log(
  "Deploying contracts with the account:",
  deployer.address
  );

  //const easaddress = "0xC2679fBD37d54388Ce493F1DB75320D236e1815e";
  //const easaddress = "0xbD75f629A22Dc1ceD33dDA0b68c546A1c035c458";
  //const easaddress = "0x6c2270298b1e6046898a322acB3Cbad6F99f7CBD"; // bsctestnet
  //const easaddress = "0x247Fe62d887bc9410c3848DF2f322e52DA9a51bC"; // bsc mainnet
  const easaddress = "0x5e905F77f59491F03eBB78c204986aaDEB0C6bDa"; // opbnb testnet
  const fee = "0";
  const receiveAddr = "0x95DE54300C06E11f348874f30c5c66F5787437d2";
  const webSchemaId = "0x5f868b117fd34565f3626396ba91ef0c9a607a0e406972655c5137c6d4291af9";
  //const proxycontract = await hre.ethers.deployContract("PermissionedEIP712Proxy", [easaddress, "PermissionedEIP712Proxy", fee, receiveAddr]);
  //await proxycontract.waitForDeployment();
  //console.log(`nftcontract deployed to ${proxycontract.target}`);

  console.log("Deploying PermissionedEIP712ProxyUpgradeable...");
  const easproxycontract = await hre.ethers.getContractFactory("PermissionedEIP712ProxyUpgradeable");
  const easproxy = await hre.upgrades.deployProxy(easproxycontract, 
    [easaddress, "PermissionedEIP712Proxy", fee, receiveAddr, webSchemaId], {initializer: 'initialize'});
  await easproxy.waitForDeployment();
  const easproxyProxyAddress = await easproxy.getAddress();
  const easproxyImplementationAddress = await hre.upgrades.erc1967.getImplementationAddress(easproxyProxyAddress);
  const adminAddress = await upgrades.erc1967.getAdminAddress(easproxyProxyAddress);

  //await hre.run("verify:verify", {
  //  address: easproxyProxyAddress,
  //});

  console.log(`Proxy is at ${easproxyProxyAddress}`);
  console.log(`Implementation is at ${easproxyImplementationAddress}`);
  console.log(`adminAddress is at ${adminAddress}`);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
