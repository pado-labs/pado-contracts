const hre = require("hardhat");

async function main() {
  const [deployer] = await hre.ethers.getSigners();
  console.log(
    "Deploying contracts with the account:",
    deployer.address
  );

  const contractAddr = "0x70e8E6c3c90e17905F9326A3Cc4bFF5a4637705E";
  //const contractAddr = "0xBF4221C5f98349FACbB28D0ea7bbc57a6834Bfe1";
  const easProxyContract = await hre.ethers.getContractAt("PermissionedEIP712ProxyUpgradeable", contractAddr);
  
  const receiveAddr = await easProxyContract.receiveAddr();
  console.log('receiveAddr=', receiveAddr);

  const beforeres = await easProxyContract.fee();
  console.log('beforeres=', beforeres);

  //const res = await easProxyContract.transferOwnership('0xe02bD7a6c8aA401189AEBb5Bad755c2610940A73');
  //console.log('res=', res);
  //await res.wait();
  
  /*const res = await easProxyContract.setFee('0x0');
  console.log('res=', res);
  await res.wait();

  const afterres = await easProxyContract.fee();
  console.log('afterres=', afterres);*/

  const schemaid = "0x07656ef97ae97711b79c9e79b3e0409712a8bb9bf26f3495ad15f48cdd49cfac";
  const beforeschemares = await easProxyContract.getEventSchema(schemaid);
  console.log('beforeres=', beforeschemares);

  /*const res = await easProxyContract.setEventSchema(schemaid, true);
  console.log('res=', res);
  await res.wait();

  const afterres = await easProxyContract.getEventSchema(schemaid);
  console.log('afterres=', afterres);*/

  const useraddr = "0x7ab44DE0156925fe0c24482a2cDe48C465e47573";
  const commonschemeid = "0x5f868b117fd34565f3626396ba91ef0c9a607a0e406972655c5137c6d4291af9";
  const eventschemaid = "0x07656ef97ae97711b79c9e79b3e0409712a8bb9bf26f3495ad15f48cdd49cfac";
  const res = await easProxyContract.getPadoAttestations(useraddr, eventschemaid);
  console.log('res=', res);



}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
