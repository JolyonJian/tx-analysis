// /contracts/MerkleDistributor.sol

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./interfaces/IMerkleDistributor.sol";


contract MerkleDistributor is IMerkleDistributor, Ownable {
    address public immutable override token;
    bytes32 public immutable override merkleRoot;
    uint256 public immutable override expireTimestamp;

    // This is a packed array of booleans.
    mapping(uint256 => uint256) private claimedBitMap;

    constructor(address token_, bytes32 merkleRoot_, uint256 expireTimestamp_) {
        token = token_;
        merkleRoot = merkleRoot_;
        expireTimestamp = expireTimestamp_;
    }

    function isClaimed(uint256 index) public view override returns (bool) {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        uint256 claimedWord = claimedBitMap[claimedWordIndex];
        uint256 mask = (1 << claimedBitIndex);
        return claimedWord & mask == mask;
    }

    function _setClaimed(uint256 index) private {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        claimedBitMap[claimedWordIndex] = claimedBitMap[claimedWordIndex] | (1 << claimedBitIndex);
    }

    function claim(uint256 index, uint256 amount, bytes32[] calldata merkleProof) external override {
        address account = msg.sender;
        require(!isClaimed(index), 'MerkleDistributor: Drop already claimed.');

        // Verify the merkle proof.
        bytes32 node = keccak256(abi.encodePacked(index, account, amount));
        require(MerkleProof.verify(merkleProof, merkleRoot, node), 'MerkleDistributor: Invalid proof.');

        // Mark it claimed and send the token.
        _setClaimed(index);
        require(IERC20(token).transfer(account, amount), 'MerkleDistributor: Transfer failed.');

        emit Claimed(index, account, amount);
    }

    /**
     * @dev Sweep any unclaimed funds to arbitrary destination. Can only be called by owner.
     */
    function sweep(address target) external override onlyOwner {
        require(block.timestamp >= expireTimestamp, "MerkleDistributor: Drop not expired");
        IERC20 tokenContract = IERC20(token);
        uint256 balance = tokenContract.balanceOf(address(this));
        tokenContract.transfer(target, balance);
    }

    /**
     * @dev Sweep any unclaimed funds to contract owner. Can be called by anyone.
     */
    function sweepToOwner() external override {
        require(block.timestamp >= expireTimestamp, "MerkleDistributor: Drop not expired");
        IERC20 tokenContract = IERC20(token);
        uint256 balance = tokenContract.balanceOf(address(this));
        tokenContract.transfer(owner(), balance);
    }
}


