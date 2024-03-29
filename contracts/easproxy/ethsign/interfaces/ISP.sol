// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { IVersionable } from "./IVersionable.sol";
import { Schema } from "../models/Schema.sol";
import { Attestation, OffchainAttestation } from "../models/Attestation.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title Sign Protocol Interface
 * @author Jack Xu @ EthSign
 */
interface ISP is IVersionable {
    event SchemaRegistered(uint256 schemaId);
    event AttestationMade(uint256 attestationId, string indexingKey);
    event AttestationRevoked(uint256 attestationId, string reason);
    event OffchainAttestationMade(string attestationId);
    event OffchainAttestationRevoked(string attestationId, string reason);

    /**
     * @dev 0x38f8c6c4
     */
    error SchemaNonexistent(uint256 nonexistentSchemaId);
    /**
     * @dev 0x8ac42f49
     */
    error AttestationIrrevocable(uint256 schemaId, uint256 offendingAttestationId);
    /**
     * @dev 0x54681a13
     */
    error AttestationNonexistent(uint256 nonexistentAttestationId);
    /**
     * @dev 0xa65e02ed
     */
    error AttestationInvalidDuration(uint256 offendingAttestationId, uint64 maxDuration, uint64 inputDuration);
    /**
     * @dev 0xd8c3da86
     */
    error AttestationAlreadyRevoked(uint256 offendingAttestationId);
    /**
     * @dev 0xa9ad2007
     */
    error AttestationWrongAttester(address expected, address actual);
    /**
     * @dev 0xc83e3cdf
     */
    error OffchainAttestationExists(string existingOffchainAttestationId);
    /**
     * @dev 0xa006519a
     */
    error OffchainAttestationNonexistent(string nonexistentOffchainAttestationId);
    /**
     * @dev 0xa0671d20
     */
    error OffchainAttestationAlreadyRevoked(string offendingOffchainAttestationId);
    /**
     * @dev 0xfdf4e6f9
     */
    error InvalidDelegateSignature();

    /**
     * @notice Registers a Schema.
     * @dev Emits `SchemaRegistered`.
     * @param schema See `Schema`.
     * @return schemaId The assigned ID of the registered schema.
     */
    function register(Schema calldata schema) external returns (uint256 schemaId);

    /**
     * @notice Makes an attestation.
     * @dev Emits `AttestationMade`.
     * @param attestation See `Attestation`.
     * @param indexingKey Used by the frontend to aid indexing.
     * @param delegateSignature An optional ECDSA delegateSignature if this is a delegated attestation. Use `""`
     * otherwise.
     * @param extraData This is forwarded to the resolver directly.
     * @return attestationId The assigned ID of the attestation.
     */
    function attest(
        Attestation calldata attestation,
        string calldata indexingKey,
        bytes calldata delegateSignature,
        bytes calldata extraData
    )
        external
        returns (uint256 attestationId);

    /**
     * @notice Makes an attestation where the schema hook expects ETH payment.
     * @dev Emits `AttestationMade`.
     * @param attestation See `Attestation`.
     * @param resolverFeesETH Amount of funds to send to the hook.
     * @param indexingKey Used by the frontend to aid indexing.
     * @param delegateSignature An optional ECDSA delegateSignature if this is a delegated attestation. Use `""`
     * otherwise.
     * @param extraData This is forwarded to the resolver directly.
     * @return attestationId The assigned ID of the attestation.
     */
    function attest(
        Attestation calldata attestation,
        uint256 resolverFeesETH,
        string calldata indexingKey,
        bytes calldata delegateSignature,
        bytes calldata extraData
    )
        external
        payable
        returns (uint256 attestationId);

    /**
     * @notice Makes an attestation where the schema hook expects ERC20 payment.
     * @dev Emits `AttestationMade`.
     * @param attestation See `Attestation`.
     * @param resolverFeesERC20Token ERC20 token address used for payment.
     * @param resolverFeesERC20Amount Amount of funds to send to the hook.
     * @param indexingKey Used by the frontend to aid indexing.
     * @param delegateSignature An optional ECDSA delegateSignature if this is a delegated attestation. Use `""`
     * otherwise.
     * @param extraData This is forwarded to the resolver directly.
     * @return attestationId The assigned ID of the attestation.
     */
    function attest(
        Attestation calldata attestation,
        IERC20 resolverFeesERC20Token,
        uint256 resolverFeesERC20Amount,
        string calldata indexingKey,
        bytes calldata delegateSignature,
        bytes calldata extraData
    )
        external
        returns (uint256 attestationId);

    /**
     * @notice Timestamps an off-chain data ID.
     * @dev Emits `OffchainAttestationMade`.
     * @param offchainAttestationId The off-chain data ID.
     * @param delegateAttester An optional delegated attester that authorized the caller to attest on their behalf if
     * this is a delegated attestation. Use `address(0)` otherwise.
     * @param delegateSignature An optional ECDSA delegateSignature if this is a delegated attestation. Use `""`
     * otherwise. Use `""` otherwise.
     */
    function attestOffchain(
        string calldata offchainAttestationId,
        address delegateAttester,
        bytes calldata delegateSignature
    )
        external;

    /**
     * @notice Revokes an existing revocable attestation.
     * @dev Emits `AttestationRevoked`. Must be called by the attester.
     * @param attestationId An existing attestation ID.
     * @param reason The revocation reason. This is only emitted as an event to save gas.
     * @param delegateSignature An optional ECDSA delegateSignature if this is a delegated revocation.
     * @param extraData This is forwarded to the resolver directly.
     */
    function revoke(
        uint256 attestationId,
        string calldata reason,
        bytes calldata delegateSignature,
        bytes calldata extraData
    )
        external;

    /**
     * @notice Revokes an existing revocable attestation where the schema hook expects ERC20 payment.
     * @dev Emits `AttestationRevoked`. Must be called by the attester.
     * @param attestationId An existing attestation ID.
     * @param reason The revocation reason. This is only emitted as an event to save gas.
     * @param resolverFeesETH Amount of funds to send to the hook.
     * @param delegateSignature An optional ECDSA delegateSignature if this is a delegated revocation.
     * @param extraData This is forwarded to the resolver directly.
     */
    function revoke(
        uint256 attestationId,
        string calldata reason,
        uint256 resolverFeesETH,
        bytes calldata delegateSignature,
        bytes calldata extraData
    )
        external
        payable;

    /**
     * @notice Revokes an existing revocable attestation where the schema hook expects ERC20 payment.
     * @dev Emits `AttestationRevoked`. Must be called by the attester.
     * @param attestationId An existing attestation ID.
     * @param reason The revocation reason. This is only emitted as an event to save gas.
     * @param resolverFeesERC20Token ERC20 token address used for payment.
     * @param resolverFeesERC20Amount Amount of funds to send to the hook.
     * @param delegateSignature An optional ECDSA delegateSignature if this is a delegated revocation.
     * @param extraData This is forwarded to the resolver directly.
     */
    function revoke(
        uint256 attestationId,
        string calldata reason,
        IERC20 resolverFeesERC20Token,
        uint256 resolverFeesERC20Amount,
        bytes calldata delegateSignature,
        bytes calldata extraData
    )
        external;

    /**
     * @notice Revokes an existing offchain attestation.
     * @dev Emits `OffchainAttestationRevoked`. Must be called by the attester.
     * @param offchainAttestationId An existing attestation ID.
     * @param reason The revocation reason. This is only emitted as an event to save gas.
     * @param delegateSignature An optional ECDSA delegateSignature if this is a delegated revocation.
     */
    function revokeOffchain(
        string calldata offchainAttestationId,
        string calldata reason,
        bytes calldata delegateSignature
    )
        external;

    /**
     * @notice Batch registers a Schema.
     */
    function registerBatch(Schema[] calldata schemas) external returns (uint256[] calldata schemaIds);

    /**
     * @notice Batch attests.
     */
    function attestBatch(
        Attestation[] calldata attestations,
        string[] calldata indexingKeys,
        bytes calldata delegateSignature,
        bytes calldata extraData
    )
        external
        returns (uint256[] calldata attestationIds);

    /**
     * @notice Batch attests where the schema hook expects ETH payment.
     */
    function attestBatch(
        Attestation[] calldata attestations,
        uint256[] calldata resolverFeesETH,
        string[] calldata indexingKeys,
        bytes calldata delegateSignature,
        bytes calldata extraData
    )
        external
        payable
        returns (uint256[] calldata attestationIds);

    /**
     * @notice Batch attests where the schema hook expects ERC20 payment.
     */
    function attestBatch(
        Attestation[] calldata attestations,
        IERC20[] calldata resolverFeesERC20Tokens,
        uint256[] calldata resolverFeesERC20Amount,
        string[] calldata indexingKeys,
        bytes calldata delegateSignature,
        bytes calldata extraData
    )
        external
        returns (uint256[] calldata attestationIds);

    /**
     * @notice Batch timestamps off-chain data IDs.
     */
    function attestOffchainBatch(
        string[] calldata offchainAttestationIds,
        address delegateAttester,
        bytes calldata delegateSignature
    )
        external;

    /**
     * @notice Batch revokes revocable on-chain attestations.
     */
    function revokeBatch(
        uint256[] calldata attestationIds,
        string[] calldata reasons,
        bytes calldata delegateSignature,
        bytes calldata extraData
    )
        external;

    /**
     * @notice Batch revokes revocable on-chain attestations where the schema hook expects ETH payment.
     */
    function revokeBatch(
        uint256[] calldata attestationIds,
        string[] calldata reasons,
        uint256[] calldata resolverFeesETH,
        bytes calldata delegateSignature,
        bytes calldata extraData
    )
        external
        payable;

    /**
     * @notice Batch revokes revocable on-chain attestations where the schema hook expects ERC20 payment.
     */
    function revokeBatch(
        uint256[] calldata attestationIds,
        string[] calldata reasons,
        IERC20[] calldata resolverFeesERC20Tokens,
        uint256[] calldata resolverFeesERC20Amount,
        bytes calldata delegateSignature,
        bytes calldata extraData
    )
        external;

    /**
     * @notice Batch revokes off-chain attestations.
     */
    function revokeOffchainBatch(
        string[] calldata offchainAttestationIds,
        string[] calldata reasons,
        bytes calldata delegateSignature
    )
        external;

    /**
     * @notice Returns the specified `Schema`.
     */
    function getSchema(uint256 schemaId) external view returns (Schema calldata);

    /**
     * @notice Returns the specified `Attestation`.
     */
    function getAttestation(uint256 attestationId) external view returns (Attestation calldata);

    /**
     * @notice Returns the specified `OffchainAttestation`.
     */
    function getOffchainAttestation(string calldata offchainAttestationId)
        external
        view
        returns (OffchainAttestation calldata);

    /**
     * @notice Returns the hash that will be used to authorize a delegated attestation.
     */
    function getDelegatedAttestHash(Attestation calldata attestation) external pure returns (bytes32);

    /**
     * @notice Returns the hash that will be used to authorize a delegated batched attestation.
     */
    function getDelegatedAttestBatchHash(Attestation[] calldata attestations) external pure returns (bytes32);

    /**
     * @notice Returns the hash that will be used to authorize a delegated offchain attestation.
     */
    function getDelegatedOffchainAttestHash(string calldata offchainAttestationId) external pure returns (bytes32);

    /**
     * @notice Returns the hash that will be used to authorize a delegated batched offchain attestation.
     */
    function getDelegatedOffchainAttestBatchHash(string[] calldata offchainAttestationIds)
        external
        pure
        returns (bytes32);

    /**
     * @notice Returns the hash that will be used to authorize a delegated revocation.
     */
    function getDelegatedRevokeHash(uint256 attestationId) external pure returns (bytes32);

    /**
     * @notice Returns the hash that will be used to authorize a delegated batched revocation.
     */
    function getDelegatedRevokeBatchHash(uint256[] calldata attestationIds) external pure returns (bytes32);

    /**
     * @notice Returns the hash that will be used to authorize a delegated offchain revocation.
     */
    function getDelegatedOffchainRevokeHash(string calldata offchainAttestationId) external pure returns (bytes32);

    /**
     * @notice Returns the hash that will be used to authorize a delegated batched offchain revocation.
     */
    function getDelegatedOffchainRevokeBatchHash(string[] calldata offchainAttestationIds)
        external
        pure
        returns (bytes32);

    /**
     * @notice Returns the current schema counter. This is incremented for each `Schema` registered.
     */
    function schemaCounter() external view returns (uint256);

    /**
     * @notice Returns the current on-chain attestation counter. This is incremented for each `Attestation` made.
     */
    function attestationCounter() external view returns (uint256);
}