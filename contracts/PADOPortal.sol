// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import { EIP712 } from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import { ECDSA } from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { AbstractPortal } from "./interface/AbstractPortal.sol";
import { AttestationPayload } from "./types/Structs.sol";

contract PADOPortal is AbstractPortal, EIP712, Ownable {
  struct AttestationRequestData {
    address recipient;
    uint64 expirationTime;
    bool revocable;
    bytes32 refUID;
    bytes data;
    uint256 value;
  }

  struct EIP712Signature {
    uint8 v; // The recovery ID.
    bytes32 r; // The x-coordinate of the nonce R.
    bytes32 s; // The signature data.
  }

  struct DelegatedProxyAttestationRequest {
    bytes32 schema; // The unique identifier of the schema.
    AttestationRequestData data; // The arguments of the attestation request.
    EIP712Signature signature; // The EIP712 signature data.
    address attester; // The attesting account.
    uint64 deadline; // The deadline of the signature/request.
  }

  error DeadlineExpired();
  error UsedSignature();
  error InvalidSignature();
  error AccessDenied();
  error NoRevocation();
  error NoBulkRevocation();

  uint64 constant NO_EXPIRATION_TIME = 0;
  string public constant VERSION = "0.1";
  // keccak256("Attest(bytes32 schema,address recipient,uint64 expirationTime,bool revocable,bytes32 refUID,bytes data,uint64 deadline)").
  bytes32 private constant ATTEST_PROXY_TYPEHASH = 0x4120d3b28306666b714826ad7cb70744d9658ad3e6cd873411bedadcf55afda7;

  string private _name;
  uint256 private _fee;
  address payable private _receiveAddr;

  constructor(string memory name, uint256 feeParams, address payable recvAddr) EIP712(name, VERSION) {
    _name = name;
    _fee = feeParams;
    _receiveAddr = recvAddr;
  }

  function _beforeAttest(AttestationPayload memory attestation, uint256 value) internal override {}

  function _afterAttest() internal override {}

  function _onRevoke(bytes32 attestationId, bytes32 replacedBy) internal override {}

  function _onBulkAttest(
    AttestationPayload[] memory attestationsPayloads,
    bytes[][] memory validationPayloads
  ) internal override {}

  function _onBulkRevoke(bytes32[] memory attestationIds, bytes32[] memory replacedBy) internal override {}

  function attest(DelegatedProxyAttestationRequest memory attestationRequest) external payable {
    _verifyAttest(attestationRequest);

    if (_fee > 0) {
      require(msg.value >= _fee, 'less than fee');
      (bool success, ) = _receiveAddr.call{value: msg.value}(new bytes(0));
      require(success, 'transfer failed');
    }

    bytes[] memory validationPayload = new bytes[](0);
    AttestationPayload memory attestationPayload = AttestationPayload(
      attestationRequest.schema,
      attestationRequest.data.expirationTime,
      abi.encodePacked(attestationRequest.data.recipient),
      attestationRequest.data.data
    );

    super.attest(attestationPayload, validationPayload);
  }

  function bulkAttest(DelegatedProxyAttestationRequest[] memory attestationsRequests) external payable {
    for (uint256 i = 0; i < attestationsRequests.length; i++) {
      _verifyAttest(attestationsRequests[i]);
    }

    if (_fee > 0) {
      require(msg.value >= _fee, 'less than fee');
      (bool success, ) = _receiveAddr.call{value: msg.value}(new bytes(0));
      require(success, 'transfer failed');
    }

    AttestationPayload[] memory attestationsPayloads = new AttestationPayload[](attestationsRequests.length);
    bytes[][] memory validationPayloads = new bytes[][](attestationsRequests.length);
    for (uint256 i = 0; i < attestationsRequests.length; i++) {
      attestationsPayloads[i] = AttestationPayload(
        attestationsRequests[i].schema,
        attestationsRequests[i].data.expirationTime,
        abi.encodePacked(attestationsRequests[i].data.recipient),
        attestationsRequests[i].data.data
      );

      validationPayloads[i] = new bytes[](0);
    }

    super.bulkAttest(attestationsPayloads, validationPayloads);
  }

  function revoke(bytes32 /*attestationId*/, bytes32 /*replacedBy*/) public pure override {
    revert NoRevocation();
  }

  function bulkRevoke(bytes32[] memory /*attestationIds*/, bytes32[] memory /*replacedBy*/) public pure override {
    revert NoBulkRevocation();
  }

  function getName() external view returns (string memory) {
    return _name;
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

  function _verifyAttest(DelegatedProxyAttestationRequest memory request) internal view {
    if (request.attester != owner()) {
      revert AccessDenied();
    }
    if (request.deadline != NO_EXPIRATION_TIME && request.deadline <= _time()) {
      revert DeadlineExpired();
    }

    AttestationRequestData memory data = request.data;
    EIP712Signature memory signature = request.signature;

    //_verifyUnusedSignature(signature);

    bytes32 digest = _hashTypedDataV4(
      keccak256(
        abi.encode(
          ATTEST_PROXY_TYPEHASH,
          request.schema,
          data.recipient,
          data.expirationTime,
          data.revocable,
          data.refUID,
          keccak256(data.data),
          request.deadline
        )
      )
    );

    if (ECDSA.recover(digest, signature.v, signature.r, signature.s) != request.attester) {
      revert InvalidSignature();
    }
  }

  function _time() internal view virtual returns (uint64) {
    return uint64(block.timestamp);
  }

  function _getAttester() public view override returns (address) {
    return owner();
  }
}
