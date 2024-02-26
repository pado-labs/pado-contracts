const hre = require("hardhat");

async function main() {
  const [deployer] = await hre.ethers.getSigners();
  console.log(
    "create schema with the account:",
    deployer.address
  );

  const balance = await hre.ethers.provider.getBalance(deployer.address);
  console.log("balance=", balance);
  const nonce = await hre.ethers.provider.getTransactionCount(deployer.address);
  console.log("nonce=", nonce);

  const contractAddr = "0x65CFBDf1EA0ACb7492Ecc1610cfBf79665DC631B"; // opbnb testnet
  const schemaRegistryContract = await hre.ethers.getContractAt("ISchemaRegistry", contractAddr);
  
  const res = await schemaRegistryContract.register('string ProofType,string Source,string Content,string Condition,bytes32 SourceUserIdHash,bool Result,uint64 Timestamp,bytes32 UserIdHash', 
    '0x0000000000000000000000000000000000000000', 
    true
  );
  console.log('res=', res);
  await res.wait();

  const afterres = await schemaRegistryContract.getSchema("0x5f868b117fd34565f3626396ba91ef0c9a607a0e406972655c5137c6d4291af9");
  console.log('afterres=', afterres);

}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
