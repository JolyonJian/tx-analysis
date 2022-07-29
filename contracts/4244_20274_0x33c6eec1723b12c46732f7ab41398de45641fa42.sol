{{
  "language": "Solidity",
  "sources": {
    "contracts/LedgerNFT.sol": {
      "content": "// SPDX-License-Identifier: MIT\n\npragma solidity >=0.8.4;\n\nimport {ERC721} from \"@rari-capital/solmate/src/tokens/ERC721.sol\";\nimport \"@openzeppelin/contracts/utils/cryptography/ECDSA.sol\";\nimport \"./ReentrancyGuard.sol\";\nimport \"./Signable.sol\";\nimport \"./IProxyTracking.sol\";\nimport \"./Helpers.sol\";\nimport \"./Errors.sol\";\n\ncontract LedgerMarketPass is ERC721, ReentrancyGuard, Signable {\n    // Phase States: None - can't mint, Pre Sale - only mint with sign, Main Sale - only regular mint\n    enum Phase {\n        NONE,\n        PRE_SALE,\n        MAIN_SALE\n    }\n\n    // Current phase of the contract\n    Phase private _phase;\n\n    // Constants\n    // Maximum number of NFTs can be allocated\n    uint256 public immutable maxSupply;\n\n    // ETH value should be sent with mint (owner mint is free)\n    uint256 public mintPrice = 0.3 ether;\n\n    // Address where all money from the contract will go if the owner of the contract will call withdraw function\n    address private constant _withdrawalAddress =\n        0xC55dA65c626Bad25532bE0d4f6B44aBFD733A152;\n\n    // Counter used for token number in minting\n    uint256 private _nextTokenCount = 1;\n\n    // Base token and contract URI\n    string private baseTokenURI;\n    string private baseContractURI;\n\n    // Proxy contract for tracking afterTokenTransfer call\n    IProxyTracking public proxyTrackingContract;\n\n    // Has the account used minting already\n    mapping(address => bool) public minted;\n\n    // Modifier is used to check if the phase rule is met\n    modifier phaseRequired(Phase phase_) {\n        if (phase_ != _phase) revert Errors.MintNotAvailable();\n        _;\n    }\n\n    // Modifier is used to check if at least a minimal amount of money was sent\n    modifier costs() {\n        if (msg.value < mintPrice) revert Errors.InsufficientFunds();\n        _;\n    }\n\n    constructor(\n        uint256 _maxSupply,\n        string memory _baseTokenURI,\n        string memory _baseContractURI,\n        string memory _name,\n        string memory _symbol\n    ) ERC721(_name, _symbol) {\n        maxSupply = _maxSupply;\n        baseTokenURI = _baseTokenURI;\n        baseContractURI = _baseContractURI;\n    }\n\n    // Contract owner can call this function to mint `amount` of tokens into account with the address `to`\n    function ownerMint(address to, uint256 amount) external onlyOwner lock {\n        if (_nextTokenCount + amount - 1 > maxSupply)\n            revert Errors.SupplyLimitReached();\n\n        for (uint256 i; i < amount; ) {\n            _safeMint(to, _nextTokenCount);\n\n            unchecked {\n                ++_nextTokenCount;\n                ++i;\n            }\n        }\n    }\n\n    // Function used to do minting on pre-sale phase (with signature)\n    function preSaleMint(bytes calldata signature)\n        external\n        payable\n        costs\n        phaseRequired(Phase.PRE_SALE)\n    {\n        if (!_verify(signer(), _hash(msg.sender), signature))\n            revert Errors.InvalidSignature();\n\n        _mintLogic();\n    }\n\n    // Function used to do minting on main-sale phase\n    function mint() external payable costs phaseRequired(Phase.MAIN_SALE) {\n        _mintLogic();\n    }\n\n    // Contract owner can call this function to withdraw all money from the contract into a defined wallet\n    function withdrawAll() external onlyOwner {\n        uint256 balance = address(this).balance;\n        if (balance == 0) revert Errors.NothingToWithdraw();\n\n        (bool success, ) = _withdrawalAddress.call{value: balance}(\"\");\n        if (!success) revert Errors.WithdrawFailed();\n    }\n\n    // Contract owner can call this function to set minting price on pre-sale and main-sale\n    function setMintPrice(uint256 mintPrice_) external onlyOwner {\n        if (mintPrice_ == 0) revert Errors.InvalidMintPrice();\n        // only allow to change price once\n        if (mintPrice != 0.3 ether) revert Errors.MintPriceAlreadyUpdated();\n\n        mintPrice = mintPrice_;\n    }\n\n    // Contract owner can call this function to set the proxy tracking contract address (which gets a call of afterTokenTransfer function of the original contract)\n    function setProxyTrackingContract(IProxyTracking proxyTrackingContract_)\n        external\n        onlyOwner\n    {\n        proxyTrackingContract = proxyTrackingContract_;\n    }\n\n    function setContractURI(string calldata baseContractURI_)\n        external\n        onlyOwner\n    {\n        if (bytes(baseContractURI_).length == 0)\n            revert Errors.InvalidBaseContractURL();\n\n        baseContractURI = baseContractURI_;\n    }\n\n    function setBaseURI(string calldata baseURI_) external onlyOwner {\n        if (bytes(baseURI_).length == 0) revert Errors.InvalidBaseURI();\n\n        baseTokenURI = baseURI_;\n    }\n\n    function setPhase(Phase phase_) external onlyOwner {\n        _phase = phase_;\n    }\n\n    function totalSupply() external view returns (uint256) {\n        return _nextTokenCount - 1;\n    }\n\n    function contractURI() external view returns (string memory) {\n        return baseContractURI;\n    }\n\n    function phase() external view returns (Phase) {\n        return _phase;\n    }\n\n    function _baseURI() internal view virtual returns (string memory) {\n        return baseTokenURI;\n    }\n\n    function _mint(address to, uint256 id) internal virtual override {\n        super._mint(to, id);\n        _afterTokenTransfer(address(0), to, id);\n    }\n\n    function _burn(uint256 id) internal virtual override {\n        address owner = _ownerOf[id];\n        super._burn(id);\n        _afterTokenTransfer(owner, address(0), id);\n    }\n\n    function transferFrom(\n        address from,\n        address to,\n        uint256 id\n    ) public virtual override {\n        super.transferFrom(from, to, id);\n        _afterTokenTransfer(from, to, id);\n    }\n\n    // Function is overridden to do a proxy call into the proxy tracking contract if it is not zero\n    function _afterTokenTransfer(\n        address from,\n        address to,\n        uint256 tokenId\n    ) internal virtual {\n        if (address(proxyTrackingContract) != address(0)) {\n            proxyTrackingContract.afterTokenTransfer(from, to, tokenId);\n        }\n    }\n\n    function _mintLogic() private {\n        if (msg.sender.code.length > 0) revert Errors.ContractCantMint();\n        if (_nextTokenCount > maxSupply) revert Errors.SupplyLimitReached();\n        if (minted[msg.sender]) revert Errors.AccountAlreadyMintedMax();\n\n        minted[msg.sender] = true;\n\n        // smart-contracts are not allowed to call the method -- that means safeMint is useless\n        _mint(msg.sender, _nextTokenCount);\n\n        unchecked {\n            ++_nextTokenCount;\n        }\n    }\n\n    function _verify(\n        address signer,\n        bytes32 hash,\n        bytes calldata signature\n    ) private pure returns (bool) {\n        return signer == ECDSA.recover(hash, signature);\n    }\n\n    function _hash(address account) private pure returns (bytes32) {\n        return\n            ECDSA.toEthSignedMessageHash(keccak256(abi.encodePacked(account)));\n    }\n\n    function tokenURI(uint256 tokenId)\n        public\n        view\n        override\n        returns (string memory)\n    {\n        if (ownerOf(tokenId) == address(0)) revert Errors.TokenDoesNotExist();\n\n        string memory baseURI = _baseURI();\n        return\n            bytes(baseURI).length > 0\n                ? string(\n                    abi.encodePacked(baseURI, Helpers.uint2string(tokenId))\n                )\n                : \"\";\n    }\n\n    function burn(uint256 id) external {\n        if (msg.sender != ownerOf(id)) revert Errors.NotOwner();\n        _burn(id);\n    }\n}\n"
    },
    "@rari-capital/solmate/src/tokens/ERC721.sol": {
      "content": "// SPDX-License-Identifier: AGPL-3.0-only\npragma solidity >=0.8.0;\n\n/// @notice Modern, minimalist, and gas efficient ERC-721 implementation.\n/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC721.sol)\nabstract contract ERC721 {\n    /*//////////////////////////////////////////////////////////////\n                                 EVENTS\n    //////////////////////////////////////////////////////////////*/\n\n    event Transfer(address indexed from, address indexed to, uint256 indexed id);\n\n    event Approval(address indexed owner, address indexed spender, uint256 indexed id);\n\n    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);\n\n    /*//////////////////////////////////////////////////////////////\n                         METADATA STORAGE/LOGIC\n    //////////////////////////////////////////////////////////////*/\n\n    string public name;\n\n    string public symbol;\n\n    function tokenURI(uint256 id) public view virtual returns (string memory);\n\n    /*//////////////////////////////////////////////////////////////\n                      ERC721 BALANCE/OWNER STORAGE\n    //////////////////////////////////////////////////////////////*/\n\n    mapping(uint256 => address) internal _ownerOf;\n\n    mapping(address => uint256) internal _balanceOf;\n\n    function ownerOf(uint256 id) public view virtual returns (address owner) {\n        require((owner = _ownerOf[id]) != address(0), \"NOT_MINTED\");\n    }\n\n    function balanceOf(address owner) public view virtual returns (uint256) {\n        require(owner != address(0), \"ZERO_ADDRESS\");\n\n        return _balanceOf[owner];\n    }\n\n    /*//////////////////////////////////////////////////////////////\n                         ERC721 APPROVAL STORAGE\n    //////////////////////////////////////////////////////////////*/\n\n    mapping(uint256 => address) public getApproved;\n\n    mapping(address => mapping(address => bool)) public isApprovedForAll;\n\n    /*//////////////////////////////////////////////////////////////\n                               CONSTRUCTOR\n    //////////////////////////////////////////////////////////////*/\n\n    constructor(string memory _name, string memory _symbol) {\n        name = _name;\n        symbol = _symbol;\n    }\n\n    /*//////////////////////////////////////////////////////////////\n                              ERC721 LOGIC\n    //////////////////////////////////////////////////////////////*/\n\n    function approve(address spender, uint256 id) public virtual {\n        address owner = _ownerOf[id];\n\n        require(msg.sender == owner || isApprovedForAll[owner][msg.sender], \"NOT_AUTHORIZED\");\n\n        getApproved[id] = spender;\n\n        emit Approval(owner, spender, id);\n    }\n\n    function setApprovalForAll(address operator, bool approved) public virtual {\n        isApprovedForAll[msg.sender][operator] = approved;\n\n        emit ApprovalForAll(msg.sender, operator, approved);\n    }\n\n    function transferFrom(\n        address from,\n        address to,\n        uint256 id\n    ) public virtual {\n        require(from == _ownerOf[id], \"WRONG_FROM\");\n\n        require(to != address(0), \"INVALID_RECIPIENT\");\n\n        require(\n            msg.sender == from || isApprovedForAll[from][msg.sender] || msg.sender == getApproved[id],\n            \"NOT_AUTHORIZED\"\n        );\n\n        // Underflow of the sender's balance is impossible because we check for\n        // ownership above and the recipient's balance can't realistically overflow.\n        unchecked {\n            _balanceOf[from]--;\n\n            _balanceOf[to]++;\n        }\n\n        _ownerOf[id] = to;\n\n        delete getApproved[id];\n\n        emit Transfer(from, to, id);\n    }\n\n    function safeTransferFrom(\n        address from,\n        address to,\n        uint256 id\n    ) public virtual {\n        transferFrom(from, to, id);\n\n        require(\n            to.code.length == 0 ||\n                ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, \"\") ==\n                ERC721TokenReceiver.onERC721Received.selector,\n            \"UNSAFE_RECIPIENT\"\n        );\n    }\n\n    function safeTransferFrom(\n        address from,\n        address to,\n        uint256 id,\n        bytes calldata data\n    ) public virtual {\n        transferFrom(from, to, id);\n\n        require(\n            to.code.length == 0 ||\n                ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, data) ==\n                ERC721TokenReceiver.onERC721Received.selector,\n            \"UNSAFE_RECIPIENT\"\n        );\n    }\n\n    /*//////////////////////////////////////////////////////////////\n                              ERC165 LOGIC\n    //////////////////////////////////////////////////////////////*/\n\n    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {\n        return\n            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165\n            interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721\n            interfaceId == 0x5b5e139f; // ERC165 Interface ID for ERC721Metadata\n    }\n\n    /*//////////////////////////////////////////////////////////////\n                        INTERNAL MINT/BURN LOGIC\n    //////////////////////////////////////////////////////////////*/\n\n    function _mint(address to, uint256 id) internal virtual {\n        require(to != address(0), \"INVALID_RECIPIENT\");\n\n        require(_ownerOf[id] == address(0), \"ALREADY_MINTED\");\n\n        // Counter overflow is incredibly unrealistic.\n        unchecked {\n            _balanceOf[to]++;\n        }\n\n        _ownerOf[id] = to;\n\n        emit Transfer(address(0), to, id);\n    }\n\n    function _burn(uint256 id) internal virtual {\n        address owner = _ownerOf[id];\n\n        require(owner != address(0), \"NOT_MINTED\");\n\n        // Ownership check above ensures no underflow.\n        unchecked {\n            _balanceOf[owner]--;\n        }\n\n        delete _ownerOf[id];\n\n        delete getApproved[id];\n\n        emit Transfer(owner, address(0), id);\n    }\n\n    /*//////////////////////////////////////////////////////////////\n                        INTERNAL SAFE MINT LOGIC\n    //////////////////////////////////////////////////////////////*/\n\n    function _safeMint(address to, uint256 id) internal virtual {\n        _mint(to, id);\n\n        require(\n            to.code.length == 0 ||\n                ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), id, \"\") ==\n                ERC721TokenReceiver.onERC721Received.selector,\n            \"UNSAFE_RECIPIENT\"\n        );\n    }\n\n    function _safeMint(\n        address to,\n        uint256 id,\n        bytes memory data\n    ) internal virtual {\n        _mint(to, id);\n\n        require(\n            to.code.length == 0 ||\n                ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), id, data) ==\n                ERC721TokenReceiver.onERC721Received.selector,\n            \"UNSAFE_RECIPIENT\"\n        );\n    }\n}\n\n/// @notice A generic interface for a contract which properly accepts ERC721 tokens.\n/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC721.sol)\nabstract contract ERC721TokenReceiver {\n    function onERC721Received(\n        address,\n        address,\n        uint256,\n        bytes calldata\n    ) external virtual returns (bytes4) {\n        return ERC721TokenReceiver.onERC721Received.selector;\n    }\n}\n"
    },
    "@openzeppelin/contracts/utils/cryptography/ECDSA.sol": {
      "content": "// SPDX-License-Identifier: MIT\n// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/ECDSA.sol)\n\npragma solidity ^0.8.0;\n\nimport \"../Strings.sol\";\n\n/**\n * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.\n *\n * These functions can be used to verify that a message was signed by the holder\n * of the private keys of a given address.\n */\nlibrary ECDSA {\n    enum RecoverError {\n        NoError,\n        InvalidSignature,\n        InvalidSignatureLength,\n        InvalidSignatureS,\n        InvalidSignatureV\n    }\n\n    function _throwError(RecoverError error) private pure {\n        if (error == RecoverError.NoError) {\n            return; // no error: do nothing\n        } else if (error == RecoverError.InvalidSignature) {\n            revert(\"ECDSA: invalid signature\");\n        } else if (error == RecoverError.InvalidSignatureLength) {\n            revert(\"ECDSA: invalid signature length\");\n        } else if (error == RecoverError.InvalidSignatureS) {\n            revert(\"ECDSA: invalid signature 's' value\");\n        } else if (error == RecoverError.InvalidSignatureV) {\n            revert(\"ECDSA: invalid signature 'v' value\");\n        }\n    }\n\n    /**\n     * @dev Returns the address that signed a hashed message (`hash`) with\n     * `signature` or error string. This address can then be used for verification purposes.\n     *\n     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:\n     * this function rejects them by requiring the `s` value to be in the lower\n     * half order, and the `v` value to be either 27 or 28.\n     *\n     * IMPORTANT: `hash` _must_ be the result of a hash operation for the\n     * verification to be secure: it is possible to craft signatures that\n     * recover to arbitrary addresses for non-hashed data. A safe way to ensure\n     * this is by receiving a hash of the original message (which may otherwise\n     * be too long), and then calling {toEthSignedMessageHash} on it.\n     *\n     * Documentation for signature generation:\n     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]\n     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]\n     *\n     * _Available since v4.3._\n     */\n    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {\n        // Check the signature length\n        // - case 65: r,s,v signature (standard)\n        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._\n        if (signature.length == 65) {\n            bytes32 r;\n            bytes32 s;\n            uint8 v;\n            // ecrecover takes the signature parameters, and the only way to get them\n            // currently is to use assembly.\n            assembly {\n                r := mload(add(signature, 0x20))\n                s := mload(add(signature, 0x40))\n                v := byte(0, mload(add(signature, 0x60)))\n            }\n            return tryRecover(hash, v, r, s);\n        } else if (signature.length == 64) {\n            bytes32 r;\n            bytes32 vs;\n            // ecrecover takes the signature parameters, and the only way to get them\n            // currently is to use assembly.\n            assembly {\n                r := mload(add(signature, 0x20))\n                vs := mload(add(signature, 0x40))\n            }\n            return tryRecover(hash, r, vs);\n        } else {\n            return (address(0), RecoverError.InvalidSignatureLength);\n        }\n    }\n\n    /**\n     * @dev Returns the address that signed a hashed message (`hash`) with\n     * `signature`. This address can then be used for verification purposes.\n     *\n     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:\n     * this function rejects them by requiring the `s` value to be in the lower\n     * half order, and the `v` value to be either 27 or 28.\n     *\n     * IMPORTANT: `hash` _must_ be the result of a hash operation for the\n     * verification to be secure: it is possible to craft signatures that\n     * recover to arbitrary addresses for non-hashed data. A safe way to ensure\n     * this is by receiving a hash of the original message (which may otherwise\n     * be too long), and then calling {toEthSignedMessageHash} on it.\n     */\n    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {\n        (address recovered, RecoverError error) = tryRecover(hash, signature);\n        _throwError(error);\n        return recovered;\n    }\n\n    /**\n     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.\n     *\n     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]\n     *\n     * _Available since v4.3._\n     */\n    function tryRecover(\n        bytes32 hash,\n        bytes32 r,\n        bytes32 vs\n    ) internal pure returns (address, RecoverError) {\n        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);\n        uint8 v = uint8((uint256(vs) >> 255) + 27);\n        return tryRecover(hash, v, r, s);\n    }\n\n    /**\n     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.\n     *\n     * _Available since v4.2._\n     */\n    function recover(\n        bytes32 hash,\n        bytes32 r,\n        bytes32 vs\n    ) internal pure returns (address) {\n        (address recovered, RecoverError error) = tryRecover(hash, r, vs);\n        _throwError(error);\n        return recovered;\n    }\n\n    /**\n     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,\n     * `r` and `s` signature fields separately.\n     *\n     * _Available since v4.3._\n     */\n    function tryRecover(\n        bytes32 hash,\n        uint8 v,\n        bytes32 r,\n        bytes32 s\n    ) internal pure returns (address, RecoverError) {\n        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature\n        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines\n        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most\n        // signatures from current libraries generate a unique signature with an s-value in the lower half order.\n        //\n        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value\n        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or\n        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept\n        // these malleable signatures as well.\n        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {\n            return (address(0), RecoverError.InvalidSignatureS);\n        }\n        if (v != 27 && v != 28) {\n            return (address(0), RecoverError.InvalidSignatureV);\n        }\n\n        // If the signature is valid (and not malleable), return the signer address\n        address signer = ecrecover(hash, v, r, s);\n        if (signer == address(0)) {\n            return (address(0), RecoverError.InvalidSignature);\n        }\n\n        return (signer, RecoverError.NoError);\n    }\n\n    /**\n     * @dev Overload of {ECDSA-recover} that receives the `v`,\n     * `r` and `s` signature fields separately.\n     */\n    function recover(\n        bytes32 hash,\n        uint8 v,\n        bytes32 r,\n        bytes32 s\n    ) internal pure returns (address) {\n        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);\n        _throwError(error);\n        return recovered;\n    }\n\n    /**\n     * @dev Returns an Ethereum Signed Message, created from a `hash`. This\n     * produces hash corresponding to the one signed with the\n     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]\n     * JSON-RPC method as part of EIP-191.\n     *\n     * See {recover}.\n     */\n    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {\n        // 32 is the length in bytes of hash,\n        // enforced by the type signature above\n        return keccak256(abi.encodePacked(\"\\x19Ethereum Signed Message:\\n32\", hash));\n    }\n\n    /**\n     * @dev Returns an Ethereum Signed Message, created from `s`. This\n     * produces hash corresponding to the one signed with the\n     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]\n     * JSON-RPC method as part of EIP-191.\n     *\n     * See {recover}.\n     */\n    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {\n        return keccak256(abi.encodePacked(\"\\x19Ethereum Signed Message:\\n\", Strings.toString(s.length), s));\n    }\n\n    /**\n     * @dev Returns an Ethereum Signed Typed Data, created from a\n     * `domainSeparator` and a `structHash`. This produces hash corresponding\n     * to the one signed with the\n     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]\n     * JSON-RPC method as part of EIP-712.\n     *\n     * See {recover}.\n     */\n    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {\n        return keccak256(abi.encodePacked(\"\\x19\\x01\", domainSeparator, structHash));\n    }\n}\n"
    },
    "contracts/ReentrancyGuard.sol": {
      "content": "// SPDX-License-Identifier: MIT\n\npragma solidity >=0.8.4;\n\nimport \"./Errors.sol\";\n\nabstract contract ReentrancyGuard {\n    uint256 private unlocked = 1;\n    modifier lock() {\n        if (unlocked == 0) revert Errors.ContractLocked();\n\n        unlocked = 0;\n        _;\n        unlocked = 1;\n    }\n}\n"
    },
    "contracts/Signable.sol": {
      "content": "// SPDX-License-Identifier: MIT\n\npragma solidity ^0.8.4;\n\nimport \"@rari-capital/solmate/src/auth/Owned.sol\";\nimport \"./Errors.sol\";\n\n/// @title Contract that manages the signer/owner roles\nabstract contract Signable is Owned {\n    address private _signer;\n\n    constructor() Owned(msg.sender) {\n        _signer = msg.sender;\n    }\n\n    function signer() public view returns (address) {\n        return _signer;\n    }\n\n    /// @notice This method allow the owner change the signer role\n    /// @dev At first, the signer role and the owner role is associated to the same address\n    /// @param newSigner The address of the new signer\n    function transferSigner(address newSigner) external onlyOwner {\n        if (newSigner == address(0)) revert Errors.NewSignerCantBeZero();\n\n        _signer = newSigner;\n    }\n}\n"
    },
    "contracts/IProxyTracking.sol": {
      "content": "// SPDX-License-Identifier: MIT\n\npragma solidity >=0.8.4;\n\ninterface IProxyTracking {\n    /**\n     * @dev Called by original contract on _afterTokenTransfer ERC721 event.\n     *\n     * WARNING: Good practice will be to check that msg.sender is original contract, for example: require(msg.sender == _originalContract, \"Only original contract can call this\");\n     *\n     */\n    function afterTokenTransfer(\n        address from,\n        address to,\n        uint256 tokenId\n    ) external;\n}"
    },
    "contracts/Helpers.sol": {
      "content": "// SPDX-License-Identifier: MIT\npragma solidity >=0.8.4;\n\nlibrary Helpers {\n    function uint2string(uint256 value) internal pure returns (string memory) {\n        // Inspired by OraclizeAPI's implementation - MIT licence\n        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol\n\n        if (value == 0) {\n            return \"0\";\n        }\n        uint256 temp = value;\n        uint256 digits;\n        while (temp != 0) {\n            digits++;\n            temp /= 10;\n        }\n        bytes memory buffer = new bytes(digits);\n        while (value != 0) {\n            digits -= 1;\n            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));\n            value /= 10;\n        }\n        return string(buffer);\n    }\n}\n"
    },
    "contracts/Errors.sol": {
      "content": "// SPDX-License-Identifier: MIT\n\npragma solidity >=0.8.4;\n\nlibrary Errors {\n    /* LedgerNFT.sol */\n    error MintNotAvailable();\n    error InsufficientFunds();\n    error SupplyLimitReached();\n    error ContractCantMint();\n    error InvalidSignature();\n    error AccountAlreadyMintedMax();\n    error TokenDoesNotExist();\n    error NotOwner();\n\n    error NothingToWithdraw();\n    error WithdrawFailed();\n    error InvalidMintPrice();\n    error MintPriceAlreadyUpdated();\n    error InvalidBaseContractURL();\n    error InvalidBaseURI();\n\n    /* ReentrancyGuard.sol */\n    error ContractLocked();\n\n    /* Signable.sol */\n    error NewSignerCantBeZero();\n\n}\n"
    },
    "@openzeppelin/contracts/utils/Strings.sol": {
      "content": "// SPDX-License-Identifier: MIT\n// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)\n\npragma solidity ^0.8.0;\n\n/**\n * @dev String operations.\n */\nlibrary Strings {\n    bytes16 private constant _HEX_SYMBOLS = \"0123456789abcdef\";\n\n    /**\n     * @dev Converts a `uint256` to its ASCII `string` decimal representation.\n     */\n    function toString(uint256 value) internal pure returns (string memory) {\n        // Inspired by OraclizeAPI's implementation - MIT licence\n        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol\n\n        if (value == 0) {\n            return \"0\";\n        }\n        uint256 temp = value;\n        uint256 digits;\n        while (temp != 0) {\n            digits++;\n            temp /= 10;\n        }\n        bytes memory buffer = new bytes(digits);\n        while (value != 0) {\n            digits -= 1;\n            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));\n            value /= 10;\n        }\n        return string(buffer);\n    }\n\n    /**\n     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.\n     */\n    function toHexString(uint256 value) internal pure returns (string memory) {\n        if (value == 0) {\n            return \"0x00\";\n        }\n        uint256 temp = value;\n        uint256 length = 0;\n        while (temp != 0) {\n            length++;\n            temp >>= 8;\n        }\n        return toHexString(value, length);\n    }\n\n    /**\n     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.\n     */\n    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {\n        bytes memory buffer = new bytes(2 * length + 2);\n        buffer[0] = \"0\";\n        buffer[1] = \"x\";\n        for (uint256 i = 2 * length + 1; i > 1; --i) {\n            buffer[i] = _HEX_SYMBOLS[value & 0xf];\n            value >>= 4;\n        }\n        require(value == 0, \"Strings: hex length insufficient\");\n        return string(buffer);\n    }\n}\n"
    },
    "@rari-capital/solmate/src/auth/Owned.sol": {
      "content": "// SPDX-License-Identifier: AGPL-3.0-only\npragma solidity >=0.8.0;\n\n/// @notice Simple single owner authorization mixin.\n/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/auth/Owned.sol)\nabstract contract Owned {\n    /*//////////////////////////////////////////////////////////////\n                                 EVENTS\n    //////////////////////////////////////////////////////////////*/\n\n    event OwnerUpdated(address indexed user, address indexed newOwner);\n\n    /*//////////////////////////////////////////////////////////////\n                            OWNERSHIP STORAGE\n    //////////////////////////////////////////////////////////////*/\n\n    address public owner;\n\n    modifier onlyOwner() virtual {\n        require(msg.sender == owner, \"UNAUTHORIZED\");\n\n        _;\n    }\n\n    /*//////////////////////////////////////////////////////////////\n                               CONSTRUCTOR\n    //////////////////////////////////////////////////////////////*/\n\n    constructor(address _owner) {\n        owner = _owner;\n\n        emit OwnerUpdated(address(0), _owner);\n    }\n\n    /*//////////////////////////////////////////////////////////////\n                             OWNERSHIP LOGIC\n    //////////////////////////////////////////////////////////////*/\n\n    function setOwner(address newOwner) public virtual onlyOwner {\n        owner = newOwner;\n\n        emit OwnerUpdated(msg.sender, newOwner);\n    }\n}\n"
    }
  },
  "settings": {
    "optimizer": {
      "enabled": true,
      "runs": 200
    },
    "outputSelection": {
      "*": {
        "*": [
          "evm.bytecode",
          "evm.deployedBytecode",
          "devdoc",
          "userdoc",
          "metadata",
          "abi"
        ]
      }
    },
    "libraries": {}
  }
}}