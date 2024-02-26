// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

// prettier-ignore
import {
    EIP712Proxy,
    DelegatedProxyAttestationRequest,
    DelegatedProxyRevocationRequest,
    MultiDelegatedProxyAttestationRequest,
    MultiDelegatedProxyRevocationRequest
} from "./EIP712Proxy.sol";

import { IEAS } from "@ethereum-attestation-service/eas-contracts/contracts/IEAS.sol";

import { AccessDenied, uncheckedInc } from "@ethereum-attestation-service/eas-contracts/contracts/Common.sol";

/**
 * @title A sample EIP712 proxy that allows only a specific address to attest.
 */
contract PermissionedEIP712Proxy is EIP712Proxy, Ownable {
    uint256 private _fee;
    address payable private _receiveAddr;

    /**
     * @dev Creates a new PermissionedEIP712Proxy instance.
     *
     * @param eas The address of the global EAS contract.
     * @param name The user readable name of the signing domain.
     */
    constructor(IEAS eas, string memory name, uint256 feeParams, address payable recvAddr) EIP712Proxy(eas, name) {
        _fee = feeParams;
        _receiveAddr = recvAddr;
    }

    /**
     * @inheritdoc EIP712Proxy
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
        _padoAttestations[delegatedRequest.data.recipient][delegatedRequest.schema].push(uid);
        return uid;
    }

    /**
     * @inheritdoc EIP712Proxy
     */
    function bulkAttest(
        MultiDelegatedProxyAttestationRequest[] calldata multiDelegatedRequests
    ) public payable override returns (bytes32[] memory) {
        if (_fee > 0) {
            require(msg.value >= _fee, 'less than fee');
            (bool success, ) = _receiveAddr.call{value: msg.value}(new bytes(0));
            require(success, 'transfer failed');
        }

        for (uint256 i = 0; i < multiDelegatedRequests.length; i = uncheckedInc(i)) {
            // Ensure that only the owner is allowed to delegate attestations.
            _verifyAttester(multiDelegatedRequests[i].attester);
        }

        return super.bulkAttest(multiDelegatedRequests);
    }

    /**
     * @inheritdoc EIP712Proxy
     */
    function revokeByDelegation(DelegatedProxyRevocationRequest calldata delegatedRequest) public payable override {
        // Ensure that only the owner is allowed to delegate revocations.
        _verifyAttester(delegatedRequest.revoker);

        super.revokeByDelegation(delegatedRequest);
    }

    /**
     * @inheritdoc EIP712Proxy
     */
    function multiRevokeByDelegation(
        MultiDelegatedProxyRevocationRequest[] calldata multiDelegatedRequests
    ) public payable override {
        for (uint256 i = 0; i < multiDelegatedRequests.length; i = uncheckedInc(i)) {
            // Ensure that only the owner is allowed to delegate revocations.
            _verifyAttester(multiDelegatedRequests[i].revoker);
        }

        super.multiRevokeByDelegation(multiDelegatedRequests);
    }

    /**
     * @dev Ensures that only the allowed attester can attest.
     *
     * @param attester The attester to verify.
     */
    function _verifyAttester(address attester) private view {
        if (attester != owner()) {
            revert AccessDenied();
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

    receive() external payable {}

    function transferBalance(address payable to, uint256 ammount) onlyOwner public{
        if(address(this).balance != 0){
            require(address(this).balance >= ammount, "Not enought Balance to Transfer");
            payable(to).transfer(ammount);
        }
    }

    function getPadoAttestations(address user, bytes32 schema) external view returns(bytes32[] memory) {
        return _padoAttestations[user][schema];
    }
}
