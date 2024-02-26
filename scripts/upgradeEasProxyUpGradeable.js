// import { ethers, upgrades } from "hardhat";
const { ethers, upgrades } =  require("hardhat");

async function main() {
    const [deployer] = await ethers.getSigners();
    console.log(
        "Deploying contracts with the account:",
        deployer.address
    );
    //const permissionedEIP712ProxyUpgradeableAddress = "0x620e84546d71A775A82491e1e527292e94a7165A"; // bnb testnet
    const permissionedEIP712ProxyUpgradeableAddress = "0x70e8E6c3c90e17905F9326A3Cc4bFF5a4637705E"; // bnb mainnet
    console.log("Checking PermissionedEIP712ProxyUpgradeable...");
    const PermissionedEIP712ProxyUpgradeable = await ethers.getContractFactory("PermissionedEIP712ProxyUpgradeable");
    await upgrades.validateImplementation(PermissionedEIP712ProxyUpgradeable);
    console.log("PermissionedEIP712ProxyUpgradeable OK");

    console.log("start to upgrade")
    console.log("Upgrading PermissionedEIP712ProxyUpgradeable, with proxy at", permissionedEIP712ProxyUpgradeableAddress);
    await upgrades.upgradeProxy(permissionedEIP712ProxyUpgradeableAddress, PermissionedEIP712ProxyUpgradeable);

    console.log(`PermissionedEIP712ProxyUpgradeable successfully upgraded!`);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
