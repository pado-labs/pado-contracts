// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {EIP712Upgradeable} from "@openzeppelin/contracts-upgradeable/utils/cryptography/EIP712Upgradeable.sol";
import {ECDSAUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";

// prettier-ignore
import {
AccessDenied,
Signature,
InvalidEAS,
InvalidLength,
InvalidSignature,
NotFound,
NO_EXPIRATION_TIME,
uncheckedInc
} from "@ethereum-attestation-service/eas-contracts/contracts/Common.sol";

import {
AttestationRequest,
AttestationRequestData,
DelegatedAttestationRequest,
DelegatedRevocationRequest,
IEAS,
MultiAttestationRequest,
MultiDelegatedAttestationRequest,
MultiDelegatedRevocationRequest,
MultiRevocationRequest,
RevocationRequest,
RevocationRequestData
} from "@ethereum-attestation-service/eas-contracts/contracts/IEAS.sol";


import {ISP} from "./ethsign/interfaces/ISP.sol";
import {Attestation} from "./ethsign/models/Attestation.sol";
import {DataLocation} from "./ethsign/models/DataLocation.sol";

/**
 * @dev A struct representing the full arguments of the full delegated attestation request.
 */
    struct DelegatedProxyAttestationRequest {
        bytes32 schema; // The unique identifier of the schema.
        AttestationRequestData data; // The arguments of the attestation request.
        Signature signature; // The EIP712 signature data.
        address attester; // The attesting account.
        uint64 deadline; // The deadline of the signature/request.
    }

/**
 * @dev A struct representing the full arguments of the delegated multi attestation request.
 */
    struct MultiDelegatedProxyAttestationRequest {
        bytes32 schema; // The unique identifier of the schema.
        AttestationRequestData[] data; // The arguments of the attestation requests.
        Signature[] signatures; // The EIP712 signatures data. Please note that the signatures are assumed to be signed with increasing nonces.
        address attester; // The attesting account.
        uint64 deadline; // The deadline of the signature/request.
    }

/**
 * @dev A struct representing the arguments of the full delegated revocation request.
 */
    struct DelegatedProxyRevocationRequest {
        bytes32 schema; // The unique identifier of the schema.
        RevocationRequestData data; // The arguments of the revocation request.
        Signature signature; // The EIP712 signature data.
        address revoker; // The revoking account.
        uint64 deadline; // The deadline of the signature/request.
    }

/**
 * @dev A struct representing the full arguments of the delegated multi revocation request.
 */
    struct MultiDelegatedProxyRevocationRequest {
        bytes32 schema; // The unique identifier of the schema.
        RevocationRequestData[] data; // The arguments of the revocation requests.
        Signature[] signatures; // The EIP712 signatures data. Please note that the signatures are assumed to be signed with increasing nonces.
        address revoker; // The revoking account.
        uint64 deadline; // The deadline of the signature/request.
    }

    error InvalidISP();


/**
 * @title This utility contract an be used to aggregate delegated attestations without requiring a specific order via
 * nonces. The contract doesn't request nonces and implements replay protection by storing ***immalleable*** signatures.
 */
contract ETHSignProxyUpgradeable is EIP712Upgradeable {
    error DeadlineExpired();
    error UsedSignature();
    event SchemaInfo(uint64 schemaId);


    // The version of the contract.
    string public constant VERSION = "0.1";

    // The hash of the data type used to relay calls to the attest function. It's the value of
    // keccak256("Attest(bytes32 schema,address recipient,uint64 expirationTime,bool revocable,bytes32 refUID,bytes data,uint64 deadline)").
    bytes32 private constant ATTEST_PROXY_TYPEHASH = 0x4120d3b28306666b714826ad7cb70744d9658ad3e6cd873411bedadcf55afda7;

    // The hash of the data type used to relay calls to the revoke function. It's the value of
    // keccak256("Revoke(bytes32 schema,bytes32 uid,uint64 deadline)").
    bytes32 private constant REVOKE_PROXY_TYPEHASH = 0x96bdbea8fa280f8a0d0835587e1fbb1470e81d05c44514158443340cea40a05d;

    // The global EAS contract.
    ISP internal _isp;

    // The user readable name of the signing domain.
    string private _name;

    // The global mapping between proxy attestations and their attesters, so that we can verify that only the original
    // attester is able to revert attestations by proxy.
    mapping(bytes32 uid => address attester) private _attesters;

    // Replay protection signatures.
    mapping(bytes signature => bool used) private _signatures;

    mapping(address => mapping(bytes32 schemaid => uint256[])) internal _padoAttestations;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(ISP isp, string memory name) internal onlyInitializing {
        __EIP712_init(name, VERSION);
        if (address(isp) == address(0)) {
            revert InvalidISP();
        }
        _isp = isp;
        _name = name;
    }

    /**
     * @dev Returns the EAS.
     */
    function getEAS() external view returns (ISP) {
        return _isp;
    }

    /**
     * @dev Returns the domain separator used in the encoding of the signatures for attest, and revoke.
     */
    function getDomainSeparator() external view returns (bytes32) {
        return _domainSeparatorV4();
    }

    /**
     * Returns the EIP712 type hash for the attest function.
     */
    function getAttestTypeHash() external pure returns (bytes32) {
        return ATTEST_PROXY_TYPEHASH;
    }

    /**
     * Returns the EIP712 type hash for the revoke function.
     */
    function getRevokeTypeHash() external pure returns (bytes32) {
        return REVOKE_PROXY_TYPEHASH;
    }

    /**
     * Returns the EIP712 name.
     */
    function getName() external view returns (string memory) {
        return _name;
    }

    /**
     * Returns the attester for a given uid.
     */
    function getAttester(bytes32 uid) external view returns (address) {
        return _attesters[uid];
    }

    /**
     * @dev Attests to a specific schema via the provided EIP712 signature.
     *
     * @param delegatedRequest The arguments of the delegated attestation request.
     *
     * Example:
     *
     * attestByDelegation({
     *     schema: '0x8e72f5bc0a8d4be6aa98360baa889040c50a0e51f32dbf0baa5199bd93472ebc',
     *     data: {
     *         recipient: '0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266',
     *         expirationTime: 1673891048,
     *         revocable: true,
     *         refUID: '0x0000000000000000000000000000000000000000000000000000000000000000',
     *         data: '0x1234',
     *         value: 0
     *     },
     *     signature: {
     *         v: 28,
     *         r: '0x148c...b25b',
     *         s: '0x5a72...be22'
     *     },
     *     attester: '0xc5E8740aD971409492b1A63Db8d83025e0Fc427e'
     * })
     *
     * @return The UID of the new attestation.
     */
    function attestByDelegation(
        DelegatedProxyAttestationRequest calldata delegatedRequest
    ) public payable virtual returns (bytes32) {
        _verifyAttest(delegatedRequest);
        bytes[] memory arrayBytes = new bytes[](1);

        arrayBytes[0] = abi.encodePacked(delegatedRequest.data.recipient);
        uint64 schemaId = getUint64ValueFromBytes32(delegatedRequest.schema);
        emit SchemaInfo(schemaId);

        Attestation memory attestation = Attestation({
            schemaId: schemaId,
            linkedAttestationId: 0,
            attestTimestamp: 0,
            revokeTimestamp: 0,
            attester: address(this),
            validUntil: delegatedRequest.data.expirationTime,
            dataLocation: DataLocation.ONCHAIN,
            revoked: true,
            recipients: arrayBytes,
            data: delegatedRequest.data.data
        });
        uint256 uid = _isp.attest(
            attestation,
            "",
            new bytes(0),
            new bytes(0)
        );


        _attesters[bytes32(uid)] = delegatedRequest.attester;

        return bytes32(uid);
    }

/**
 * @dev Revokes an existing attestation to a specific schema via the provided EIP712 signature.
     *
     * Example:
     *
     * revokeByDelegation({
     *     schema: '0x8e72f5bc0a8d4be6aa98360baa889040c50a0e51f32dbf0baa5199bd93472ebc',
     *     data: {
     *         uid: '0xcbbc12102578c642a0f7b34fe7111e41afa25683b6cd7b5a14caf90fa14d24ba',
     *         value: 0
     *     },
     *     signature: {
     *         v: 27,
     *         r: '0xb593...7142',
     *         s: '0x0f5b...2cce'
     *     },
     *     revoker: '0x244934dd3e31bE2c81f84ECf0b3E6329F5381992'
     * })
     *
     * @param delegatedRequest The arguments of the delegated revocation request.
     */
/*function revokeByDelegation(DelegatedProxyRevocationRequest calldata delegatedRequest) public payable virtual {
    _verifyRevoke(delegatedRequest);

    return
        _isp.revoke(
            RevocationRequest({ schema: delegatedRequest.schema, data: delegatedRequest.data })
        );
}*/

/**
 * @dev Revokes existing attestations to multiple schemas via provided EIP712 signatures.
     *
     * @param multiDelegatedRequests The arguments of the delegated multi revocation attestation requests. The requests should be
     * grouped by distinct schema ids to benefit from the best batching optimization.
     *
     * Example:
     *
     * multiRevokeByDelegation([{
     *     schema: '0x8e72f5bc0a8d4be6aa98360baa889040c50a0e51f32dbf0baa5199bd93472ebc',
     *     data: [{
     *         uid: '0x211296a1ca0d7f9f2cfebf0daaa575bea9b20e968d81aef4e743d699c6ac4b25',
     *         value: 1000
     *     },
     *     {
     *         uid: '0xe160ac1bd3606a287b4d53d5d1d6da5895f65b4b4bab6d93aaf5046e48167ade',
     *         value: 0
     *     }],
     *     signatures: [{
     *         v: 28,
     *         r: '0x148c...b25b',
     *         s: '0x5a72...be22'
     *     },
     *     {
     *         v: 28,
     *         r: '0x487s...67bb',
     *         s: '0x12ad...2366'
     *     }],
     *     revoker: '0x244934dd3e31bE2c81f84ECf0b3E6329F5381992'
     * }])
     *
     */
/*function multiRevokeByDelegation(
    MultiDelegatedProxyRevocationRequest[] calldata multiDelegatedRequests
) public payable virtual {
    MultiRevocationRequest[] memory multiRequests = new MultiRevocationRequest[](multiDelegatedRequests.length);

    for (uint256 i = 0; i < multiDelegatedRequests.length; i = uncheckedInc(i)) {
        MultiDelegatedProxyRevocationRequest memory multiDelegatedRequest = multiDelegatedRequests[i];
        RevocationRequestData[] memory data = multiDelegatedRequest.data;

        // Ensure that no inputs are missing.
        if (data.length == 0 || data.length != multiDelegatedRequest.signatures.length) {
            revert InvalidLength();
        }

        // Verify EIP712 signatures. Please note that the signatures are assumed to be signed with increasing nonces.
        for (uint256 j = 0; j < data.length; j = uncheckedInc(j)) {
            RevocationRequestData memory requestData = data[j];

            _verifyRevoke(
                DelegatedProxyRevocationRequest({
                    schema: multiDelegatedRequest.schema,
                    data: requestData,
                    signature: multiDelegatedRequest.signatures[j],
                    revoker: multiDelegatedRequest.revoker,
                    deadline: multiDelegatedRequest.deadline
                })
            );
        }

        multiRequests[i] = MultiRevocationRequest({ schema: multiDelegatedRequest.schema, data: data });
    }

    _isp.multiRevoke{ value: msg.value }(multiRequests);
}*/

/**
 * @dev Verifies delegated attestation request.
     *
     * @param request The arguments of the delegated attestation request.
     */
    function _verifyAttest(DelegatedProxyAttestationRequest memory request) internal view {
        if (request.deadline != NO_EXPIRATION_TIME && request.deadline <= _time()) {
            revert DeadlineExpired();
        }

        AttestationRequestData memory data = request.data;
        Signature memory signature = request.signature;

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

        address recoverFromSigAddress = ECDSAUpgradeable.recover(digest, signature.v, signature.r, signature.s);
        if (recoverFromSigAddress != request.attester) {
            revert InvalidSignature();
        }
    }

/**
 * @dev Verifies delegated revocation request.
     *
     * @param request The arguments of the delegated revocation request.
     */
    function _verifyRevoke(DelegatedProxyRevocationRequest memory request) internal {
        if (request.deadline != NO_EXPIRATION_TIME && request.deadline <= _time()) {
            revert DeadlineExpired();
        }

        RevocationRequestData memory data = request.data;

        // Allow only original attesters to revoke their attestations.
        address attester = _attesters[data.uid];
        if (attester == address(0)) {
            revert NotFound();
        }

        if (attester != msg.sender) {
            revert AccessDenied();
        }

        Signature memory signature = request.signature;

        _verifyUnusedSignature(signature);

        bytes32 digest = _hashTypedDataV4(
            keccak256(abi.encode(REVOKE_PROXY_TYPEHASH, request.schema, data.uid, request.deadline))
        );

        if (ECDSAUpgradeable.recover(digest, signature.v, signature.r, signature.s) != request.revoker) {
            revert InvalidSignature();
        }
    }

/**
 * @dev Ensures that the provided EIP712 signature wasn't already used.
     *
     * @param signature The EIP712 signature data.
     */
    function _verifyUnusedSignature(Signature memory signature) internal {
        bytes memory packedSignature = abi.encodePacked(signature.v, signature.r, signature.s);

        if (_signatures[packedSignature]) {
            revert UsedSignature();
        }

        _signatures[packedSignature] = true;
    }

/**
 * @dev Returns the current's block timestamp. This method is overridden during tests and used to simulate the
     * current block time.
     */
    function _time() internal view virtual returns (uint64) {
        return uint64(block.timestamp);
    }


    function uint64ToBytes32(uint64 number) public pure returns (bytes32) {
        uint256 result = number;
        return bytes32(result);
    }

    function getUint64ValueFromBytes32(bytes32 value) public pure returns (uint64)  {
        uint64 result;
        assembly {
            let tempBytes := mload(0x40)
            mstore(tempBytes, value)
            result := mload(tempBytes)
        }
        return result;
    }

}
