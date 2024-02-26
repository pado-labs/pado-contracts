// import { ethers, upgrades } from "hardhat";
const { ethers, upgrades } =  require("hardhat");

async function main() {
    const [deployer] = await ethers.getSigners();
    console.log(
        "Deploying contracts with the account:",
        deployer.address
    );
    //const permissionedEIP712ProxyUpgradeableAddress = "0x620e84546d71A775A82491e1e527292e94a7165A"; //
    const permissionedEIP712ProxyUpgradeableAddress = "0x2A45DEF86e7bf8Cd85514aeB1e811ED32D72Ac06"; // mumbai
    console.log("Checking PermissionedETHSignProxyUpgradeable...");
    const permissionedETHSignProxyUpgradeable = await ethers.getContractFactory("PermissionedETHSignProxyUpgradeable");
    await upgrades.validateImplementation(permissionedETHSignProxyUpgradeable);
    console.log("PermissionedETHSignProxyUpgradeable OK");

    console.log("start to upgrade")
    console.log("Upgrading PermissionedEIP712ProxyUpgradeable, with proxy at", permissionedEIP712ProxyUpgradeableAddress);
    await upgrades.upgradeProxy(permissionedEIP712ProxyUpgradeableAddress, permissionedETHSignProxyUpgradeable);

    console.log(`PermissionedETHSignProxyUpgradeable successfully upgraded!`);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
