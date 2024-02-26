const hre = require("hardhat");

async function main() {
  const padoContract = await hre.ethers.getContractAt("PADOERC721A", '0x0abe45De70bBd82409D3C640b7d4c30d3B0b5b1f');
  const res = await padoContract.changeBaseUri('https://xuda-note.oss-cn-shanghai.aliyuncs.com/nft_meta/');
  console.log('res=', res);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
