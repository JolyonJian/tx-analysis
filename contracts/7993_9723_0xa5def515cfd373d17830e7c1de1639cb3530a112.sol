{{
  "language": "Solidity",
  "sources": {
    "contracts/DePoToken.sol": {
      "content": "// SPDX-License-Identifier: MIT\npragma solidity ^0.8.0;\n\nimport './UsingLiquidityProtectionService.sol';\nimport '@openzeppelin/contracts/access/Ownable.sol';\nimport '@openzeppelin/contracts/token/ERC20/ERC20.sol';\n\n\ncontract DePoToken is ERC20, Ownable, UsingLiquidityProtectionService(0x7F6140Bab96793126c0306C08687603F4Cb5b098) {\n\n    constructor() ERC20('DePo Token', 'DEPO') {\n        _mint(owner(), 1000000000 * 1e18);\n    }\n\n    function token_transfer(address _from, address _to, uint _amount) internal override {\n        _transfer(_from, _to, _amount); // Expose low-level token transfer function.\n    }\n    function token_balanceOf(address _holder) internal view override returns(uint) {\n        return balanceOf(_holder); // Expose balance check function.\n    }\n    function protectionAdminCheck() internal view override onlyOwner {} // Must revert to deny access.\n    function uniswapVariety() internal pure override returns(bytes32) {\n        return UNISWAP; // UNISWAP / PANCAKESWAP / QUICKSWAP.\n    }\n    function uniswapVersion() internal pure override returns(UniswapVersion) {\n        return UniswapVersion.V2; // V2 or V3.\n    }\n    function uniswapFactory() internal pure override returns(address) {\n        return 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f; // Replace with the correct address.\n    }\n    function _beforeTokenTransfer(address _from, address _to, uint _amount) internal override {\n        super._beforeTokenTransfer(_from, _to, _amount);\n        LiquidityProtection_beforeTokenTransfer(_from, _to, _amount);\n    }\n    // All the following overrides are optional, if you want to modify default behavior.\n\n    // How the protection gets disabled.\n    function protectionChecker() internal view override returns(bool) {\n        return ProtectionSwitch_timestamp(1634133600); // Switch off protection on Wednesday, October 13, 2021 2:00:00 PM GMT.\n        // return ProtectionSwitch_block(13000000); // Switch off protection on block 13000000.\n        //return ProtectionSwitch_manual(); // Switch off protection by calling disableProtection(); from owner. Default.\n    }\n\n    // This token will be pooled in pair with:\n    function counterToken() internal pure override returns(address) {\n        return 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2; // WETH\n    }\n}\n"
    },
    "contracts/UsingLiquidityProtectionService.sol": {
      "content": "// SPDX-License-Identifier: MIT\npragma solidity ^0.8.0;\n\nimport './external/UniswapV2Library.sol';\nimport './external/UniswapV3Library.sol';\nimport './IPLPS.sol';\n\nabstract contract UsingLiquidityProtectionService {\n    bool private unProtected = false;\n    IPLPS private plps;\n    uint64 internal constant HUNDRED_PERCENT = 1e18;\n    bytes32 internal constant UNISWAP = 0x96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f;\n    bytes32 internal constant PANCAKESWAP = 0x00fb7f630766e6a796048ea87d01acd3068e8ff67d078148a3fa3f4a84f69bd5;\n    bytes32 internal constant QUICKSWAP = 0x96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f;\n\n    enum UniswapVersion {\n        V2,\n        V3\n    }\n\n    enum UniswapV3Fees {\n        _005, // 0.05%\n        _03, // 0.3%\n        _1 // 1%\n    }\n\n    modifier onlyProtectionAdmin() {\n        protectionAdminCheck();\n        _;\n    }\n\n    constructor (address _plps) {\n        plps = IPLPS(_plps);\n    }\n\n    function LiquidityProtection_setLiquidityProtectionService(IPLPS _plps) external onlyProtectionAdmin() {\n        plps = _plps;\n    }\n\n    function token_transfer(address from, address to, uint amount) internal virtual;\n    function token_balanceOf(address holder) internal view virtual returns(uint);\n    function protectionAdminCheck() internal view virtual;\n    function uniswapVariety() internal pure virtual returns(bytes32);\n    function uniswapVersion() internal pure virtual returns(UniswapVersion);\n    function uniswapFactory() internal pure virtual returns(address);\n    function counterToken() internal pure virtual returns(address) {\n        return 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2; // WETH\n    }\n    function uniswapV3Fee() internal pure virtual returns(UniswapV3Fees) {\n        return UniswapV3Fees._03;\n    }\n    function protectionChecker() internal view virtual returns(bool) {\n        return ProtectionSwitch_manual();\n    }\n\n    function lps() private view returns(IPLPS) {\n        return plps;\n    }\n\n    function LiquidityProtection_beforeTokenTransfer(address _from, address _to, uint _amount) internal virtual {\n        if (protectionChecker()) {\n            if (unProtected) {\n                return;\n            }\n            lps().LiquidityProtection_beforeTokenTransfer(getLiquidityPool(), _from, _to, _amount);\n        }\n    }\n\n    function revokeBlocked(address[] calldata _holders, address _revokeTo) external onlyProtectionAdmin() {\n        require(protectionChecker(), 'UsingLiquidityProtectionService: protection removed');\n        unProtected = true;\n        address pool = getLiquidityPool();\n        for (uint i = 0; i < _holders.length; i++) {\n            address holder = _holders[i];\n            if (lps().isBlocked(pool, holder)) {\n                token_transfer(holder, _revokeTo, token_balanceOf(holder));\n            }\n        }\n        unProtected = false;\n    }\n\n    function LiquidityProtection_unblock(address[] calldata _holders) external onlyProtectionAdmin() {\n        require(protectionChecker(), 'UsingLiquidityProtectionService: protection removed');\n        address pool = getLiquidityPool();\n        for (uint i = 0; i < _holders.length; i++) {\n            lps().unblock(pool, _holders[i]);\n        }\n    }\n\n    function disableProtection() external onlyProtectionAdmin() {\n        unProtected = true;\n    }\n\n    function isProtected() public view returns(bool) {\n        return not(unProtected);\n    }\n\n    function ProtectionSwitch_manual() internal view returns(bool) {\n        return isProtected();\n    }\n\n    function ProtectionSwitch_timestamp(uint _timestamp) internal view returns(bool) {\n        return not(passed(_timestamp));\n    }\n\n    function ProtectionSwitch_block(uint _block) internal view returns(bool) {\n        return not(blockPassed(_block));\n    }\n\n    function blockPassed(uint _block) internal view returns(bool) {\n        return _block < block.number;\n    }\n\n    function passed(uint _timestamp) internal view returns(bool) {\n        return _timestamp < block.timestamp;\n    }\n\n    function not(bool _condition) internal pure returns(bool) {\n        return !_condition;\n    }\n\n    function feeToUint24(UniswapV3Fees _fee) internal pure returns(uint24) {\n        if (_fee == UniswapV3Fees._03) return 3000;\n        if (_fee == UniswapV3Fees._005) return 500;\n        return 10000;\n    }\n\n    function getLiquidityPool() public view returns(address) {\n        if (uniswapVersion() == UniswapVersion.V2) {\n            return UniswapV2Library.pairFor(uniswapVariety(), uniswapFactory(), address(this), counterToken());\n        }\n        require(uniswapVariety() == UNISWAP, 'LiquidityProtection: uniswapVariety() can only be UNISWAP for V3.');\n        return UniswapV3Library.computeAddress(uniswapFactory(),\n            UniswapV3Library.getPoolKey(address(this), counterToken(), feeToUint24(uniswapV3Fee())));\n    }\n}\n"
    },
    "@openzeppelin/contracts/access/Ownable.sol": {
      "content": "// SPDX-License-Identifier: MIT\n\npragma solidity ^0.8.0;\n\nimport \"../utils/Context.sol\";\n/**\n * @dev Contract module which provides a basic access control mechanism, where\n * there is an account (an owner) that can be granted exclusive access to\n * specific functions.\n *\n * By default, the owner account will be the one that deploys the contract. This\n * can later be changed with {transferOwnership}.\n *\n * This module is used through inheritance. It will make available the modifier\n * `onlyOwner`, which can be applied to your functions to restrict their use to\n * the owner.\n */\nabstract contract Ownable is Context {\n    address private _owner;\n\n    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);\n\n    /**\n     * @dev Initializes the contract setting the deployer as the initial owner.\n     */\n    constructor () {\n        address msgSender = _msgSender();\n        _owner = msgSender;\n        emit OwnershipTransferred(address(0), msgSender);\n    }\n\n    /**\n     * @dev Returns the address of the current owner.\n     */\n    function owner() public view virtual returns (address) {\n        return _owner;\n    }\n\n    /**\n     * @dev Throws if called by any account other than the owner.\n     */\n    modifier onlyOwner() {\n        require(owner() == _msgSender(), \"Ownable: caller is not the owner\");\n        _;\n    }\n\n    /**\n     * @dev Leaves the contract without owner. It will not be possible to call\n     * `onlyOwner` functions anymore. Can only be called by the current owner.\n     *\n     * NOTE: Renouncing ownership will leave the contract without an owner,\n     * thereby removing any functionality that is only available to the owner.\n     */\n    function renounceOwnership() public virtual onlyOwner {\n        emit OwnershipTransferred(_owner, address(0));\n        _owner = address(0);\n    }\n\n    /**\n     * @dev Transfers ownership of the contract to a new account (`newOwner`).\n     * Can only be called by the current owner.\n     */\n    function transferOwnership(address newOwner) public virtual onlyOwner {\n        require(newOwner != address(0), \"Ownable: new owner is the zero address\");\n        emit OwnershipTransferred(_owner, newOwner);\n        _owner = newOwner;\n    }\n}\n"
    },
    "@openzeppelin/contracts/token/ERC20/ERC20.sol": {
      "content": "// SPDX-License-Identifier: MIT\n\npragma solidity ^0.8.0;\n\nimport \"./IERC20.sol\";\nimport \"./extensions/IERC20Metadata.sol\";\nimport \"../../utils/Context.sol\";\n\n/**\n * @dev Implementation of the {IERC20} interface.\n *\n * This implementation is agnostic to the way tokens are created. This means\n * that a supply mechanism has to be added in a derived contract using {_mint}.\n * For a generic mechanism see {ERC20PresetMinterPauser}.\n *\n * TIP: For a detailed writeup see our guide\n * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How\n * to implement supply mechanisms].\n *\n * We have followed general OpenZeppelin guidelines: functions revert instead\n * of returning `false` on failure. This behavior is nonetheless conventional\n * and does not conflict with the expectations of ERC20 applications.\n *\n * Additionally, an {Approval} event is emitted on calls to {transferFrom}.\n * This allows applications to reconstruct the allowance for all accounts just\n * by listening to said events. Other implementations of the EIP may not emit\n * these events, as it isn't required by the specification.\n *\n * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}\n * functions have been added to mitigate the well-known issues around setting\n * allowances. See {IERC20-approve}.\n */\ncontract ERC20 is Context, IERC20, IERC20Metadata {\n    mapping (address => uint256) private _balances;\n\n    mapping (address => mapping (address => uint256)) private _allowances;\n\n    uint256 private _totalSupply;\n\n    string private _name;\n    string private _symbol;\n\n    /**\n     * @dev Sets the values for {name} and {symbol}.\n     *\n     * The defaut value of {decimals} is 18. To select a different value for\n     * {decimals} you should overload it.\n     *\n     * All two of these values are immutable: they can only be set once during\n     * construction.\n     */\n    constructor (string memory name_, string memory symbol_) {\n        _name = name_;\n        _symbol = symbol_;\n    }\n\n    /**\n     * @dev Returns the name of the token.\n     */\n    function name() public view virtual override returns (string memory) {\n        return _name;\n    }\n\n    /**\n     * @dev Returns the symbol of the token, usually a shorter version of the\n     * name.\n     */\n    function symbol() public view virtual override returns (string memory) {\n        return _symbol;\n    }\n\n    /**\n     * @dev Returns the number of decimals used to get its user representation.\n     * For example, if `decimals` equals `2`, a balance of `505` tokens should\n     * be displayed to a user as `5,05` (`505 / 10 ** 2`).\n     *\n     * Tokens usually opt for a value of 18, imitating the relationship between\n     * Ether and Wei. This is the value {ERC20} uses, unless this function is\n     * overridden;\n     *\n     * NOTE: This information is only used for _display_ purposes: it in\n     * no way affects any of the arithmetic of the contract, including\n     * {IERC20-balanceOf} and {IERC20-transfer}.\n     */\n    function decimals() public view virtual override returns (uint8) {\n        return 18;\n    }\n\n    /**\n     * @dev See {IERC20-totalSupply}.\n     */\n    function totalSupply() public view virtual override returns (uint256) {\n        return _totalSupply;\n    }\n\n    /**\n     * @dev See {IERC20-balanceOf}.\n     */\n    function balanceOf(address account) public view virtual override returns (uint256) {\n        return _balances[account];\n    }\n\n    /**\n     * @dev See {IERC20-transfer}.\n     *\n     * Requirements:\n     *\n     * - `recipient` cannot be the zero address.\n     * - the caller must have a balance of at least `amount`.\n     */\n    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {\n        _transfer(_msgSender(), recipient, amount);\n        return true;\n    }\n\n    /**\n     * @dev See {IERC20-allowance}.\n     */\n    function allowance(address owner, address spender) public view virtual override returns (uint256) {\n        return _allowances[owner][spender];\n    }\n\n    /**\n     * @dev See {IERC20-approve}.\n     *\n     * Requirements:\n     *\n     * - `spender` cannot be the zero address.\n     */\n    function approve(address spender, uint256 amount) public virtual override returns (bool) {\n        _approve(_msgSender(), spender, amount);\n        return true;\n    }\n\n    /**\n     * @dev See {IERC20-transferFrom}.\n     *\n     * Emits an {Approval} event indicating the updated allowance. This is not\n     * required by the EIP. See the note at the beginning of {ERC20}.\n     *\n     * Requirements:\n     *\n     * - `sender` and `recipient` cannot be the zero address.\n     * - `sender` must have a balance of at least `amount`.\n     * - the caller must have allowance for ``sender``'s tokens of at least\n     * `amount`.\n     */\n    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {\n        _transfer(sender, recipient, amount);\n\n        uint256 currentAllowance = _allowances[sender][_msgSender()];\n        require(currentAllowance >= amount, \"ERC20: transfer amount exceeds allowance\");\n        _approve(sender, _msgSender(), currentAllowance - amount);\n\n        return true;\n    }\n\n    /**\n     * @dev Atomically increases the allowance granted to `spender` by the caller.\n     *\n     * This is an alternative to {approve} that can be used as a mitigation for\n     * problems described in {IERC20-approve}.\n     *\n     * Emits an {Approval} event indicating the updated allowance.\n     *\n     * Requirements:\n     *\n     * - `spender` cannot be the zero address.\n     */\n    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {\n        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);\n        return true;\n    }\n\n    /**\n     * @dev Atomically decreases the allowance granted to `spender` by the caller.\n     *\n     * This is an alternative to {approve} that can be used as a mitigation for\n     * problems described in {IERC20-approve}.\n     *\n     * Emits an {Approval} event indicating the updated allowance.\n     *\n     * Requirements:\n     *\n     * - `spender` cannot be the zero address.\n     * - `spender` must have allowance for the caller of at least\n     * `subtractedValue`.\n     */\n    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {\n        uint256 currentAllowance = _allowances[_msgSender()][spender];\n        require(currentAllowance >= subtractedValue, \"ERC20: decreased allowance below zero\");\n        _approve(_msgSender(), spender, currentAllowance - subtractedValue);\n\n        return true;\n    }\n\n    /**\n     * @dev Moves tokens `amount` from `sender` to `recipient`.\n     *\n     * This is internal function is equivalent to {transfer}, and can be used to\n     * e.g. implement automatic token fees, slashing mechanisms, etc.\n     *\n     * Emits a {Transfer} event.\n     *\n     * Requirements:\n     *\n     * - `sender` cannot be the zero address.\n     * - `recipient` cannot be the zero address.\n     * - `sender` must have a balance of at least `amount`.\n     */\n    function _transfer(address sender, address recipient, uint256 amount) internal virtual {\n        require(sender != address(0), \"ERC20: transfer from the zero address\");\n        require(recipient != address(0), \"ERC20: transfer to the zero address\");\n\n        _beforeTokenTransfer(sender, recipient, amount);\n\n        uint256 senderBalance = _balances[sender];\n        require(senderBalance >= amount, \"ERC20: transfer amount exceeds balance\");\n        _balances[sender] = senderBalance - amount;\n        _balances[recipient] += amount;\n\n        emit Transfer(sender, recipient, amount);\n    }\n\n    /** @dev Creates `amount` tokens and assigns them to `account`, increasing\n     * the total supply.\n     *\n     * Emits a {Transfer} event with `from` set to the zero address.\n     *\n     * Requirements:\n     *\n     * - `to` cannot be the zero address.\n     */\n    function _mint(address account, uint256 amount) internal virtual {\n        require(account != address(0), \"ERC20: mint to the zero address\");\n\n        _beforeTokenTransfer(address(0), account, amount);\n\n        _totalSupply += amount;\n        _balances[account] += amount;\n        emit Transfer(address(0), account, amount);\n    }\n\n    /**\n     * @dev Destroys `amount` tokens from `account`, reducing the\n     * total supply.\n     *\n     * Emits a {Transfer} event with `to` set to the zero address.\n     *\n     * Requirements:\n     *\n     * - `account` cannot be the zero address.\n     * - `account` must have at least `amount` tokens.\n     */\n    function _burn(address account, uint256 amount) internal virtual {\n        require(account != address(0), \"ERC20: burn from the zero address\");\n\n        _beforeTokenTransfer(account, address(0), amount);\n\n        uint256 accountBalance = _balances[account];\n        require(accountBalance >= amount, \"ERC20: burn amount exceeds balance\");\n        _balances[account] = accountBalance - amount;\n        _totalSupply -= amount;\n\n        emit Transfer(account, address(0), amount);\n    }\n\n    /**\n     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.\n     *\n     * This internal function is equivalent to `approve`, and can be used to\n     * e.g. set automatic allowances for certain subsystems, etc.\n     *\n     * Emits an {Approval} event.\n     *\n     * Requirements:\n     *\n     * - `owner` cannot be the zero address.\n     * - `spender` cannot be the zero address.\n     */\n    function _approve(address owner, address spender, uint256 amount) internal virtual {\n        require(owner != address(0), \"ERC20: approve from the zero address\");\n        require(spender != address(0), \"ERC20: approve to the zero address\");\n\n        _allowances[owner][spender] = amount;\n        emit Approval(owner, spender, amount);\n    }\n\n    /**\n     * @dev Hook that is called before any transfer of tokens. This includes\n     * minting and burning.\n     *\n     * Calling conditions:\n     *\n     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens\n     * will be to transferred to `to`.\n     * - when `from` is zero, `amount` tokens will be minted for `to`.\n     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.\n     * - `from` and `to` are never both zero.\n     *\n     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].\n     */\n    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }\n}\n"
    },
    "contracts/external/UniswapV2Library.sol": {
      "content": "// SPDX-License-Identifier: GPL-3.0\npragma solidity ^0.8.0;\n\n// Exempt from the original UniswapV2Library.\nlibrary UniswapV2Library {\n    // returns sorted token addresses, used to handle return values from pairs sorted in this order\n    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {\n        require(tokenA != tokenB, 'UniswapV2Library: IDENTICAL_ADDRESSES');\n        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);\n        require(token0 != address(0), 'UniswapV2Library: ZERO_ADDRESS');\n    }\n\n    // calculates the CREATE2 address for a pair without making any external calls\n    function pairFor(bytes32 initCodeHash, address factory, address tokenA, address tokenB) internal pure returns (address pair) {\n        (address token0, address token1) = sortTokens(tokenA, tokenB);\n        pair = address(uint160(uint(keccak256(abi.encodePacked(\n                hex'ff',\n                factory,\n                keccak256(abi.encodePacked(token0, token1)),\n                initCodeHash // init code hash\n            )))));\n    }\n}\n"
    },
    "contracts/external/UniswapV3Library.sol": {
      "content": "// SPDX-License-Identifier: GPL-2.0-or-later\npragma solidity ^0.8.0;\n\n/// @notice based on https://github.com/Uniswap/uniswap-v3-periphery/blob/v1.0.0/contracts/libraries/PoolAddress.sol\n/// @notice changed compiler version and lib name.\n\n/// @title Provides functions for deriving a pool address from the factory, tokens, and the fee\nlibrary UniswapV3Library {\n    bytes32 internal constant POOL_INIT_CODE_HASH = 0xe34f199b19b2b4f47f68442619d555527d244f78a3297ea89325f843f87b8b54;\n\n    /// @notice The identifying key of the pool\n    struct PoolKey {\n        address token0;\n        address token1;\n        uint24 fee;\n    }\n\n    /// @notice Returns PoolKey: the ordered tokens with the matched fee levels\n    /// @param tokenA The first token of a pool, unsorted\n    /// @param tokenB The second token of a pool, unsorted\n    /// @param fee The fee level of the pool\n    /// @return Poolkey The pool details with ordered token0 and token1 assignments\n    function getPoolKey(\n        address tokenA,\n        address tokenB,\n        uint24 fee\n    ) internal pure returns (PoolKey memory) {\n        if (tokenA > tokenB) (tokenA, tokenB) = (tokenB, tokenA);\n        return PoolKey({token0: tokenA, token1: tokenB, fee: fee});\n    }\n\n    /// @notice Deterministically computes the pool address given the factory and PoolKey\n    /// @param factory The Uniswap V3 factory contract address\n    /// @param key The PoolKey\n    /// @return pool The contract address of the V3 pool\n    function computeAddress(address factory, PoolKey memory key) internal pure returns (address pool) {\n        require(key.token0 < key.token1);\n        pool = address(\n            uint160(\n                uint256(\n                    keccak256(\n                        abi.encodePacked(\n                            hex'ff',\n                            factory,\n                            keccak256(abi.encode(key.token0, key.token1, key.fee)),\n                            POOL_INIT_CODE_HASH\n                        )\n                    )\n                )\n            )\n        );\n    }\n}\n"
    },
    "contracts/IPLPS.sol": {
      "content": "// SPDX-License-Identifier: MIT\npragma solidity ^0.8.0;\n\ninterface IPLPS {\n    function LiquidityProtection_beforeTokenTransfer(\n        address _pool, address _from, address _to, uint _amount) external;\n    function isBlocked(address _pool, address _who) external view returns(bool);\n    function unblock(address _pool, address _who) external;\n}\n"
    },
    "@openzeppelin/contracts/utils/Context.sol": {
      "content": "// SPDX-License-Identifier: MIT\n\npragma solidity ^0.8.0;\n\n/*\n * @dev Provides information about the current execution context, including the\n * sender of the transaction and its data. While these are generally available\n * via msg.sender and msg.data, they should not be accessed in such a direct\n * manner, since when dealing with meta-transactions the account sending and\n * paying for execution may not be the actual sender (as far as an application\n * is concerned).\n *\n * This contract is only required for intermediate, library-like contracts.\n */\nabstract contract Context {\n    function _msgSender() internal view virtual returns (address) {\n        return msg.sender;\n    }\n\n    function _msgData() internal view virtual returns (bytes calldata) {\n        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691\n        return msg.data;\n    }\n}\n"
    },
    "@openzeppelin/contracts/token/ERC20/IERC20.sol": {
      "content": "// SPDX-License-Identifier: MIT\n\npragma solidity ^0.8.0;\n\n/**\n * @dev Interface of the ERC20 standard as defined in the EIP.\n */\ninterface IERC20 {\n    /**\n     * @dev Returns the amount of tokens in existence.\n     */\n    function totalSupply() external view returns (uint256);\n\n    /**\n     * @dev Returns the amount of tokens owned by `account`.\n     */\n    function balanceOf(address account) external view returns (uint256);\n\n    /**\n     * @dev Moves `amount` tokens from the caller's account to `recipient`.\n     *\n     * Returns a boolean value indicating whether the operation succeeded.\n     *\n     * Emits a {Transfer} event.\n     */\n    function transfer(address recipient, uint256 amount) external returns (bool);\n\n    /**\n     * @dev Returns the remaining number of tokens that `spender` will be\n     * allowed to spend on behalf of `owner` through {transferFrom}. This is\n     * zero by default.\n     *\n     * This value changes when {approve} or {transferFrom} are called.\n     */\n    function allowance(address owner, address spender) external view returns (uint256);\n\n    /**\n     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.\n     *\n     * Returns a boolean value indicating whether the operation succeeded.\n     *\n     * IMPORTANT: Beware that changing an allowance with this method brings the risk\n     * that someone may use both the old and the new allowance by unfortunate\n     * transaction ordering. One possible solution to mitigate this race\n     * condition is to first reduce the spender's allowance to 0 and set the\n     * desired value afterwards:\n     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729\n     *\n     * Emits an {Approval} event.\n     */\n    function approve(address spender, uint256 amount) external returns (bool);\n\n    /**\n     * @dev Moves `amount` tokens from `sender` to `recipient` using the\n     * allowance mechanism. `amount` is then deducted from the caller's\n     * allowance.\n     *\n     * Returns a boolean value indicating whether the operation succeeded.\n     *\n     * Emits a {Transfer} event.\n     */\n    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);\n\n    /**\n     * @dev Emitted when `value` tokens are moved from one account (`from`) to\n     * another (`to`).\n     *\n     * Note that `value` may be zero.\n     */\n    event Transfer(address indexed from, address indexed to, uint256 value);\n\n    /**\n     * @dev Emitted when the allowance of a `spender` for an `owner` is set by\n     * a call to {approve}. `value` is the new allowance.\n     */\n    event Approval(address indexed owner, address indexed spender, uint256 value);\n}\n"
    },
    "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol": {
      "content": "// SPDX-License-Identifier: MIT\n\npragma solidity ^0.8.0;\n\nimport \"../IERC20.sol\";\n\n/**\n * @dev Interface for the optional metadata functions from the ERC20 standard.\n *\n * _Available since v4.1._\n */\ninterface IERC20Metadata is IERC20 {\n    /**\n     * @dev Returns the name of the token.\n     */\n    function name() external view returns (string memory);\n\n    /**\n     * @dev Returns the symbol of the token.\n     */\n    function symbol() external view returns (string memory);\n\n    /**\n     * @dev Returns the decimals places of the token.\n     */\n    function decimals() external view returns (uint8);\n}\n"
    }
  },
  "settings": {
    "optimizer": {
      "enabled": true,
      "runs": 999999
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