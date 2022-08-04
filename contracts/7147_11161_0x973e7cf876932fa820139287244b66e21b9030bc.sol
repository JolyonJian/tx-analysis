// contracts/SPOODEEMOONWTF.sol

//SPDX-License-Identifier: UNLICENSED

// File: @openzeppelin/contracts/utils/cryptography/ECDSA.sol

// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature)
        internal
        pure
        returns (address, RecoverError)
    {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature)
        internal
        pure
        returns (address)
    {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs &
            bytes32(
                0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
            );
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (
            uint256(s) >
            0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0
        ) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash)
        internal
        pure
        returns (bytes32)
    {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return
            keccak256(
                abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
            );
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n",
                    Strings.toString(s.length),
                    s
                )
            );
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked("\x19\x01", domainSeparator, structHash)
            );
    }
}

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Trees proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
 *
 * WARNING: You should avoid using leaf values that are 64 bytes long prior to
 * hashing, or use a hash function other than keccak256 for hashing leaves.
 * This is because the concatenation of a sorted pair of internal nodes in
 * the merkle tree could be reinterpreted as a leaf value.
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merkle tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf)
        internal
        pure
        returns (bytes32)
    {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];
            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = _efficientHash(computedHash, proofElement);
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = _efficientHash(proofElement, computedHash);
            }
        }
        return computedHash;
    }

    function _efficientHash(bytes32 a, bytes32 b)
        private
        pure
        returns (bytes32 value)
    {
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }
}

pragma solidity ^0.8.4;

pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./ERC721A.sol";

contract SPOODEEMOON is ERC721A, Ownable {
    using ECDSA for bytes32;

    using SafeMath for uint256;

    string private baseTokenURI;

    bytes32 private merkleRoot;

    bool public publicSaleStarted;

    bool public presaleStarted;

    uint256 public publicSalePrice;

    uint256 public presalePrice;

    uint256 private totalNFTs;

    mapping(address => uint256) public NFTtracker;
    mapping(address => uint256) public NFTtrackerPresale;

    mapping(address => bool) freeMinted;
    mapping(address => bool) freeMintedPresale;

    uint256 public NFTLimitPublic;

    uint256 public NFTLimitPresale;

    uint256 public maxNFTs;

    event BaseURIChanged(string baseURI);

    event PublicSaleMint(address mintTo, uint256 tokensCount);

    event Received();

    address founderAddress;

    mapping(uint256 => bool) sellTokens;
    mapping(uint256 => uint256) tokenPrice;
    mapping(uint256 => address) trueOwner;

    uint256 royaltyFee;

    constructor(
        string memory baseURI,
        address _founderAddress,
        bytes32 root
    ) ERC721A("SPOODEEMOON", "SPDM", 10, 5775) {
        baseTokenURI = baseURI;

        founderAddress = _founderAddress;

        totalNFTs = 0;

        merkleRoot = root;

        NFTLimitPublic = 3;
        NFTLimitPresale = 3;

        maxNFTs = 5775;
        publicSalePrice = 150000000000000000;
        presalePrice = 150000000000000000;
        //
    }

    //Settings

    function setPrices(uint256 _newPublicSalePrice, uint256 _newPresalePrice)
        public
        onlyOwner
    {
        publicSalePrice = _newPublicSalePrice;

        presalePrice = _newPresalePrice;
    }

    function setNFTLimits(uint256 _newLimitPublic, uint256 _newLimitPresale)
        public
        onlyOwner
    {
        NFTLimitPublic = _newLimitPublic;

        NFTLimitPresale = _newLimitPresale;
    }

    function setNFTHardcap(uint256 _newMax) public onlyOwner {
        maxNFTs = _newMax;
    }

    function setNewRoot(bytes32 _newRoot) public onlyOwner {
        merkleRoot = _newRoot;
    }

    function PublicMint(uint256 quantity)
        external
        payable
        whenPublicSaleStarted
    {
        require(totalNFTs + quantity <= maxNFTs, "Exceeded max NFTs amount");

        require(
            NFTtracker[msg.sender] + quantity <= NFTLimitPublic,
            "Minting would exceed wallet limit"
        );

        require(quantity <= 10, "Exceeded max transaction amount");

        if (freeMinted[msg.sender]) {
            require(
                msg.value >= publicSalePrice * quantity,
                "Fund amount is incorrect"
            );
        } else {
            require(
                msg.value >= (publicSalePrice * quantity) - publicSalePrice,
                "Fund amount is incorrect"
            );
            freeMinted[msg.sender] = true;
        }

        _safeMint(msg.sender, quantity, true, "");

        totalNFTs += quantity;

        NFTtracker[msg.sender] += quantity;

        _widthdraw(founderAddress, msg.value);
    }

    function Airdrop(uint256 quantity, address wallet)
        external
        payable
        onlyOwner
    {
        require(totalNFTs + quantity <= maxNFTs, "Exceeded max NFTs amount");

        require(quantity <= 150, "Exceeded max transaction amount");

        _safeMint(wallet, quantity, true, "");

        totalNFTs += quantity;

        NFTtracker[wallet] += quantity;
    }

    function PresaleMint(uint256 quantity, bytes32[] calldata _merkleProof)
        external
        payable
        whenPresaleStarted
    {
        require(
            NFTtrackerPresale[msg.sender] + quantity <= NFTLimitPresale,
            "Minting would exceed wallet limit"
        );

        require(totalNFTs + quantity <= maxNFTs, "Exceeded max NFTs amount");

        if (freeMintedPresale[msg.sender]) {
            require(
                msg.value >= presalePrice * quantity,
                "Fund amount is incorrect"
            );
        } else {
            require(
                msg.value >= (presalePrice * quantity) - presalePrice,
                "Fund amount is incorrect"
            );
            freeMintedPresale[msg.sender] = true;
        }

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));

        require(
            MerkleProof.verify(_merkleProof, merkleRoot, leaf),
            "Presale must be minted from our website"
        );

        _safeMint(msg.sender, quantity, true, "");

        totalNFTs += quantity;

        NFTtrackerPresale[msg.sender] += quantity;

        _widthdraw(founderAddress, msg.value);
    }

    //Sales

    modifier whenPublicSaleStarted() {
        require(publicSaleStarted, "Public sale has not started yet");

        _;
    }

    modifier whenPresaleStarted() {
        require(presaleStarted, "Presale has not started yet");

        _;
    }

    function togglePublicSaleStarted() external onlyOwner {
        publicSaleStarted = !publicSaleStarted;
    }

    function togglePresaleStarted() external onlyOwner {
        presaleStarted = !presaleStarted;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 0;
    }

    //NFT Metadata Methods

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721A)
        returns (string memory)
    {
        string memory _tokenURI = super.tokenURI(tokenId);

        return string(abi.encodePacked(_tokenURI, ".json"));
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        baseTokenURI = baseURI;

        emit BaseURIChanged(baseURI);
    }

    // Withdraw

    function withdrawAll() public onlyOwner {
        uint256 balance = address(this).balance;

        require(balance > 0, "Insufficent balance");

        _widthdraw(founderAddress, balance);
    }

    function _widthdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");

        require(success, "Failed to widthdraw Ether");
    }

    function changeFounderAddress(address adr) external onlyOwner {
        founderAddress = adr;
    }

    function onERC721Received(
        address _operator,
        address _from,
        uint256 _tokenId,
        bytes calldata _data
    ) external returns (bytes4) {
        _operator;
        _from;
        _tokenId;
        _data;
        emit Received();
        return 0x150b7a02;
    }
}


