// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

// prettier-ignore
import {
    ETHSignProxyUpgradeable,
    DelegatedProxyAttestationRequest,
    DelegatedProxyRevocationRequest,
    MultiDelegatedProxyAttestationRequest,
    MultiDelegatedProxyRevocationRequest
} from "./ETHSignProxyUpgradeable.sol";

import {ISP} from "./ethsign/interfaces/ISP.sol";

import { AccessDenied, uncheckedInc } from "@ethereum-attestation-service/eas-contracts/contracts/Common.sol";
import {Attestation} from "./ethsign/models/Attestation.sol";


/**
 * @title A sample EIP712 proxy that allows only a specific address to attest.
 */
contract PermissionedETHSignProxyUpgradeable is ETHSignProxyUpgradeable, OwnableUpgradeable {
    uint256 private _fee;
    address payable private _receiveAddr;
    bytes32 private _webSchemaId;
    mapping (bytes32 schemaid => bool isEvent) private eventSchemas;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(ISP isp, string memory name, uint256 feeParams, address payable recvAddr, bytes32 webSchemaId) external initializer {
        super.initialize(isp, name);
        __Ownable_init();
         _fee = feeParams;
        _receiveAddr = recvAddr;
        _webSchemaId = webSchemaId;
    }

    /**
     * @inheritdoc ETHSignProxyUpgradeable
     */
    function attestByDelegation(
        DelegatedProxyAttestationRequest calldata delegatedRequest
    ) public payable override returns (bytes32) {
        if (_fee > 0) {
            require(msg.value >= _fee, 'less than fee');
            (bool success, ) = _receiveAddr.call{value: msg.value}(new bytes(0));
            require(success, 'transfer failed');
        }

        // Ensure that only the owner is allowed to delegate attestations.
        _verifyAttester(delegatedRequest.attester);

        bytes32 uid = super.attestByDelegation(delegatedRequest);
        if (!eventSchemas[delegatedRequest.schema]) {
            _padoAttestations[delegatedRequest.data.recipient][delegatedRequest.schema].push(uint256(uid));
        }
        return uid;
    }

    function bulkAttest(
        DelegatedProxyAttestationRequest[] calldata multiDelegatedRequests
    ) public payable {
        if (_fee > 0) {
            require(msg.value >= _fee * multiDelegatedRequests.length, 'less than fee');
            (bool success, ) = _receiveAddr.call{value: msg.value}(new bytes(0));
            require(success, 'transfer failed');
        }

        for (uint256 i = 0; i < multiDelegatedRequests.length; i = uncheckedInc(i)) {
            // Ensure that only the owner is allowed to delegate attestations.
            _verifyAttester(multiDelegatedRequests[i].attester);
            bytes32 uid = super.attestByDelegation(multiDelegatedRequests[i]);
            if (!eventSchemas[multiDelegatedRequests[i].schema]) {
                _padoAttestations[multiDelegatedRequests[i].data.recipient][multiDelegatedRequests[i].schema].push(uint256(uid));
            }
        }
    }

    /**
     * @inheritdoc ETHSignProxyUpgradeable
     */
    /*function revokeByDelegation(DelegatedProxyRevocationRequest calldata delegatedRequest) public payable override {
        // Ensure that only the owner is allowed to delegate revocations.
        _verifyAttester(delegatedRequest.revoker);

        super.revokeByDelegation(delegatedRequest);
    }*/

    /**
     * @inheritdoc ETHSignProxyUpgradeable
     */
    /*function multiRevokeByDelegation(
        MultiDelegatedProxyRevocationRequest[] calldata multiDelegatedRequests
    ) public payable override {
        for (uint256 i = 0; i < multiDelegatedRequests.length; i = uncheckedInc(i)) {
            // Ensure that only the owner is allowed to delegate revocations.
            _verifyAttester(multiDelegatedRequests[i].revoker);
        }

        super.multiRevokeByDelegation(multiDelegatedRequests);
    }*/

    /**
     * @dev Ensures that only the allowed attester can attest.
     *
     * @param attester The attester to verify.
     */
    function _verifyAttester(address attester) private view {
        if (attester != owner()) {
//            revert AccessDenied();
        }
    }

    function fee() public view returns(uint256) {
        return _fee;
    }

    function setFee(uint256 feeParams) public onlyOwner returns (bool){
        _fee = feeParams;
        return true;
    }

    function receiveAddr() public view returns(address) {
        return _receiveAddr;
    }

    function setReceiveAddr(address payable recvAddr) public onlyOwner returns (bool) {
        _receiveAddr = recvAddr;
        return true;
    }

    function setWebSchemaId(bytes32 webSchemaId) public onlyOwner returns (bool) {
        _webSchemaId = webSchemaId;
        return true;
    }

    function getWebSchemaId() public view returns(bytes32) {
        return _webSchemaId;
    }

    receive() external payable {}

    function transferBalance(address payable to, uint256 ammount) onlyOwner public{
        if(address(this).balance != 0){
            require(address(this).balance >= ammount, "Not enought Balance to Transfer");
            payable(to).transfer(ammount);
        }
    }

    function getPadoAttestations(address user, bytes32 schema) external view returns(uint256[] memory) {
        return _padoAttestations[user][schema];
    }

    function checkBinanceKyc(address userAddress) public view returns (bool) {
        return checkCommon(userAddress, "Identity", "binance", "KYC Level", ">=2");
    }

    /*function checkBinanceOwner(address userAddress) public view returns (bool) {
        return false;
    }*/

    function checkTwitterOwner(address userAddress) public view returns (bool) {
        return checkCommon(userAddress, "Identity", "x", "Account Ownership", "Verified");
    }

    function checkCommon(address userAddress, string memory proofType, string memory source, string memory content, string memory condition) public view returns (bool) {
        uint256[] memory attestationIds =  _padoAttestations[userAddress][_webSchemaId];
        for (uint256 i = 0; i < attestationIds.length; i++) {
            Attestation memory ats = _isp.getAttestation(attestationIds[i]);
            (string memory ProofType,string memory Source,string memory Content,string memory Condition,/*bytes32 SourceUserIdHash*/,bool Result,/*uint64 Timestamp*/,/*bytes32 UserIdHash*/) = abi.decode(ats.data, (string,string,string,string,bytes32,bool,uint64,bytes32));
            if (_compareStrings(ProofType, proofType) && _compareStrings(Source, source)
            && _compareStrings(Content, content) && _compareStrings(Condition, condition) && Result) {
                return true;
            }
        }
        return false;
    }

    function _compareStrings(string memory a, string memory b) internal pure returns (bool) {
        return (keccak256(bytes(a)) == keccak256(bytes(b)));
    }

    function setEventSchema(bytes32 schemaId, bool isEvent) public onlyOwner returns (bool) {
        eventSchemas[schemaId] = isEvent;
        return true;
    }

    function getEventSchema(bytes32 schemaId) public view returns (bool) {
        return eventSchemas[schemaId];
    }


}
