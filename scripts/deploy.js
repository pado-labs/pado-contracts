const hre = require("hardhat");

async function main() {
  const nftcontract = await hre.ethers.deployContract("PADOERC721A");
  await nftcontract.waitForDeployment();
  console.log(`nftcontract deployed to ${nftcontract.target}`);

  const padoContract = await hre.ethers.getContractAt("PADOERC721A", nftcontract.target);
  const addr = '0xDB736B13E2f522dBE18B2015d0291E4b193D8eF6';
  const res = await padoContract.initialize('PADO Early Adopters', 'PADOEA', 'https://pado-online.s3.ap-northeast-1.amazonaws.com/nft_meta/', addr, 0, 1000, addr, 1, 0, '');
  console.log('res=', res);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
