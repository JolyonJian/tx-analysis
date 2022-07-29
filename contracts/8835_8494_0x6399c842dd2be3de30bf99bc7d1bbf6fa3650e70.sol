{{
  "language": "Solidity",
  "sources": {
    "contracts/PremiaErc20.sol": {
      "content": "// SPDX-License-Identifier: MIT\r\n\r\npragma solidity ^0.7.0;\r\n\r\nimport \"./ERC20Permit.sol\";\r\n\r\n/// @author Premia\r\n/// @title The Premia token\r\ncontract PremiaErc20 is ERC20Permit {\r\n    constructor() ERC20(\"Premia\", \"PREMIA\") {\r\n        _mint(msg.sender, 1e26); // 100m\r\n    }\r\n}"
    },
    "contracts/ERC20Permit.sol": {
      "content": "// SPDX-License-Identifier: MIT\r\npragma solidity ^0.7.0;\r\n\r\nimport \"@openzeppelin/contracts/token/ERC20/ERC20.sol\";\r\nimport \"@openzeppelin/contracts/utils/Counters.sol\";\r\n\r\nimport \"./interface/IERC2612Permit.sol\";\r\n\r\n\r\n// ERC20-Permit implementation from soliditylabs ( https://github.com/soliditylabs/ERC20-Permit )\r\n\r\n/**\r\n * @dev Extension of {ERC20} that allows token holders to use their tokens\r\n * without sending any transactions by setting {IERC20-allowance} with a\r\n * signature using the {permit} method, and then spend them via\r\n * {IERC20-transferFrom}.\r\n *\r\n * The {permit} signature mechanism conforms to the {IERC2612Permit} interface.\r\n */\r\nabstract contract ERC20Permit is ERC20, IERC2612Permit {\r\n    using Counters for Counters.Counter;\r\n\r\n    mapping(address => Counters.Counter) private _nonces;\r\n\r\n    // Mapping of ChainID to domain separators. This is a very gas efficient way\r\n    // to not recalculate the domain separator on every call, while still\r\n    // automatically detecting ChainID changes.\r\n    mapping(uint256 => bytes32) public domainSeparators;\r\n\r\n    constructor() {\r\n        _updateDomainSeparator();\r\n    }\r\n\r\n    /**\r\n     * @dev See {IERC2612Permit-permit}.\r\n     *\r\n     * If https://eips.ethereum.org/EIPS/eip-1344[ChainID] ever changes, the\r\n     * EIP712 Domain Separator is automatically recalculated.\r\n     */\r\n    function permit(\r\n        address owner,\r\n        address spender,\r\n        uint256 amount,\r\n        uint256 deadline,\r\n        uint8 v,\r\n        bytes32 r,\r\n        bytes32 s\r\n    ) public virtual override {\r\n        require(block.timestamp <= deadline, \"ERC20Permit: expired deadline\");\r\n\r\n        // Assembly for more efficiently computing:\r\n        // bytes32 hashStruct = keccak256(\r\n        //     abi.encode(\r\n        //         _PERMIT_TYPEHASH,\r\n        //         owner,\r\n        //         spender,\r\n        //         amount,\r\n        //         _nonces[owner].current(),\r\n        //         deadline\r\n        //     )\r\n        // );\r\n\r\n        bytes32 hashStruct;\r\n        uint256 nonce = _nonces[owner].current();\r\n\r\n        assembly {\r\n        // Load free memory pointer\r\n            let memPtr := mload(64)\r\n\r\n        // keccak256(\"Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)\")\r\n            mstore(memPtr, 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9)\r\n            mstore(add(memPtr, 32), owner)\r\n            mstore(add(memPtr, 64), spender)\r\n            mstore(add(memPtr, 96), amount)\r\n            mstore(add(memPtr, 128), nonce)\r\n            mstore(add(memPtr, 160), deadline)\r\n\r\n            hashStruct := keccak256(memPtr, 192)\r\n        }\r\n\r\n        bytes32 eip712DomainHash = _domainSeparator();\r\n\r\n        // Assembly for more efficient computing:\r\n        // bytes32 hash = keccak256(\r\n        //     abi.encodePacked(uint16(0x1901), eip712DomainHash, hashStruct)\r\n        // );\r\n\r\n        bytes32 hash;\r\n\r\n        assembly {\r\n        // Load free memory pointer\r\n            let memPtr := mload(64)\r\n\r\n            mstore(memPtr, 0x1901000000000000000000000000000000000000000000000000000000000000)  // EIP191 header\r\n            mstore(add(memPtr, 2), eip712DomainHash)                                            // EIP712 domain hash\r\n            mstore(add(memPtr, 34), hashStruct)                                                 // Hash of struct\r\n\r\n            hash := keccak256(memPtr, 66)\r\n        }\r\n\r\n        address signer = _recover(hash, v, r, s);\r\n\r\n        require(signer == owner, \"ERC20Permit: invalid signature\");\r\n\r\n        _nonces[owner].increment();\r\n        _approve(owner, spender, amount);\r\n    }\r\n\r\n    /**\r\n     * @dev See {IERC2612Permit-nonces}.\r\n     */\r\n    function nonces(address owner) public override view returns (uint256) {\r\n        return _nonces[owner].current();\r\n    }\r\n\r\n    function _updateDomainSeparator() private returns (bytes32) {\r\n        uint256 chainID = _chainID();\r\n\r\n        // no need for assembly, running very rarely\r\n        bytes32 newDomainSeparator = keccak256(\r\n            abi.encode(\r\n                keccak256(\r\n                    \"EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)\"\r\n                ),\r\n                keccak256(bytes(name())), // ERC-20 Name\r\n                keccak256(bytes(\"1\")),    // Version\r\n                chainID,\r\n                address(this)\r\n            )\r\n        );\r\n\r\n        domainSeparators[chainID] = newDomainSeparator;\r\n\r\n        return newDomainSeparator;\r\n    }\r\n\r\n    // Returns the domain separator, updating it if chainID changes\r\n    function _domainSeparator() private returns (bytes32) {\r\n        bytes32 domainSeparator = domainSeparators[_chainID()];\r\n\r\n        if (domainSeparator != 0x00) {\r\n            return domainSeparator;\r\n        }\r\n\r\n        return _updateDomainSeparator();\r\n    }\r\n\r\n    function _chainID() private pure returns (uint256) {\r\n        uint256 chainID;\r\n        assembly {\r\n            chainID := chainid()\r\n        }\r\n\r\n        return chainID;\r\n    }\r\n\r\n    function _recover(\r\n        bytes32 hash,\r\n        uint8 v,\r\n        bytes32 r,\r\n        bytes32 s\r\n    ) internal pure returns (address) {\r\n        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature\r\n        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines\r\n        // the valid range for s in (281): 0 < s < secp256k1n ÷ 2 + 1, and for v in (282): v ∈ {27, 28}. Most\r\n        // signatures from current libraries generate a unique signature with an s-value in the lower half order.\r\n        //\r\n        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value\r\n        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or\r\n        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept\r\n        // these malleable signatures as well.\r\n        if (\r\n            uint256(s) >\r\n            0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0\r\n        ) {\r\n            revert(\"ECDSA: invalid signature 's' value\");\r\n        }\r\n\r\n        if (v != 27 && v != 28) {\r\n            revert(\"ECDSA: invalid signature 'v' value\");\r\n        }\r\n\r\n        // If the signature is valid (and not malleable), return the signer address\r\n        address signer = ecrecover(hash, v, r, s);\r\n        require(signer != address(0), \"ECDSA: invalid signature\");\r\n\r\n        return signer;\r\n    }\r\n}\r\n"
    },
    "@openzeppelin/contracts/token/ERC20/ERC20.sol": {
      "content": "// SPDX-License-Identifier: MIT\n\npragma solidity >=0.6.0 <0.8.0;\n\nimport \"../../GSN/Context.sol\";\nimport \"./IERC20.sol\";\nimport \"../../math/SafeMath.sol\";\n\n/**\n * @dev Implementation of the {IERC20} interface.\n *\n * This implementation is agnostic to the way tokens are created. This means\n * that a supply mechanism has to be added in a derived contract using {_mint}.\n * For a generic mechanism see {ERC20PresetMinterPauser}.\n *\n * TIP: For a detailed writeup see our guide\n * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How\n * to implement supply mechanisms].\n *\n * We have followed general OpenZeppelin guidelines: functions revert instead\n * of returning `false` on failure. This behavior is nonetheless conventional\n * and does not conflict with the expectations of ERC20 applications.\n *\n * Additionally, an {Approval} event is emitted on calls to {transferFrom}.\n * This allows applications to reconstruct the allowance for all accounts just\n * by listening to said events. Other implementations of the EIP may not emit\n * these events, as it isn't required by the specification.\n *\n * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}\n * functions have been added to mitigate the well-known issues around setting\n * allowances. See {IERC20-approve}.\n */\ncontract ERC20 is Context, IERC20 {\n    using SafeMath for uint256;\n\n    mapping (address => uint256) private _balances;\n\n    mapping (address => mapping (address => uint256)) private _allowances;\n\n    uint256 private _totalSupply;\n\n    string private _name;\n    string private _symbol;\n    uint8 private _decimals;\n\n    /**\n     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with\n     * a default value of 18.\n     *\n     * To select a different value for {decimals}, use {_setupDecimals}.\n     *\n     * All three of these values are immutable: they can only be set once during\n     * construction.\n     */\n    constructor (string memory name_, string memory symbol_) public {\n        _name = name_;\n        _symbol = symbol_;\n        _decimals = 18;\n    }\n\n    /**\n     * @dev Returns the name of the token.\n     */\n    function name() public view returns (string memory) {\n        return _name;\n    }\n\n    /**\n     * @dev Returns the symbol of the token, usually a shorter version of the\n     * name.\n     */\n    function symbol() public view returns (string memory) {\n        return _symbol;\n    }\n\n    /**\n     * @dev Returns the number of decimals used to get its user representation.\n     * For example, if `decimals` equals `2`, a balance of `505` tokens should\n     * be displayed to a user as `5,05` (`505 / 10 ** 2`).\n     *\n     * Tokens usually opt for a value of 18, imitating the relationship between\n     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is\n     * called.\n     *\n     * NOTE: This information is only used for _display_ purposes: it in\n     * no way affects any of the arithmetic of the contract, including\n     * {IERC20-balanceOf} and {IERC20-transfer}.\n     */\n    function decimals() public view returns (uint8) {\n        return _decimals;\n    }\n\n    /**\n     * @dev See {IERC20-totalSupply}.\n     */\n    function totalSupply() public view override returns (uint256) {\n        return _totalSupply;\n    }\n\n    /**\n     * @dev See {IERC20-balanceOf}.\n     */\n    function balanceOf(address account) public view override returns (uint256) {\n        return _balances[account];\n    }\n\n    /**\n     * @dev See {IERC20-transfer}.\n     *\n     * Requirements:\n     *\n     * - `recipient` cannot be the zero address.\n     * - the caller must have a balance of at least `amount`.\n     */\n    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {\n        _transfer(_msgSender(), recipient, amount);\n        return true;\n    }\n\n    /**\n     * @dev See {IERC20-allowance}.\n     */\n    function allowance(address owner, address spender) public view virtual override returns (uint256) {\n        return _allowances[owner][spender];\n    }\n\n    /**\n     * @dev See {IERC20-approve}.\n     *\n     * Requirements:\n     *\n     * - `spender` cannot be the zero address.\n     */\n    function approve(address spender, uint256 amount) public virtual override returns (bool) {\n        _approve(_msgSender(), spender, amount);\n        return true;\n    }\n\n    /**\n     * @dev See {IERC20-transferFrom}.\n     *\n     * Emits an {Approval} event indicating the updated allowance. This is not\n     * required by the EIP. See the note at the beginning of {ERC20}.\n     *\n     * Requirements:\n     *\n     * - `sender` and `recipient` cannot be the zero address.\n     * - `sender` must have a balance of at least `amount`.\n     * - the caller must have allowance for ``sender``'s tokens of at least\n     * `amount`.\n     */\n    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {\n        _transfer(sender, recipient, amount);\n        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, \"ERC20: transfer amount exceeds allowance\"));\n        return true;\n    }\n\n    /**\n     * @dev Atomically increases the allowance granted to `spender` by the caller.\n     *\n     * This is an alternative to {approve} that can be used as a mitigation for\n     * problems described in {IERC20-approve}.\n     *\n     * Emits an {Approval} event indicating the updated allowance.\n     *\n     * Requirements:\n     *\n     * - `spender` cannot be the zero address.\n     */\n    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {\n        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));\n        return true;\n    }\n\n    /**\n     * @dev Atomically decreases the allowance granted to `spender` by the caller.\n     *\n     * This is an alternative to {approve} that can be used as a mitigation for\n     * problems described in {IERC20-approve}.\n     *\n     * Emits an {Approval} event indicating the updated allowance.\n     *\n     * Requirements:\n     *\n     * - `spender` cannot be the zero address.\n     * - `spender` must have allowance for the caller of at least\n     * `subtractedValue`.\n     */\n    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {\n        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, \"ERC20: decreased allowance below zero\"));\n        return true;\n    }\n\n    /**\n     * @dev Moves tokens `amount` from `sender` to `recipient`.\n     *\n     * This is internal function is equivalent to {transfer}, and can be used to\n     * e.g. implement automatic token fees, slashing mechanisms, etc.\n     *\n     * Emits a {Transfer} event.\n     *\n     * Requirements:\n     *\n     * - `sender` cannot be the zero address.\n     * - `recipient` cannot be the zero address.\n     * - `sender` must have a balance of at least `amount`.\n     */\n    function _transfer(address sender, address recipient, uint256 amount) internal virtual {\n        require(sender != address(0), \"ERC20: transfer from the zero address\");\n        require(recipient != address(0), \"ERC20: transfer to the zero address\");\n\n        _beforeTokenTransfer(sender, recipient, amount);\n\n        _balances[sender] = _balances[sender].sub(amount, \"ERC20: transfer amount exceeds balance\");\n        _balances[recipient] = _balances[recipient].add(amount);\n        emit Transfer(sender, recipient, amount);\n    }\n\n    /** @dev Creates `amount` tokens and assigns them to `account`, increasing\n     * the total supply.\n     *\n     * Emits a {Transfer} event with `from` set to the zero address.\n     *\n     * Requirements:\n     *\n     * - `to` cannot be the zero address.\n     */\n    function _mint(address account, uint256 amount) internal virtual {\n        require(account != address(0), \"ERC20: mint to the zero address\");\n\n        _beforeTokenTransfer(address(0), account, amount);\n\n        _totalSupply = _totalSupply.add(amount);\n        _balances[account] = _balances[account].add(amount);\n        emit Transfer(address(0), account, amount);\n    }\n\n    /**\n     * @dev Destroys `amount` tokens from `account`, reducing the\n     * total supply.\n     *\n     * Emits a {Transfer} event with `to` set to the zero address.\n     *\n     * Requirements:\n     *\n     * - `account` cannot be the zero address.\n     * - `account` must have at least `amount` tokens.\n     */\n    function _burn(address account, uint256 amount) internal virtual {\n        require(account != address(0), \"ERC20: burn from the zero address\");\n\n        _beforeTokenTransfer(account, address(0), amount);\n\n        _balances[account] = _balances[account].sub(amount, \"ERC20: burn amount exceeds balance\");\n        _totalSupply = _totalSupply.sub(amount);\n        emit Transfer(account, address(0), amount);\n    }\n\n    /**\n     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.\n     *\n     * This internal function is equivalent to `approve`, and can be used to\n     * e.g. set automatic allowances for certain subsystems, etc.\n     *\n     * Emits an {Approval} event.\n     *\n     * Requirements:\n     *\n     * - `owner` cannot be the zero address.\n     * - `spender` cannot be the zero address.\n     */\n    function _approve(address owner, address spender, uint256 amount) internal virtual {\n        require(owner != address(0), \"ERC20: approve from the zero address\");\n        require(spender != address(0), \"ERC20: approve to the zero address\");\n\n        _allowances[owner][spender] = amount;\n        emit Approval(owner, spender, amount);\n    }\n\n    /**\n     * @dev Sets {decimals} to a value other than the default one of 18.\n     *\n     * WARNING: This function should only be called from the constructor. Most\n     * applications that interact with token contracts will not expect\n     * {decimals} to ever change, and may work incorrectly if it does.\n     */\n    function _setupDecimals(uint8 decimals_) internal {\n        _decimals = decimals_;\n    }\n\n    /**\n     * @dev Hook that is called before any transfer of tokens. This includes\n     * minting and burning.\n     *\n     * Calling conditions:\n     *\n     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens\n     * will be to transferred to `to`.\n     * - when `from` is zero, `amount` tokens will be minted for `to`.\n     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.\n     * - `from` and `to` are never both zero.\n     *\n     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].\n     */\n    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }\n}\n"
    },
    "@openzeppelin/contracts/utils/Counters.sol": {
      "content": "// SPDX-License-Identifier: MIT\n\npragma solidity >=0.6.0 <0.8.0;\n\nimport \"../math/SafeMath.sol\";\n\n/**\n * @title Counters\n * @author Matt Condon (@shrugs)\n * @dev Provides counters that can only be incremented or decremented by one. This can be used e.g. to track the number\n * of elements in a mapping, issuing ERC721 ids, or counting request ids.\n *\n * Include with `using Counters for Counters.Counter;`\n * Since it is not possible to overflow a 256 bit integer with increments of one, `increment` can skip the {SafeMath}\n * overflow check, thereby saving gas. This does assume however correct usage, in that the underlying `_value` is never\n * directly accessed.\n */\nlibrary Counters {\n    using SafeMath for uint256;\n\n    struct Counter {\n        // This variable should never be directly accessed by users of the library: interactions must be restricted to\n        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add\n        // this feature: see https://github.com/ethereum/solidity/issues/4637\n        uint256 _value; // default: 0\n    }\n\n    function current(Counter storage counter) internal view returns (uint256) {\n        return counter._value;\n    }\n\n    function increment(Counter storage counter) internal {\n        // The {SafeMath} overflow check can be skipped here, see the comment at the top\n        counter._value += 1;\n    }\n\n    function decrement(Counter storage counter) internal {\n        counter._value = counter._value.sub(1);\n    }\n}\n"
    },
    "contracts/interface/IERC2612Permit.sol": {
      "content": "//SPDX-License-Identifier: MIT\r\npragma solidity ^0.7.0;\r\n\r\n/**\r\n * @dev Interface of the ERC2612 standard as defined in the EIP.\r\n *\r\n * Adds the {permit} method, which can be used to change one's\r\n * {IERC20-allowance} without having to send a transaction, by signing a\r\n * message. This allows users to spend tokens without having to hold Ether.\r\n *\r\n * See https://eips.ethereum.org/EIPS/eip-2612.\r\n */\r\ninterface IERC2612Permit {\r\n    /**\r\n     * @dev Sets `amount` as the allowance of `spender` over `owner`'s tokens,\r\n     * given `owner`'s signed approval.\r\n     *\r\n     * IMPORTANT: The same issues {IERC20-approve} has related to transaction\r\n     * ordering also apply here.\r\n     *\r\n     * Emits an {Approval} event.\r\n     *\r\n     * Requirements:\r\n     *\r\n     * - `owner` cannot be the zero address.\r\n     * - `spender` cannot be the zero address.\r\n     * - `deadline` must be a timestamp in the future.\r\n     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`\r\n     * over the EIP712-formatted function arguments.\r\n     * - the signature must use ``owner``'s current nonce (see {nonces}).\r\n     *\r\n     * For more information on the signature format, see the\r\n     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP\r\n     * section].\r\n     */\r\n    function permit(\r\n        address owner,\r\n        address spender,\r\n        uint256 amount,\r\n        uint256 deadline,\r\n        uint8 v,\r\n        bytes32 r,\r\n        bytes32 s\r\n    ) external;\r\n\r\n    /**\r\n     * @dev Returns the current ERC2612 nonce for `owner`. This value must be\r\n     * included whenever a signature is generated for {permit}.\r\n     *\r\n     * Every successful call to {permit} increases ``owner``'s nonce by one. This\r\n     * prevents a signature from being used multiple times.\r\n     */\r\n    function nonces(address owner) external view returns (uint256);\r\n}\r\n"
    },
    "@openzeppelin/contracts/GSN/Context.sol": {
      "content": "// SPDX-License-Identifier: MIT\n\npragma solidity >=0.6.0 <0.8.0;\n\n/*\n * @dev Provides information about the current execution context, including the\n * sender of the transaction and its data. While these are generally available\n * via msg.sender and msg.data, they should not be accessed in such a direct\n * manner, since when dealing with GSN meta-transactions the account sending and\n * paying for execution may not be the actual sender (as far as an application\n * is concerned).\n *\n * This contract is only required for intermediate, library-like contracts.\n */\nabstract contract Context {\n    function _msgSender() internal view virtual returns (address payable) {\n        return msg.sender;\n    }\n\n    function _msgData() internal view virtual returns (bytes memory) {\n        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691\n        return msg.data;\n    }\n}\n"
    },
    "@openzeppelin/contracts/token/ERC20/IERC20.sol": {
      "content": "// SPDX-License-Identifier: MIT\n\npragma solidity >=0.6.0 <0.8.0;\n\n/**\n * @dev Interface of the ERC20 standard as defined in the EIP.\n */\ninterface IERC20 {\n    /**\n     * @dev Returns the amount of tokens in existence.\n     */\n    function totalSupply() external view returns (uint256);\n\n    /**\n     * @dev Returns the amount of tokens owned by `account`.\n     */\n    function balanceOf(address account) external view returns (uint256);\n\n    /**\n     * @dev Moves `amount` tokens from the caller's account to `recipient`.\n     *\n     * Returns a boolean value indicating whether the operation succeeded.\n     *\n     * Emits a {Transfer} event.\n     */\n    function transfer(address recipient, uint256 amount) external returns (bool);\n\n    /**\n     * @dev Returns the remaining number of tokens that `spender` will be\n     * allowed to spend on behalf of `owner` through {transferFrom}. This is\n     * zero by default.\n     *\n     * This value changes when {approve} or {transferFrom} are called.\n     */\n    function allowance(address owner, address spender) external view returns (uint256);\n\n    /**\n     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.\n     *\n     * Returns a boolean value indicating whether the operation succeeded.\n     *\n     * IMPORTANT: Beware that changing an allowance with this method brings the risk\n     * that someone may use both the old and the new allowance by unfortunate\n     * transaction ordering. One possible solution to mitigate this race\n     * condition is to first reduce the spender's allowance to 0 and set the\n     * desired value afterwards:\n     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729\n     *\n     * Emits an {Approval} event.\n     */\n    function approve(address spender, uint256 amount) external returns (bool);\n\n    /**\n     * @dev Moves `amount` tokens from `sender` to `recipient` using the\n     * allowance mechanism. `amount` is then deducted from the caller's\n     * allowance.\n     *\n     * Returns a boolean value indicating whether the operation succeeded.\n     *\n     * Emits a {Transfer} event.\n     */\n    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);\n\n    /**\n     * @dev Emitted when `value` tokens are moved from one account (`from`) to\n     * another (`to`).\n     *\n     * Note that `value` may be zero.\n     */\n    event Transfer(address indexed from, address indexed to, uint256 value);\n\n    /**\n     * @dev Emitted when the allowance of a `spender` for an `owner` is set by\n     * a call to {approve}. `value` is the new allowance.\n     */\n    event Approval(address indexed owner, address indexed spender, uint256 value);\n}\n"
    },
    "@openzeppelin/contracts/math/SafeMath.sol": {
      "content": "// SPDX-License-Identifier: MIT\n\npragma solidity >=0.6.0 <0.8.0;\n\n/**\n * @dev Wrappers over Solidity's arithmetic operations with added overflow\n * checks.\n *\n * Arithmetic operations in Solidity wrap on overflow. This can easily result\n * in bugs, because programmers usually assume that an overflow raises an\n * error, which is the standard behavior in high level programming languages.\n * `SafeMath` restores this intuition by reverting the transaction when an\n * operation overflows.\n *\n * Using this library instead of the unchecked operations eliminates an entire\n * class of bugs, so it's recommended to use it always.\n */\nlibrary SafeMath {\n    /**\n     * @dev Returns the addition of two unsigned integers, reverting on\n     * overflow.\n     *\n     * Counterpart to Solidity's `+` operator.\n     *\n     * Requirements:\n     *\n     * - Addition cannot overflow.\n     */\n    function add(uint256 a, uint256 b) internal pure returns (uint256) {\n        uint256 c = a + b;\n        require(c >= a, \"SafeMath: addition overflow\");\n\n        return c;\n    }\n\n    /**\n     * @dev Returns the subtraction of two unsigned integers, reverting on\n     * overflow (when the result is negative).\n     *\n     * Counterpart to Solidity's `-` operator.\n     *\n     * Requirements:\n     *\n     * - Subtraction cannot overflow.\n     */\n    function sub(uint256 a, uint256 b) internal pure returns (uint256) {\n        return sub(a, b, \"SafeMath: subtraction overflow\");\n    }\n\n    /**\n     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on\n     * overflow (when the result is negative).\n     *\n     * Counterpart to Solidity's `-` operator.\n     *\n     * Requirements:\n     *\n     * - Subtraction cannot overflow.\n     */\n    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {\n        require(b <= a, errorMessage);\n        uint256 c = a - b;\n\n        return c;\n    }\n\n    /**\n     * @dev Returns the multiplication of two unsigned integers, reverting on\n     * overflow.\n     *\n     * Counterpart to Solidity's `*` operator.\n     *\n     * Requirements:\n     *\n     * - Multiplication cannot overflow.\n     */\n    function mul(uint256 a, uint256 b) internal pure returns (uint256) {\n        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the\n        // benefit is lost if 'b' is also tested.\n        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522\n        if (a == 0) {\n            return 0;\n        }\n\n        uint256 c = a * b;\n        require(c / a == b, \"SafeMath: multiplication overflow\");\n\n        return c;\n    }\n\n    /**\n     * @dev Returns the integer division of two unsigned integers. Reverts on\n     * division by zero. The result is rounded towards zero.\n     *\n     * Counterpart to Solidity's `/` operator. Note: this function uses a\n     * `revert` opcode (which leaves remaining gas untouched) while Solidity\n     * uses an invalid opcode to revert (consuming all remaining gas).\n     *\n     * Requirements:\n     *\n     * - The divisor cannot be zero.\n     */\n    function div(uint256 a, uint256 b) internal pure returns (uint256) {\n        return div(a, b, \"SafeMath: division by zero\");\n    }\n\n    /**\n     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on\n     * division by zero. The result is rounded towards zero.\n     *\n     * Counterpart to Solidity's `/` operator. Note: this function uses a\n     * `revert` opcode (which leaves remaining gas untouched) while Solidity\n     * uses an invalid opcode to revert (consuming all remaining gas).\n     *\n     * Requirements:\n     *\n     * - The divisor cannot be zero.\n     */\n    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {\n        require(b > 0, errorMessage);\n        uint256 c = a / b;\n        // assert(a == b * c + a % b); // There is no case in which this doesn't hold\n\n        return c;\n    }\n\n    /**\n     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),\n     * Reverts when dividing by zero.\n     *\n     * Counterpart to Solidity's `%` operator. This function uses a `revert`\n     * opcode (which leaves remaining gas untouched) while Solidity uses an\n     * invalid opcode to revert (consuming all remaining gas).\n     *\n     * Requirements:\n     *\n     * - The divisor cannot be zero.\n     */\n    function mod(uint256 a, uint256 b) internal pure returns (uint256) {\n        return mod(a, b, \"SafeMath: modulo by zero\");\n    }\n\n    /**\n     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),\n     * Reverts with custom message when dividing by zero.\n     *\n     * Counterpart to Solidity's `%` operator. This function uses a `revert`\n     * opcode (which leaves remaining gas untouched) while Solidity uses an\n     * invalid opcode to revert (consuming all remaining gas).\n     *\n     * Requirements:\n     *\n     * - The divisor cannot be zero.\n     */\n    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {\n        require(b != 0, errorMessage);\n        return a % b;\n    }\n}\n"
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
          "abi"
        ]
      }
    },
    "libraries": {}
  }
}}