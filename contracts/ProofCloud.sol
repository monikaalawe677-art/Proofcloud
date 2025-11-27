// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract ProofCloud {
    struct Proof {
        address submitter;
        uint256 timestamp;
        string metadata;  // e.g. IPFS hash / link / description
    }

    // Map proof ID to Proof
    mapping(uint256 => Proof) private proofs;
    uint256 private nextProofId = 1;

    // Map documentHash => proof ID for quick lookup (optional, if you store hash)
    mapping(bytes32 => uint256) private hashToProofId;

    // Events
    event ProofSubmitted(uint256 indexed proofId, address indexed submitter, uint256 timestamp, string metadata);
    event ProofMetadataUpdated(uint256 indexed proofId, string newMetadata);

    /// @notice Submit a new proof (with metadata, e.g. IPFS link or description)
    function submitProof(string memory metadata) external returns (uint256) {
        require(bytes(metadata).length > 0, "Metadata cannot be empty");

        uint256 proofId = nextProofId++;
        proofs[proofId] = Proof({
            submitter: msg.sender,
            timestamp: block.timestamp,
            metadata: metadata
        });

        emit ProofSubmitted(proofId, msg.sender, block.timestamp, metadata);
        return proofId;
    }

    /// @notice Optionally associate a hash as key (if you want to store doc hash rather than arbitrary metadata)
    function submitProofWithHash(bytes32 docHash, string memory metadata) external returns (uint256) {
        require(docHash != bytes32(0), "Invalid hash");
        require(hashToProofId[docHash] == 0, "Proof for this hash already exists");

        uint256 proofId = nextProofId++;
        proofs[proofId] = Proof({
            submitter: msg.sender,
            timestamp: block.timestamp,
            metadata: metadata
        });
        hashToProofId[docHash] = proofId;

        emit ProofSubmitted(proofId, msg.sender, block.timestamp, metadata);
        return proofId;
    }

    /// @notice View proof details by proof ID
    function getProof(uint256 proofId) external view returns (address submitter, uint256 timestamp, string memory metadata) {
        Proof memory p = proofs[proofId];
        require(p.timestamp != 0, "Proof not found");
        return (p.submitter, p.timestamp, p.metadata);
    }

    /// @notice Find proof ID by document hash (if used)
    function findProofByHash(bytes32 docHash) external view returns (uint256) {
        return hashToProofId[docHash];
    }

    /// @notice If you want to let submitter update metadata (e.g. add IPFS link or update description)
    function updateMetadata(uint256 proofId, string memory newMetadata) external {
        Proof storage p = proofs[proofId];
        require(p.submitter == msg.sender, "Not submitter");
        require(bytes(newMetadata).length > 0, "Metadata cannot be empty");
        p.metadata = newMetadata;
        emit ProofMetadataUpdated(proofId, newMetadata);
    }

    /// @notice Get total proofs submitted
    function totalProofs() external view returns (uint256) {
        return nextProofId - 1;
    }
}
