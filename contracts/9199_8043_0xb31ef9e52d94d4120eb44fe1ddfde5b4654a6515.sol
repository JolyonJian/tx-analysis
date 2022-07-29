{{
  "language": "Solidity",
  "sources": {
    "contracts/token/ERC20/DOSE.sol": {
      "content": "// SPDX-License-Identifier: MIT\n\npragma solidity >=0.7.6 <0.8.0;\n\nimport \"@animoca/ethereum-contracts-assets/contracts/token/ERC20/ERC20.sol\";\n\n/**\n * @title DOSE\n */\ncontract DOSE is ERC20 {\n    constructor(\n        address[] memory recipients,\n        uint256[] memory values,\n        string memory tokenURI_\n    ) ERC20(\"DOSE\", \"DOSE\", 18, tokenURI_) {\n        _batchMint(recipients, values);\n    }\n}\n"
    },
    "@animoca/ethereum-contracts-assets/contracts/token/ERC20/ERC20.sol": {
      "content": "// SPDX-License-Identifier: MIT\n\npragma solidity >=0.7.6 <0.8.0;\n\nimport {ManagedIdentity} from \"@animoca/ethereum-contracts-core-1.1.1/contracts/metatx/ManagedIdentity.sol\";\nimport {IERC165} from \"@animoca/ethereum-contracts-core-1.1.1/contracts/introspection/IERC165.sol\";\nimport {AddressIsContract} from \"@animoca/ethereum-contracts-core-1.1.1/contracts/utils/types/AddressIsContract.sol\";\nimport {IERC20} from \"./IERC20.sol\";\nimport {IERC20Detailed} from \"./IERC20Detailed.sol\";\nimport {IERC20Allowance} from \"./IERC20Allowance.sol\";\nimport {IERC20SafeTransfers} from \"./IERC20SafeTransfers.sol\";\nimport {IERC20BatchTransfers} from \"./IERC20BatchTransfers.sol\";\nimport {IERC20Metadata} from \"./IERC20Metadata.sol\";\nimport {IERC20Permit} from \"./IERC20Permit.sol\";\nimport {IERC20Receiver} from \"./IERC20Receiver.sol\";\n\n/**\n * @title ERC20 Fungible Token Contract.\n */\nabstract contract ERC20 is\n    ManagedIdentity,\n    IERC165,\n    IERC20,\n    IERC20Detailed,\n    IERC20Metadata,\n    IERC20Allowance,\n    IERC20BatchTransfers,\n    IERC20SafeTransfers,\n    IERC20Permit\n{\n    using AddressIsContract for address;\n\n    // keccak256(\"Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)\")\n    bytes32 internal constant PERMIT_TYPEHASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;\n\n    uint256 public immutable deploymentChainId;\n\n    // solhint-disable-next-line var-name-mixedcase\n    bytes32 internal immutable _DOMAIN_SEPARATOR;\n\n    mapping(address => uint256) public override nonces;\n\n    string internal _name;\n    string internal _symbol;\n    uint8 internal immutable _decimals;\n    string internal _tokenURI;\n\n    mapping(address => uint256) internal _balances;\n    mapping(address => mapping(address => uint256)) internal _allowances;\n    uint256 internal _totalSupply;\n\n    constructor(\n        string memory name_,\n        string memory symbol_,\n        uint8 decimals_,\n        string memory tokenURI_\n    ) {\n        _name = name_;\n        _symbol = symbol_;\n        _decimals = decimals_;\n        _tokenURI = tokenURI_;\n\n        uint256 chainId;\n        assembly {\n            chainId := chainid()\n        }\n        deploymentChainId = chainId;\n        _DOMAIN_SEPARATOR = _calculateDomainSeparator(chainId, bytes(name_));\n    }\n\n    // solhint-disable-next-line func-name-mixedcase\n    function DOMAIN_SEPARATOR() public view override returns (bytes32) {\n        uint256 chainId;\n        assembly {\n            chainId := chainid()\n        }\n        // recompute the domain separator in case of fork and chainid update\n        return chainId == deploymentChainId ? _DOMAIN_SEPARATOR : _calculateDomainSeparator(chainId, bytes(_name));\n    }\n\n    function _calculateDomainSeparator(uint256 chainId, bytes memory name_) private view returns (bytes32) {\n        return\n            keccak256(\n                abi.encode(\n                    keccak256(\"EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)\"),\n                    keccak256(name_),\n                    keccak256(\"1\"),\n                    chainId,\n                    address(this)\n                )\n            );\n    }\n\n    /////////////////////////////////////////// ERC165 ///////////////////////////////////////\n\n    /// @dev See {IERC165-supportsInterface}.\n    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {\n        return\n            interfaceId == type(IERC165).interfaceId ||\n            interfaceId == type(IERC20).interfaceId ||\n            interfaceId == type(IERC20Detailed).interfaceId ||\n            interfaceId == type(IERC20Metadata).interfaceId ||\n            interfaceId == type(IERC20Allowance).interfaceId ||\n            interfaceId == type(IERC20BatchTransfers).interfaceId ||\n            interfaceId == type(IERC20SafeTransfers).interfaceId ||\n            interfaceId == type(IERC20Permit).interfaceId;\n    }\n\n    /////////////////////////////////////////// ERC20Detailed ///////////////////////////////////////\n\n    /// @dev See {IERC20Detailed-name}.\n    function name() external view override returns (string memory) {\n        return _name;\n    }\n\n    /// @dev See {IERC20Detailed-symbol}.\n    function symbol() external view override returns (string memory) {\n        return _symbol;\n    }\n\n    /// @dev See {IERC20Detailed-decimals}.\n    function decimals() external view override returns (uint8) {\n        return _decimals;\n    }\n\n    /////////////////////////////////////////// ERC20Metadata ///////////////////////////////////////\n\n    /// @dev See {IERC20Metadata-tokenURI}.\n    function tokenURI() external view override returns (string memory) {\n        return _tokenURI;\n    }\n\n    /////////////////////////////////////////// ERC20 ///////////////////////////////////////\n\n    /// @dev See {IERC20-totalSupply}.\n    function totalSupply() external view override returns (uint256) {\n        return _totalSupply;\n    }\n\n    /// @dev See {IERC20-balanceOf}.\n    function balanceOf(address account) external view override returns (uint256) {\n        return _balances[account];\n    }\n\n    /// @dev See {IERC20-allowance}.\n    function allowance(address owner, address spender) public view virtual override returns (uint256) {\n        return _allowances[owner][spender];\n    }\n\n    /// @dev See {IERC20-approve}.\n    function approve(address spender, uint256 value) external virtual override returns (bool) {\n        _approve(_msgSender(), spender, value);\n        return true;\n    }\n\n    /////////////////////////////////////////// ERC20 Allowance ///////////////////////////////////////\n\n    /// @dev See {IERC20Allowance-increaseAllowance}.\n    function increaseAllowance(address spender, uint256 addedValue) external virtual override returns (bool) {\n        require(spender != address(0), \"ERC20: zero address spender\");\n        address owner = _msgSender();\n        uint256 allowance_ = _allowances[owner][spender];\n        if (addedValue != 0) {\n            uint256 newAllowance = allowance_ + addedValue;\n            require(newAllowance > allowance_, \"ERC20: allowance overflow\");\n            _allowances[owner][spender] = newAllowance;\n            allowance_ = newAllowance;\n        }\n        emit Approval(owner, spender, allowance_);\n\n        return true;\n    }\n\n    /// @dev See {IERC20Allowance-decreaseAllowance}.\n    function decreaseAllowance(address spender, uint256 subtractedValue) external virtual override returns (bool) {\n        require(spender != address(0), \"ERC20: zero address spender\");\n        _decreaseAllowance(_msgSender(), spender, subtractedValue);\n        return true;\n    }\n\n    /// @dev See {IERC20-transfer}.\n    function transfer(address to, uint256 value) external virtual override returns (bool) {\n        _transfer(_msgSender(), to, value);\n        return true;\n    }\n\n    /// @dev See {IERC20-transferFrom}.\n    function transferFrom(\n        address from,\n        address to,\n        uint256 value\n    ) external virtual override returns (bool) {\n        _transferFrom(_msgSender(), from, to, value);\n        return true;\n    }\n\n    /////////////////////////////////////////// ERC20MultiTransfer ///////////////////////////////////////\n\n    /// @dev See {IERC20MultiTransfer-multiTransfer(address[],uint256[])}.\n    function batchTransfer(address[] calldata recipients, uint256[] calldata values) external virtual override returns (bool) {\n        uint256 length = recipients.length;\n        require(length == values.length, \"ERC20: inconsistent arrays\");\n        address sender = _msgSender();\n        uint256 balance = _balances[sender];\n\n        uint256 totalValue;\n        uint256 selfTransferTotalValue;\n        for (uint256 i; i != length; ++i) {\n            address to = recipients[i];\n            require(to != address(0), \"ERC20: to zero address\");\n\n            uint256 value = values[i];\n            if (value != 0) {\n                uint256 newTotalValue = totalValue + value;\n                require(newTotalValue > totalValue, \"ERC20: values overflow\");\n                totalValue = newTotalValue;\n                if (sender != to) {\n                    _balances[to] += value;\n                } else {\n                    require(value <= balance, \"ERC20: insufficient balance\");\n                    selfTransferTotalValue += value; // cannot overflow as 'selfTransferTotalValue <= totalValue' is always true\n                }\n            }\n            emit Transfer(sender, to, value);\n        }\n\n        if (totalValue != 0 && totalValue != selfTransferTotalValue) {\n            uint256 newBalance = balance - totalValue;\n            require(newBalance < balance, \"ERC20: insufficient balance\"); // balance must be sufficient, including self-transfers\n            _balances[sender] = newBalance + selfTransferTotalValue; // do not deduct self-transfers from the sender balance\n        }\n        return true;\n    }\n\n    /// @dev See {IERC20MultiTransfer-multiTransferFrom(address,address[],uint256[])}.\n    function batchTransferFrom(\n        address from,\n        address[] calldata recipients,\n        uint256[] calldata values\n    ) external virtual override returns (bool) {\n        uint256 length = recipients.length;\n        require(length == values.length, \"ERC20: inconsistent arrays\");\n\n        uint256 balance = _balances[from];\n\n        uint256 totalValue;\n        uint256 selfTransferTotalValue;\n        for (uint256 i; i != length; ++i) {\n            address to = recipients[i];\n            require(to != address(0), \"ERC20: to zero address\");\n\n            uint256 value = values[i];\n\n            if (value != 0) {\n                uint256 newTotalValue = totalValue + value;\n                require(newTotalValue > totalValue, \"ERC20: values overflow\");\n                totalValue = newTotalValue;\n                if (from != to) {\n                    _balances[to] += value;\n                } else {\n                    require(value <= balance, \"ERC20: insufficient balance\");\n                    selfTransferTotalValue += value; // cannot overflow as 'selfTransferTotalValue <= totalValue' is always true\n                }\n            }\n\n            emit Transfer(from, to, value);\n        }\n\n        if (totalValue != 0 && totalValue != selfTransferTotalValue) {\n            uint256 newBalance = balance - totalValue;\n            require(newBalance < balance, \"ERC20: insufficient balance\"); // balance must be sufficient, including self-transfers\n            _balances[from] = newBalance + selfTransferTotalValue; // do not deduct self-transfers from the sender balance\n        }\n\n        address sender = _msgSender();\n        if (from != sender) {\n            _decreaseAllowance(from, sender, totalValue);\n        }\n\n        return true;\n    }\n\n    /////////////////////////////////////////// ERC20SafeTransfers ///////////////////////////////////////\n\n    /// @dev See {IERC20Safe-safeTransfer(address,uint256,bytes)}.\n    function safeTransfer(\n        address to,\n        uint256 amount,\n        bytes calldata data\n    ) external virtual override returns (bool) {\n        address sender = _msgSender();\n        _transfer(sender, to, amount);\n        if (to.isContract()) {\n            require(IERC20Receiver(to).onERC20Received(sender, sender, amount, data) == type(IERC20Receiver).interfaceId, \"ERC20: transfer refused\");\n        }\n        return true;\n    }\n\n    /// @dev See {IERC20Safe-safeTransferFrom(address,address,uint256,bytes)}.\n    function safeTransferFrom(\n        address from,\n        address to,\n        uint256 amount,\n        bytes calldata data\n    ) external virtual override returns (bool) {\n        address sender = _msgSender();\n        _transferFrom(sender, from, to, amount);\n        if (to.isContract()) {\n            require(IERC20Receiver(to).onERC20Received(sender, from, amount, data) == type(IERC20Receiver).interfaceId, \"ERC20: transfer refused\");\n        }\n        return true;\n    }\n\n    /////////////////////////////////////////// ERC20Permit ///////////////////////////////////////\n\n    /// @dev See {IERC2612-permit(address,address,uint256,uint256,uint8,bytes32,bytes32)}.\n    function permit(\n        address owner,\n        address spender,\n        uint256 value,\n        uint256 deadline,\n        uint8 v,\n        bytes32 r,\n        bytes32 s\n    ) external virtual override {\n        require(owner != address(0), \"ERC20: zero address owner\");\n        require(block.timestamp <= deadline, \"ERC20: expired permit\");\n        bytes32 hashStruct = keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline));\n        bytes32 hash = keccak256(abi.encodePacked(\"\\x19\\x01\", DOMAIN_SEPARATOR(), hashStruct));\n        address signer = ecrecover(hash, v, r, s);\n        require(signer == owner, \"ERC20: invalid permit\");\n        _approve(owner, spender, value);\n    }\n\n    /////////////////////////////////////////// Internal Functions ///////////////////////////////////////\n\n    function _approve(\n        address owner,\n        address spender,\n        uint256 value\n    ) internal {\n        require(spender != address(0), \"ERC20: zero address spender\");\n        _allowances[owner][spender] = value;\n        emit Approval(owner, spender, value);\n    }\n\n    function _decreaseAllowance(\n        address owner,\n        address spender,\n        uint256 subtractedValue\n    ) internal {\n        uint256 allowance_ = _allowances[owner][spender];\n\n        if (allowance_ != type(uint256).max && subtractedValue != 0) {\n            // save gas when allowance is maximal by not reducing it (see https://github.com/ethereum/EIPs/issues/717)\n            uint256 newAllowance = allowance_ - subtractedValue;\n            require(newAllowance < allowance_, \"ERC20: insufficient allowance\");\n            _allowances[owner][spender] = newAllowance;\n            allowance_ = newAllowance;\n        }\n        emit Approval(owner, spender, allowance_);\n    }\n\n    function _transfer(\n        address from,\n        address to,\n        uint256 value\n    ) internal virtual {\n        require(to != address(0), \"ERC20: to zero address\");\n\n        if (value != 0) {\n            uint256 balance = _balances[from];\n            uint256 newBalance = balance - value;\n            require(newBalance < balance, \"ERC20: insufficient balance\");\n            if (from != to) {\n                _balances[from] = newBalance;\n                _balances[to] += value;\n            }\n        }\n\n        emit Transfer(from, to, value);\n    }\n\n    function _transferFrom(\n        address sender,\n        address from,\n        address to,\n        uint256 value\n    ) internal {\n        _transfer(from, to, value);\n        if (from != sender) {\n            _decreaseAllowance(from, sender, value);\n        }\n    }\n\n    function _mint(address to, uint256 value) internal virtual {\n        require(to != address(0), \"ERC20: zero address\");\n        uint256 supply = _totalSupply;\n        if (value != 0) {\n            uint256 newSupply = supply + value;\n            require(newSupply > supply, \"ERC20: supply overflow\");\n            _totalSupply = newSupply;\n            _balances[to] += value; // balance cannot overflow if supply does not\n        }\n        emit Transfer(address(0), to, value);\n    }\n\n    function _batchMint(address[] memory recipients, uint256[] memory values) internal virtual {\n        uint256 length = recipients.length;\n        require(length == values.length, \"ERC20: inconsistent arrays\");\n\n        uint256 totalValue;\n        for (uint256 i; i != length; ++i) {\n            address to = recipients[i];\n            require(to != address(0), \"ERC20: zero address\");\n\n            uint256 value = values[i];\n            if (value != 0) {\n                uint256 newTotalValue = totalValue + value;\n                require(newTotalValue > totalValue, \"ERC20: values overflow\");\n                totalValue = newTotalValue;\n                _balances[to] += value; // balance cannot overflow if supply does not\n            }\n            emit Transfer(address(0), to, value);\n        }\n\n        if (totalValue != 0) {\n            uint256 supply = _totalSupply;\n            uint256 newSupply = supply + totalValue;\n            require(newSupply > supply, \"ERC20: supply overflow\");\n            _totalSupply = newSupply;\n        }\n    }\n\n    function _burn(address from, uint256 value) internal virtual {\n        if (value != 0) {\n            uint256 balance = _balances[from];\n            uint256 newBalance = balance - value;\n            require(newBalance < balance, \"ERC20: insufficient balance\");\n            _balances[from] = newBalance;\n            _totalSupply -= value; // will not underflow if balance does not\n        }\n        emit Transfer(from, address(0), value);\n    }\n\n    function _burnFrom(address from, uint256 value) internal virtual {\n        _burn(from, value);\n        address sender = _msgSender();\n        if (from != sender) {\n            _decreaseAllowance(from, sender, value);\n        }\n    }\n\n    function _batchBurnFrom(address[] memory owners, uint256[] memory values) internal virtual {\n        uint256 length = owners.length;\n        require(length == values.length, \"ERC20: inconsistent arrays\");\n\n        address sender = _msgSender();\n\n        uint256 totalValue;\n        for (uint256 i; i != length; ++i) {\n            address from = owners[i];\n            uint256 value = values[i];\n            if (value != 0) {\n                uint256 balance = _balances[from];\n                uint256 newBalance = balance - value;\n                require(newBalance < balance, \"ERC20: insufficient balance\");\n                _balances[from] = newBalance;\n                totalValue += value; // totalValue cannot overflow if the individual balances do not underflow\n            }\n            emit Transfer(from, address(0), value);\n\n            if (from != sender) {\n                _decreaseAllowance(from, sender, value);\n            }\n        }\n\n        if (totalValue != 0) {\n            _totalSupply -= totalValue; // _totalSupply cannot underfow as balances do not underflow\n        }\n    }\n}\n"
    },
    "@animoca/ethereum-contracts-core-1.1.1/contracts/metatx/ManagedIdentity.sol": {
      "content": "// SPDX-License-Identifier: MIT\n\npragma solidity >=0.7.6 <0.8.0;\n\n/*\n * Provides information about the current execution context, including the\n * sender of the transaction and its data. While these are generally available\n * via msg.sender and msg.data, they should not be accessed in such a direct\n * manner.\n */\nabstract contract ManagedIdentity {\n    function _msgSender() internal view virtual returns (address payable) {\n        return msg.sender;\n    }\n\n    function _msgData() internal view virtual returns (bytes memory) {\n        return msg.data;\n    }\n}\n"
    },
    "@animoca/ethereum-contracts-core-1.1.1/contracts/introspection/IERC165.sol": {
      "content": "// SPDX-License-Identifier: MIT\n\npragma solidity >=0.7.6 <0.8.0;\n\n/**\n * @dev Interface of the ERC165 standard, as defined in the\n * https://eips.ethereum.org/EIPS/eip-165.\n */\ninterface IERC165 {\n    /**\n     * @dev Returns true if this contract implements the interface defined by\n     * `interfaceId`. See the corresponding\n     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]\n     * to learn more about how these ids are created.\n     *\n     * This function call must use less than 30 000 gas.\n     */\n    function supportsInterface(bytes4 interfaceId) external view returns (bool);\n}\n"
    },
    "@animoca/ethereum-contracts-core-1.1.1/contracts/utils/types/AddressIsContract.sol": {
      "content": "// SPDX-License-Identifier: MIT\n\n// Partially derived from OpenZeppelin:\n// https://github.com/OpenZeppelin/openzeppelin-contracts/blob/406c83649bd6169fc1b578e08506d78f0873b276/contracts/utils/Address.sol\n\npragma solidity >=0.7.6 <0.8.0;\n\n/**\n * @dev Upgrades the address type to check if it is a contract.\n */\nlibrary AddressIsContract {\n    /**\n     * @dev Returns true if `account` is a contract.\n     *\n     * [IMPORTANT]\n     * ====\n     * It is unsafe to assume that an address for which this function returns\n     * false is an externally-owned account (EOA) and not a contract.\n     *\n     * Among others, `isContract` will return false for the following\n     * types of addresses:\n     *\n     *  - an externally-owned account\n     *  - a contract in construction\n     *  - an address where a contract will be created\n     *  - an address where a contract lived, but was destroyed\n     * ====\n     */\n    function isContract(address account) internal view returns (bool) {\n        // This method relies on extcodesize, which returns 0 for contracts in\n        // construction, since the code is only stored at the end of the\n        // constructor execution.\n\n        uint256 size;\n        assembly {\n            size := extcodesize(account)\n        }\n        return size > 0;\n    }\n}\n"
    },
    "@animoca/ethereum-contracts-assets/contracts/token/ERC20/IERC20.sol": {
      "content": "// SPDX-License-Identifier: MIT\n\npragma solidity >=0.7.6 <0.8.0;\n\n/**\n * @title ERC20 Token Standard, basic interface\n * @dev See https://eips.ethereum.org/EIPS/eip-20\n * Note: The ERC-165 identifier for this interface is 0x36372b07.\n */\ninterface IERC20 {\n    /**\n     * @dev Emitted when tokens are transferred, including zero value transfers.\n     * @param _from The account where the transferred tokens are withdrawn from.\n     * @param _to The account where the transferred tokens are deposited to.\n     * @param _value The amount of tokens being transferred.\n     */\n    event Transfer(address indexed _from, address indexed _to, uint256 _value);\n\n    /**\n     * @dev Emitted when a successful call to {IERC20-approve(address,uint256)} is made.\n     * @param _owner The account granting an allowance to `_spender`.\n     * @param _spender The account being granted an allowance from `_owner`.\n     * @param _value The allowance amount being granted.\n     */\n    event Approval(address indexed _owner, address indexed _spender, uint256 _value);\n\n    /**\n     * @notice Returns the total token supply.\n     * @return The total token supply.\n     */\n    function totalSupply() external view returns (uint256);\n\n    /**\n     * @notice Returns the account balance of another account with address `owner`.\n     * @param owner The account whose balance will be returned.\n     * @return The account balance of another account with address `owner`.\n     */\n    function balanceOf(address owner) external view returns (uint256);\n\n    /**\n     * Transfers `value` amount of tokens to address `to`.\n     * @dev Reverts if `to` is the zero address.\n     * @dev Reverts if the sender does not have enough balance.\n     * @dev Emits an {IERC20-Transfer} event.\n     * @dev Transfers of 0 values are treated as normal transfers and fire the {IERC20-Transfer} event.\n     * @param to The receiver account.\n     * @param value The amount of tokens to transfer.\n     * @return True if the transfer succeeds, false otherwise.\n     */\n    function transfer(address to, uint256 value) external returns (bool);\n\n    /**\n     * @notice Transfers `value` amount of tokens from address `from` to address `to` via the approval mechanism.\n     * @dev Reverts if `to` is the zero address.\n     * @dev Reverts if the sender is not `from` and has not been approved by `from` for at least `value`.\n     * @dev Reverts if `from` does not have at least `value` of balance.\n     * @dev Emits an {IERC20-Transfer} event.\n     * @dev Transfers of 0 values are treated as normal transfers and fire the {IERC20-Transfer} event.\n     * @param from The emitter account.\n     * @param to The receiver account.\n     * @param value The amount of tokens to transfer.\n     * @return True if the transfer succeeds, false otherwise.\n     */\n    function transferFrom(\n        address from,\n        address to,\n        uint256 value\n    ) external returns (bool);\n\n    /**\n     * Sets `value` as the allowance from the caller to `spender`.\n     *  IMPORTANT: Beware that changing an allowance with this method brings the risk\n     *  that someone may use both the old and the new allowance by unfortunate\n     *  transaction ordering. One possible solution to mitigate this race\n     *  condition is to first reduce the spender's allowance to 0 and set the\n     *  desired value afterwards: https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729\n     * @dev Reverts if `spender` is the zero address.\n     * @dev Emits the {IERC20-Approval} event.\n     * @param spender The account being granted the allowance by the message caller.\n     * @param value The allowance amount to grant.\n     * @return True if the approval succeeds, false otherwise.\n     */\n    function approve(address spender, uint256 value) external returns (bool);\n\n    /**\n     * Returns the amount which `spender` is allowed to spend on behalf of `owner`.\n     * @param owner The account that has granted an allowance to `spender`.\n     * @param spender The account that was granted an allowance by `owner`.\n     * @return The amount which `spender` is allowed to spend on behalf of `owner`.\n     */\n    function allowance(address owner, address spender) external view returns (uint256);\n}\n"
    },
    "@animoca/ethereum-contracts-assets/contracts/token/ERC20/IERC20Detailed.sol": {
      "content": "// SPDX-License-Identifier: MIT\n\npragma solidity >=0.7.6 <0.8.0;\n\n/**\n * @title ERC20 Token Standard, optional extension: Detailed\n * See https://eips.ethereum.org/EIPS/eip-20\n * Note: the ERC-165 identifier for this interface is 0xa219a025.\n */\ninterface IERC20Detailed {\n    /**\n     * Returns the name of the token. E.g. \"My Token\".\n     * @return The name of the token.\n     */\n    function name() external view returns (string memory);\n\n    /**\n     * Returns the symbol of the token. E.g. \"HIX\".\n     * @return The symbol of the token.\n     */\n    function symbol() external view returns (string memory);\n\n    /**\n     * Returns the number of decimals used to display the balances.\n     * For example, if `decimals` equals `2`, a balance of `505` tokens should\n     * be displayed to a user as `5,05` (`505 / 10 ** 2`).\n     *\n     * Tokens usually opt for a value of 18, imitating the relationship between Ether and Wei.\n     *\n     * NOTE: This information is only used for _display_ purposes: it does  not impact the arithmetic of the contract.\n     * @return The number of decimals used to display the balances.\n     */\n    function decimals() external view returns (uint8);\n}\n"
    },
    "@animoca/ethereum-contracts-assets/contracts/token/ERC20/IERC20Allowance.sol": {
      "content": "// SPDX-License-Identifier: MIT\n\npragma solidity >=0.7.6 <0.8.0;\n\n/**\n * @title ERC20 Token Standard, optional extension: Allowance\n * See https://eips.ethereum.org/EIPS/eip-20\n * Note: the ERC-165 identifier for this interface is 0xd5b86388.\n */\ninterface IERC20Allowance {\n    /**\n     * Increases the allowance granted by the sender to `spender` by `value`.\n     *  This is an alternative to {approve} that can be used as a mitigation for\n     *  problems described in {IERC20-approve}.\n     * @dev Reverts if `spender` is the zero address.\n     * @dev Reverts if `spender`'s allowance overflows.\n     * @dev Emits an {IERC20-Approval} event with an updated allowance for `spender`.\n     * @param spender The account whose allowance is being increased by the message caller.\n     * @param value The allowance amount increase.\n     * @return True if the allowance increase succeeds, false otherwise.\n     */\n    function increaseAllowance(address spender, uint256 value) external returns (bool);\n\n    /**\n     * Decreases the allowance granted by the sender to `spender` by `value`.\n     *  This is an alternative to {approve} that can be used as a mitigation for\n     *  problems described in {IERC20-approve}.\n     * @dev Reverts if `spender` is the zero address.\n     * @dev Reverts if `spender` has an allowance with the message caller for less than `value`.\n     * @dev Emits an {IERC20-Approval} event with an updated allowance for `spender`.\n     * @param spender The account whose allowance is being decreased by the message caller.\n     * @param value The allowance amount decrease.\n     * @return True if the allowance decrease succeeds, false otherwise.\n     */\n    function decreaseAllowance(address spender, uint256 value) external returns (bool);\n}\n"
    },
    "@animoca/ethereum-contracts-assets/contracts/token/ERC20/IERC20SafeTransfers.sol": {
      "content": "// SPDX-License-Identifier: MIT\n\npragma solidity >=0.7.6 <0.8.0;\n\n/**\n * @title ERC20 Token Standard, optional extension: Safe Transfers\n * Note: the ERC-165 identifier for this interface is 0x53f41a97.\n */\ninterface IERC20SafeTransfers {\n    /**\n     * Transfers tokens from the caller to `to`. If this address is a contract, then calls `onERC20Received(address,address,uint256,bytes)` on it.\n     * @dev Reverts if `to` is the zero address.\n     * @dev Reverts if `value` is greater than the sender's balance.\n     * @dev Reverts if `to` is a contract which does not implement `onERC20Received(address,address,uint256,bytes)`.\n     * @dev Reverts if `to` is a contract and the call to `onERC20Received(address,address,uint256,bytes)` returns a wrong value.\n     * @dev Emits an {IERC20-Transfer} event.\n     * @param to The address for the tokens to be transferred to.\n     * @param amount The amount of tokens to be transferred.\n     * @param data Optional additional data with no specified format, to be passed to the receiver contract.\n     * @return true.\n     */\n    function safeTransfer(\n        address to,\n        uint256 amount,\n        bytes calldata data\n    ) external returns (bool);\n\n    /**\n     * Transfers tokens from `from` to another address, using the allowance mechanism.\n     *  If this address is a contract, then calls `onERC20Received(address,address,uint256,bytes)` on it.\n     * @dev Reverts if `to` is the zero address.\n     * @dev Reverts if `value` is greater than `from`'s balance.\n     * @dev Reverts if the sender does not have at least `value` allowance by `from`.\n     * @dev Reverts if `to` is a contract which does not implement `onERC20Received(address,address,uint256,bytes)`.\n     * @dev Reverts if `to` is a contract and the call to `onERC20Received(address,address,uint256,bytes)` returns a wrong value.\n     * @dev Emits an {IERC20-Transfer} event.\n     * @param from The address which owns the tokens to be transferred.\n     * @param to The address for the tokens to be transferred to.\n     * @param amount The amount of tokens to be transferred.\n     * @param data Optional additional data with no specified format, to be passed to the receiver contract.\n     * @return true.\n     */\n    function safeTransferFrom(\n        address from,\n        address to,\n        uint256 amount,\n        bytes calldata data\n    ) external returns (bool);\n}\n"
    },
    "@animoca/ethereum-contracts-assets/contracts/token/ERC20/IERC20BatchTransfers.sol": {
      "content": "// SPDX-License-Identifier: MIT\n\npragma solidity >=0.7.6 <0.8.0;\n\n/**\n * @title ERC20 Token Standard, optional extension: Multi Transfers\n * Note: the ERC-165 identifier for this interface is 0xd5b86388.\n */\ninterface IERC20BatchTransfers {\n    /**\n     * Moves multiple `amounts` tokens from the caller's account to each of `recipients`.\n     * @dev Reverts if `recipients` and `amounts` have different lengths.\n     * @dev Reverts if one of `recipients` is the zero address.\n     * @dev Reverts if the caller has an insufficient balance.\n     * @dev Emits an {IERC20-Transfer} event for each individual transfer.\n     * @param recipients the list of recipients to transfer the tokens to.\n     * @param amounts the amounts of tokens to transfer to each of `recipients`.\n     * @return a boolean value indicating whether the operation succeeded.\n     */\n    function batchTransfer(address[] calldata recipients, uint256[] calldata amounts) external returns (bool);\n\n    /**\n     * Moves multiple `amounts` tokens from an account to each of `recipients`, using the approval mechanism.\n     * @dev Reverts if `recipients` and `amounts` have different lengths.\n     * @dev Reverts if one of `recipients` is the zero address.\n     * @dev Reverts if `from` has an insufficient balance.\n     * @dev Reverts if the sender does not have at least the sum of all `amounts` as allowance by `from`.\n     * @dev Emits an {IERC20-Transfer} event for each individual transfer.\n     * @dev Emits an {IERC20-Approval} event.\n     * @param from The address which owns the tokens to be transferred.\n     * @param recipients the list of recipients to transfer the tokens to.\n     * @param amounts the amounts of tokens to transfer to each of `recipients`.\n     * @return a boolean value indicating whether the operation succeeded.\n     */\n    function batchTransferFrom(\n        address from,\n        address[] calldata recipients,\n        uint256[] calldata amounts\n    ) external returns (bool);\n}\n"
    },
    "@animoca/ethereum-contracts-assets/contracts/token/ERC20/IERC20Metadata.sol": {
      "content": "// SPDX-License-Identifier: MIT\n\npragma solidity >=0.7.6 <0.8.0;\n\n/**\n * @title ERC20 Token Standard, ERC1046 optional extension: Metadata\n * See https://eips.ethereum.org/EIPS/eip-1046\n * Note: the ERC-165 identifier for this interface is 0x3c130d90.\n */\ninterface IERC20Metadata {\n    /**\n     * Returns a distinct Uniform Resource Identifier (URI) for the token metadata.\n     * @return a distinct Uniform Resource Identifier (URI) for the token metadata.\n     */\n    function tokenURI() external view returns (string memory);\n}\n"
    },
    "@animoca/ethereum-contracts-assets/contracts/token/ERC20/IERC20Permit.sol": {
      "content": "// SPDX-License-Identifier: MIT\n\npragma solidity >=0.7.6 <0.8.0;\n\n/**\n * @title ERC20 Token Standard, ERC2612 optional extension: permit – 712-signed approvals\n * @dev Interface for allowing ERC20 approvals to be made via ECDSA `secp256k1` signatures.\n * See https://eips.ethereum.org/EIPS/eip-2612\n * Note: the ERC-165 identifier for this interface is 0x9d8ff7da.\n */\ninterface IERC20Permit {\n    /**\n     * Sets `value` as the allowance of `spender` over the tokens of `owner`, given `owner` account's signed permit.\n     * @dev WARNING: The standard ERC-20 race condition for approvals applies to `permit()` as well: https://swcregistry.io/docs/SWC-114\n     * @dev Reverts if `owner` is the zero address.\n     * @dev Reverts if the current blocktime is > `deadline`.\n     * @dev Reverts if `r`, `s`, and `v` is not a valid `secp256k1` signature from `owner`.\n     * @dev Emits an {IERC20-Approval} event.\n     * @param owner The token owner granting the allowance to `spender`.\n     * @param spender The token spender being granted the allowance by `owner`.\n     * @param value The token amount of the allowance.\n     * @param deadline The deadline from which the permit signature is no longer valid.\n     * @param v Permit signature v parameter\n     * @param r Permit signature r parameter.\n     * @param s Permis signature s parameter.\n     */\n    function permit(\n        address owner,\n        address spender,\n        uint256 value,\n        uint256 deadline,\n        uint8 v,\n        bytes32 r,\n        bytes32 s\n    ) external;\n\n    /**\n     * Returns the current permit nonce of `owner`.\n     * @param owner the address to check the nonce of.\n     * @return the current permit nonce of `owner`.\n     */\n    function nonces(address owner) external view returns (uint256);\n\n    /**\n     * Returns the EIP-712 encoded hash struct of the domain-specific information for permits.\n     *\n     * @dev A common ERC-20 permit implementation choice for the `DOMAIN_SEPARATOR` is:\n     *\n     *  keccak256(\n     *      abi.encode(\n     *          keccak256(\"EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)\"),\n     *          keccak256(bytes(name)),\n     *          keccak256(bytes(version)),\n     *          chainId,\n     *          address(this)))\n     *\n     *  where\n     *   - `name` (string) is the ERC-20 token name.\n     *   - `version` (string) refers to the ERC-20 token contract version.\n     *   - `chainId` (uint256) is the chain ID to which the ERC-20 token contract is deployed to.\n     *   - `verifyingContract` (address) is the ERC-20 token contract address.\n     *\n     * @return the EIP-712 encoded hash struct of the domain-specific information for permits.\n     */\n    // solhint-disable-next-line func-name-mixedcase\n    function DOMAIN_SEPARATOR() external view returns (bytes32);\n}\n"
    },
    "@animoca/ethereum-contracts-assets/contracts/token/ERC20/IERC20Receiver.sol": {
      "content": "// SPDX-License-Identifier: MIT\n\npragma solidity >=0.7.6 <0.8.0;\n\n/**\n * @title ERC20 Token Standard, Receiver\n * See https://eips.ethereum.org/EIPS/eip-20\n * Note: the ERC-165 identifier for this interface is 0x4fc35859.\n */\ninterface IERC20Receiver {\n    /**\n     * Handles the receipt of ERC20 tokens.\n     * @param sender The initiator of the transfer.\n     * @param from The address which transferred the tokens.\n     * @param value The amount of tokens transferred.\n     * @param data Optional additional data with no specified format.\n     * @return bytes4 `bytes4(keccak256(\"onERC20Received(address,address,uint256,bytes)\"))`\n     */\n    function onERC20Received(\n        address sender,\n        address from,\n        uint256 value,\n        bytes calldata data\n    ) external returns (bytes4);\n}\n"
    }
  },
  "settings": {
    "optimizer": {
      "enabled": true,
      "runs": 2000
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