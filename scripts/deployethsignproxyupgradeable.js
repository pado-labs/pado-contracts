const hre = require("hardhat");

async function main() {
  const [deployer] = await hre.ethers.getSigners();
  console.log(
  "Deploying contracts with the account:",
  deployer.address
  );

  const ethSignAddress = "0x4665fffdD8b48aDF5bab3621F835C831f0ee36D7"; // polygon mumbai
  const fee = "0000000000000000";
  const receiveAddr = "0x024e45D7F868C41F3723B13fD7Ae03AA5A181362";
  const webSchemaId = "0x0000000000000000000000000000000000000000000000000000000000000001";

  console.log("Deploying PermissionedETHSignProxyUpgradeable...");
  const easproxycontract = await hre.ethers.getContractFactory("PermissionedETHSignProxyUpgradeable");
  const easproxy = await hre.upgrades.deployProxy(easproxycontract, 
    [ethSignAddress, "PermissionedEIP712Proxy", fee, receiveAddr, webSchemaId], {initializer: 'initialize'});

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
