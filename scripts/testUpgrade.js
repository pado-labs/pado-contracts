const hre = require("hardhat");

async function main() {
    const contract  = await hre.ethers.getContractAt("PermissionedEIP712ProxyUpgradeable","0x915327d89CB2a5ED7Fc6c80E095B93099E43438d")
    console.log("set addr")
    await contract.setTestAddr("0x6b28B1D10D45fD811a9fb48Ed60E394f7cB8D34f");
    console.log("get addr")
    const fee = await contract.getTestAddr();
    console.log(`addr is ${fee}`)
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
