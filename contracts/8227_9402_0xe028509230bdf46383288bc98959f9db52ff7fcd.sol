{{
  "language": "Solidity",
  "sources": {
    "contracts/EMatesMinter.sol": {
      "content": "// SPDX-License-Identifier: MIT\r\npragma solidity ^0.8.9;\r\n\r\nimport \"@openzeppelin/contracts/access/Ownable.sol\";\r\nimport \"./interfaces/IEMatesMinter.sol\";\r\n\r\ncontract EMatesMinter is Ownable, IEMatesMinter {\r\n    IEMates public immutable emates;\r\n    IEthereumMix public immutable emix;\r\n    uint256 public mintPrice;\r\n\r\n    uint256 public limit;\r\n\r\n    constructor(\r\n        IEMates _emates,\r\n        IEthereumMix _emix,\r\n        uint256 _mintPrice\r\n    ) {\r\n        emates = _emates;\r\n        emix = _emix;\r\n        mintPrice = _mintPrice;\r\n\r\n        emit SetMintPrice(_mintPrice);\r\n    }\r\n\r\n    function setLimit(uint256 _limit) external onlyOwner {\r\n        limit = _limit;\r\n        emit SetLimit(_limit);\r\n    }\r\n\r\n    function setMintPrice(uint256 _price) external onlyOwner {\r\n        mintPrice = _price;\r\n        emit SetMintPrice(_price);\r\n    }\r\n\r\n    function mint() public returns (uint256 id) {\r\n        require(emates.totalSupply() < limit, \"EMatesMinter: Limit exceeded\");\r\n        id = emates.mint(msg.sender);\r\n        emix.transferFrom(msg.sender, address(this), mintPrice);\r\n    }\r\n\r\n    function mintWithPermit(\r\n        uint256 deadline,\r\n        uint8 v,\r\n        bytes32 r,\r\n        bytes32 s\r\n    ) external returns (uint256 id) {\r\n        emix.permit(msg.sender, address(this), mintPrice, deadline, v, r, s);\r\n        id = mint();\r\n    }\r\n\r\n    function withdrawEmix() external onlyOwner {\r\n        emix.transfer(msg.sender, emix.balanceOf(address(this)));\r\n    }\r\n}\r\n"
    },
    "@openzeppelin/contracts/access/Ownable.sol": {
      "content": "// SPDX-License-Identifier: MIT\n\npragma solidity ^0.8.0;\n\nimport \"../utils/Context.sol\";\n\n/**\n * @dev Contract module which provides a basic access control mechanism, where\n * there is an account (an owner) that can be granted exclusive access to\n * specific functions.\n *\n * By default, the owner account will be the one that deploys the contract. This\n * can later be changed with {transferOwnership}.\n *\n * This module is used through inheritance. It will make available the modifier\n * `onlyOwner`, which can be applied to your functions to restrict their use to\n * the owner.\n */\nabstract contract Ownable is Context {\n    address private _owner;\n\n    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);\n\n    /**\n     * @dev Initializes the contract setting the deployer as the initial owner.\n     */\n    constructor() {\n        _setOwner(_msgSender());\n    }\n\n    /**\n     * @dev Returns the address of the current owner.\n     */\n    function owner() public view virtual returns (address) {\n        return _owner;\n    }\n\n    /**\n     * @dev Throws if called by any account other than the owner.\n     */\n    modifier onlyOwner() {\n        require(owner() == _msgSender(), \"Ownable: caller is not the owner\");\n        _;\n    }\n\n    /**\n     * @dev Leaves the contract without owner. It will not be possible to call\n     * `onlyOwner` functions anymore. Can only be called by the current owner.\n     *\n     * NOTE: Renouncing ownership will leave the contract without an owner,\n     * thereby removing any functionality that is only available to the owner.\n     */\n    function renounceOwnership() public virtual onlyOwner {\n        _setOwner(address(0));\n    }\n\n    /**\n     * @dev Transfers ownership of the contract to a new account (`newOwner`).\n     * Can only be called by the current owner.\n     */\n    function transferOwnership(address newOwner) public virtual onlyOwner {\n        require(newOwner != address(0), \"Ownable: new owner is the zero address\");\n        _setOwner(newOwner);\n    }\n\n    function _setOwner(address newOwner) private {\n        address oldOwner = _owner;\n        _owner = newOwner;\n        emit OwnershipTransferred(oldOwner, newOwner);\n    }\n}\n"
    },
    "contracts/interfaces/IEMatesMinter.sol": {
      "content": "// SPDX-License-Identifier: MIT\r\npragma solidity ^0.8.9;\r\n\r\nimport \"./IEMates.sol\";\r\nimport \"./IEthereumMix.sol\";\r\n\r\ninterface IEMatesMinter {\r\n    event SetMintPrice(uint256 mintPrice);\r\n    event SetLimit(uint256 limit);\r\n\r\n    function emates() external view returns (IEMates);\r\n    function emix() external view returns (IEthereumMix);\r\n    function mintPrice() external view returns (uint256);\r\n    function limit() external view returns (uint256);\r\n\r\n    function mint() external returns (uint256 id);\r\n    function mintWithPermit(\r\n        uint256 deadline,\r\n        uint8 v,\r\n        bytes32 r,\r\n        bytes32 s\r\n    ) external returns (uint256 id);\r\n}\r\n"
    },
    "@openzeppelin/contracts/utils/Context.sol": {
      "content": "// SPDX-License-Identifier: MIT\n\npragma solidity ^0.8.0;\n\n/**\n * @dev Provides information about the current execution context, including the\n * sender of the transaction and its data. While these are generally available\n * via msg.sender and msg.data, they should not be accessed in such a direct\n * manner, since when dealing with meta-transactions the account sending and\n * paying for execution may not be the actual sender (as far as an application\n * is concerned).\n *\n * This contract is only required for intermediate, library-like contracts.\n */\nabstract contract Context {\n    function _msgSender() internal view virtual returns (address) {\n        return msg.sender;\n    }\n\n    function _msgData() internal view virtual returns (bytes calldata) {\n        return msg.data;\n    }\n}\n"
    },
    "contracts/interfaces/IEMates.sol": {
      "content": "// SPDX-License-Identifier: MIT\r\npragma solidity ^0.8.9;\r\n\r\nimport \"@openzeppelin/contracts/token/ERC721/IERC721.sol\";\r\nimport \"@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol\";\r\nimport \"./IERC2981.sol\";\r\n\r\ninterface IEMates is IERC721, IERC721Metadata, IERC2981 {\r\n    event SetMinter(address indexed target, bool indexed isMinter);\r\n    event SetRoyaltyInfo(address indexed receiver, uint256 fee);\r\n    event SetContractURI(string uri);\r\n    event SetBaseURI(string uri);\r\n\r\n    function DOMAIN_SEPARATOR() external view returns (bytes32);\r\n    function PERMIT_TYPEHASH() external view returns (bytes32);\r\n    function PERMIT_ALL_TYPEHASH() external view returns (bytes32);\r\n    function nonces(uint256 id) external view returns (uint256);\r\n    function noncesForAll(address owner) external view returns (uint256);\r\n\r\n    function totalSupply() external view returns (uint256);\r\n    function isMinter(address target) external view returns (bool);\r\n\r\n    function feeReceiver() external view returns (address);\r\n    function fee() external view returns (uint256);\r\n\r\n    function contractURI() external view returns (string calldata);\r\n\r\n    function permit(\r\n        address spender,\r\n        uint256 id,\r\n        uint256 deadline,\r\n        uint8 v,\r\n        bytes32 r,\r\n        bytes32 s\r\n    ) external;\r\n\r\n    function permitAll(\r\n        address owner,\r\n        address spender,\r\n        uint256 deadline,\r\n        uint8 v,\r\n        bytes32 r,\r\n        bytes32 s\r\n    ) external;\r\n\r\n    function mint(address to) external returns (uint256 id);\r\n\r\n    function mintBatch(uint256 limit) external;\r\n}\r\n"
    },
    "contracts/interfaces/IEthereumMix.sol": {
      "content": "// SPDX-License-Identifier: MIT\r\npragma solidity ^0.8.9;\r\n\r\nimport \"./IFungibleToken.sol\";\r\n\r\ninterface IEthereumMix is IFungibleToken {\r\n\r\n    event SetSigner(address indexed signer);\r\n    event SendOverHorizon(address indexed sender, uint256 indexed toChain, address indexed receiver, uint256 sendId, uint256 amount);\r\n    event ReceiveOverHorizon(address indexed receiver, uint256 indexed fromChain, address indexed sender, uint256 sendId, uint256 amount);\r\n\r\n    function signer() external view returns (address);\r\n    function sendOverHorizon(uint256 toChain, address receiver, uint256 amount) external returns (uint256 sendId);\r\n    function sended(address sender, uint256 toChain, address receiver, uint256 sendId) external view returns (uint256 amount);\r\n    function sendCount(address sender, uint256 toChain, address receiver) external view returns (uint256);\r\n    function receiveOverHorizon(uint256 fromChain, uint256 toChain, address sender, uint256 sendId, uint256 amount, bytes calldata signature) external;\r\n    function received(address receiver, uint256 fromChain, address sender, uint256 sendId) external view returns (bool);\r\n}\r\n"
    },
    "@openzeppelin/contracts/token/ERC721/IERC721.sol": {
      "content": "// SPDX-License-Identifier: MIT\n\npragma solidity ^0.8.0;\n\nimport \"../../utils/introspection/IERC165.sol\";\n\n/**\n * @dev Required interface of an ERC721 compliant contract.\n */\ninterface IERC721 is IERC165 {\n    /**\n     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.\n     */\n    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);\n\n    /**\n     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.\n     */\n    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);\n\n    /**\n     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.\n     */\n    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);\n\n    /**\n     * @dev Returns the number of tokens in ``owner``'s account.\n     */\n    function balanceOf(address owner) external view returns (uint256 balance);\n\n    /**\n     * @dev Returns the owner of the `tokenId` token.\n     *\n     * Requirements:\n     *\n     * - `tokenId` must exist.\n     */\n    function ownerOf(uint256 tokenId) external view returns (address owner);\n\n    /**\n     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients\n     * are aware of the ERC721 protocol to prevent tokens from being forever locked.\n     *\n     * Requirements:\n     *\n     * - `from` cannot be the zero address.\n     * - `to` cannot be the zero address.\n     * - `tokenId` token must exist and be owned by `from`.\n     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.\n     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.\n     *\n     * Emits a {Transfer} event.\n     */\n    function safeTransferFrom(\n        address from,\n        address to,\n        uint256 tokenId\n    ) external;\n\n    /**\n     * @dev Transfers `tokenId` token from `from` to `to`.\n     *\n     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.\n     *\n     * Requirements:\n     *\n     * - `from` cannot be the zero address.\n     * - `to` cannot be the zero address.\n     * - `tokenId` token must be owned by `from`.\n     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.\n     *\n     * Emits a {Transfer} event.\n     */\n    function transferFrom(\n        address from,\n        address to,\n        uint256 tokenId\n    ) external;\n\n    /**\n     * @dev Gives permission to `to` to transfer `tokenId` token to another account.\n     * The approval is cleared when the token is transferred.\n     *\n     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.\n     *\n     * Requirements:\n     *\n     * - The caller must own the token or be an approved operator.\n     * - `tokenId` must exist.\n     *\n     * Emits an {Approval} event.\n     */\n    function approve(address to, uint256 tokenId) external;\n\n    /**\n     * @dev Returns the account approved for `tokenId` token.\n     *\n     * Requirements:\n     *\n     * - `tokenId` must exist.\n     */\n    function getApproved(uint256 tokenId) external view returns (address operator);\n\n    /**\n     * @dev Approve or remove `operator` as an operator for the caller.\n     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.\n     *\n     * Requirements:\n     *\n     * - The `operator` cannot be the caller.\n     *\n     * Emits an {ApprovalForAll} event.\n     */\n    function setApprovalForAll(address operator, bool _approved) external;\n\n    /**\n     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.\n     *\n     * See {setApprovalForAll}\n     */\n    function isApprovedForAll(address owner, address operator) external view returns (bool);\n\n    /**\n     * @dev Safely transfers `tokenId` token from `from` to `to`.\n     *\n     * Requirements:\n     *\n     * - `from` cannot be the zero address.\n     * - `to` cannot be the zero address.\n     * - `tokenId` token must exist and be owned by `from`.\n     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.\n     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.\n     *\n     * Emits a {Transfer} event.\n     */\n    function safeTransferFrom(\n        address from,\n        address to,\n        uint256 tokenId,\n        bytes calldata data\n    ) external;\n}\n"
    },
    "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol": {
      "content": "// SPDX-License-Identifier: MIT\n\npragma solidity ^0.8.0;\n\nimport \"../IERC721.sol\";\n\n/**\n * @title ERC-721 Non-Fungible Token Standard, optional metadata extension\n * @dev See https://eips.ethereum.org/EIPS/eip-721\n */\ninterface IERC721Metadata is IERC721 {\n    /**\n     * @dev Returns the token collection name.\n     */\n    function name() external view returns (string memory);\n\n    /**\n     * @dev Returns the token collection symbol.\n     */\n    function symbol() external view returns (string memory);\n\n    /**\n     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.\n     */\n    function tokenURI(uint256 tokenId) external view returns (string memory);\n}\n"
    },
    "contracts/interfaces/IERC2981.sol": {
      "content": "// SPDX-License-Identifier: MIT\r\npragma solidity ^0.8.9;\r\n\r\nimport \"@openzeppelin/contracts/utils/introspection/IERC165.sol\";\r\n\r\n///\r\n/// @dev Interface for the NFT Royalty Standard\r\n///\r\ninterface IERC2981 is IERC165 {\r\n    /// ERC165 bytes to add to interface array - set in parent contract\r\n    /// implementing this standard\r\n    ///\r\n    /// bytes4(keccak256(\"royaltyInfo(uint256,uint256)\")) == 0x2a55205a\r\n    /// bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;\r\n    /// _registerInterface(_INTERFACE_ID_ERC2981);\r\n\r\n    /// @notice Called with the sale price to determine how much royalty\r\n    //          is owed and to whom.\r\n    /// @param _tokenId - the NFT asset queried for royalty information\r\n    /// @param _salePrice - the sale price of the NFT asset specified by _tokenId\r\n    /// @return receiver - address of who should be sent the royalty payment\r\n    /// @return royaltyAmount - the royalty payment amount for _salePrice\r\n    function royaltyInfo(uint256 _tokenId, uint256 _salePrice)\r\n        external\r\n        view\r\n        returns (address receiver, uint256 royaltyAmount);\r\n}\r\n"
    },
    "@openzeppelin/contracts/utils/introspection/IERC165.sol": {
      "content": "// SPDX-License-Identifier: MIT\n\npragma solidity ^0.8.0;\n\n/**\n * @dev Interface of the ERC165 standard, as defined in the\n * https://eips.ethereum.org/EIPS/eip-165[EIP].\n *\n * Implementers can declare support of contract interfaces, which can then be\n * queried by others ({ERC165Checker}).\n *\n * For an implementation, see {ERC165}.\n */\ninterface IERC165 {\n    /**\n     * @dev Returns true if this contract implements the interface defined by\n     * `interfaceId`. See the corresponding\n     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]\n     * to learn more about how these ids are created.\n     *\n     * This function call must use less than 30 000 gas.\n     */\n    function supportsInterface(bytes4 interfaceId) external view returns (bool);\n}\n"
    },
    "contracts/interfaces/IFungibleToken.sol": {
      "content": "\r\n// SPDX-License-Identifier: MIT\r\npragma solidity ^0.8.9;\r\n\r\nimport \"@openzeppelin/contracts/token/ERC20/IERC20.sol\";\r\n\r\ninterface IFungibleToken is IERC20 {\r\n    \r\n    function version() external view returns (string memory);\r\n\r\n    function DOMAIN_SEPARATOR() external view returns (bytes32);\r\n    function PERMIT_TYPEHASH() external view returns (bytes32);\r\n    function nonces(address owner) external view returns (uint256);\r\n\r\n    function permit(\r\n        address owner,\r\n        address spender,\r\n        uint256 value,\r\n        uint256 deadline,\r\n        uint8 v,\r\n        bytes32 r,\r\n        bytes32 s\r\n    ) external;\r\n}"
    },
    "@openzeppelin/contracts/token/ERC20/IERC20.sol": {
      "content": "// SPDX-License-Identifier: MIT\n\npragma solidity ^0.8.0;\n\n/**\n * @dev Interface of the ERC20 standard as defined in the EIP.\n */\ninterface IERC20 {\n    /**\n     * @dev Returns the amount of tokens in existence.\n     */\n    function totalSupply() external view returns (uint256);\n\n    /**\n     * @dev Returns the amount of tokens owned by `account`.\n     */\n    function balanceOf(address account) external view returns (uint256);\n\n    /**\n     * @dev Moves `amount` tokens from the caller's account to `recipient`.\n     *\n     * Returns a boolean value indicating whether the operation succeeded.\n     *\n     * Emits a {Transfer} event.\n     */\n    function transfer(address recipient, uint256 amount) external returns (bool);\n\n    /**\n     * @dev Returns the remaining number of tokens that `spender` will be\n     * allowed to spend on behalf of `owner` through {transferFrom}. This is\n     * zero by default.\n     *\n     * This value changes when {approve} or {transferFrom} are called.\n     */\n    function allowance(address owner, address spender) external view returns (uint256);\n\n    /**\n     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.\n     *\n     * Returns a boolean value indicating whether the operation succeeded.\n     *\n     * IMPORTANT: Beware that changing an allowance with this method brings the risk\n     * that someone may use both the old and the new allowance by unfortunate\n     * transaction ordering. One possible solution to mitigate this race\n     * condition is to first reduce the spender's allowance to 0 and set the\n     * desired value afterwards:\n     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729\n     *\n     * Emits an {Approval} event.\n     */\n    function approve(address spender, uint256 amount) external returns (bool);\n\n    /**\n     * @dev Moves `amount` tokens from `sender` to `recipient` using the\n     * allowance mechanism. `amount` is then deducted from the caller's\n     * allowance.\n     *\n     * Returns a boolean value indicating whether the operation succeeded.\n     *\n     * Emits a {Transfer} event.\n     */\n    function transferFrom(\n        address sender,\n        address recipient,\n        uint256 amount\n    ) external returns (bool);\n\n    /**\n     * @dev Emitted when `value` tokens are moved from one account (`from`) to\n     * another (`to`).\n     *\n     * Note that `value` may be zero.\n     */\n    event Transfer(address indexed from, address indexed to, uint256 value);\n\n    /**\n     * @dev Emitted when the allowance of a `spender` for an `owner` is set by\n     * a call to {approve}. `value` is the new allowance.\n     */\n    event Approval(address indexed owner, address indexed spender, uint256 value);\n}\n"
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