const { expect } = require("chai");
const {ethers} = require("hardhat");
const hre = require("hardhat");
const {keccak256} = require("hardhat/internal/util/keccak");

describe("Token contract", function () {
    it("Deployment Contract", async function (){
        const [owner] = await ethers.getSigners();
        console.log("deployer account is:",owner.address);
       // console.log("ATTEST_PROXY_TYPEHASH:",keccak256("Attest(uint schema,address recipient,uint64 expirationTime,bool revocable,bytes32 refUID,bytes data,uint64 deadline)").toString('hex'));

        const ethSignAddress = "0xEadFcE1eA8c2BB0DE3Cc3854076E1900373Aae59"; // polygon mumbai
        const fee = "0000000000000000";
        const receiveAddr = "0x024e45D7F868C41F3723B13fD7Ae03AA5A181362";
        const webSchemaId = "0x000000000000000000000000000000000000000000000000000000000000000d";

        // await hardhatToken.initialize(ethSignAddress, "PermissionedEIP712Proxy", fee, receiveAddr, webSchemaId)
        // const hardhatToken = await ethers.deployContract("PermissionedETHSignProxyUpgradeable",[ethSignAddress, "PermissionedEIP712Proxy", fee, receiveAddr, webSchemaId],{initializer: 'initialize'});
        const easproxycontract = await hre.ethers.getContractFactory("PermissionedETHSignProxyUpgradeable");
        const hardhatToken = await hre.upgrades.deployProxy(easproxycontract,
            [ethSignAddress, "PermissionedEIP712Proxy", fee, receiveAddr, webSchemaId], {initializer: 'initialize'});

        // const ownerBalance = await hardhatToken.fee();
        // console.log(ownerBalance)
        const res = await hardhatToken.uint64ToBytes32(0x3);
        const res2 = await hardhatToken.getUint64ValueFromBytes32(res);
        console.log(res)
        console.log(res2)
        // console.log(res2)
    });
});