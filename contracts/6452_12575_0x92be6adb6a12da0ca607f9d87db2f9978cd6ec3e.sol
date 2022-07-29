{{
  "language": "Solidity",
  "settings": {
    "evmVersion": "istanbul",
    "libraries": {},
    "metadata": {
      "bytecodeHash": "ipfs",
      "useLiteralContent": true
    },
    "optimizer": {
      "enabled": true,
      "runs": 200
    },
    "remappings": [],
    "outputSelection": {
      "*": {
        "*": [
          "evm.bytecode",
          "evm.deployedBytecode",
          "abi"
        ]
      }
    }
  },
  "sources": {
    "contracts/_base/ZapBaseV2.sol": {
      "content": "// SPDX-License-Identifier: GPL-2.0\npragma solidity ^0.8.0;\n\nimport \"../oz/0.8.0/access/Ownable.sol\";\nimport \"../oz/0.8.0/token/ERC20/utils/SafeERC20.sol\";\n\nabstract contract ZapBaseV2 is Ownable {\n    using SafeERC20 for IERC20;\n    bool public stopped = false;\n\n    // if true, goodwill is not deducted\n    mapping(address => bool) public feeWhitelist;\n\n    uint256 public goodwill;\n    // % share of goodwill (0-100 %)\n    uint256 affiliateSplit;\n    // restrict affiliates\n    mapping(address => bool) public affiliates;\n    // affiliate => token => amount\n    mapping(address => mapping(address => uint256)) public affiliateBalance;\n    // token => amount\n    mapping(address => uint256) public totalAffiliateBalance;\n    // swapTarget => approval status\n    mapping(address => bool) public approvedTargets;\n\n    address internal constant ETHAddress =\n        0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;\n\n    constructor(uint256 _goodwill, uint256 _affiliateSplit) {\n        goodwill = _goodwill;\n        affiliateSplit = _affiliateSplit;\n    }\n\n    // circuit breaker modifiers\n    modifier stopInEmergency {\n        if (stopped) {\n            revert(\"Temporarily Paused\");\n        } else {\n            _;\n        }\n    }\n\n    function _getBalance(address token)\n        internal\n        view\n        returns (uint256 balance)\n    {\n        if (token == address(0)) {\n            balance = address(this).balance;\n        } else {\n            balance = IERC20(token).balanceOf(address(this));\n        }\n    }\n\n    function _approveToken(address token, address spender) internal {\n        IERC20 _token = IERC20(token);\n        if (_token.allowance(address(this), spender) > 0) return;\n        else {\n            _token.safeApprove(spender, type(uint256).max);\n        }\n    }\n\n    function _approveToken(\n        address token,\n        address spender,\n        uint256 amount\n    ) internal {\n        IERC20(token).safeApprove(spender, 0);\n        IERC20(token).safeApprove(spender, amount);\n    }\n\n    // - to Pause the contract\n    function toggleContractActive() public onlyOwner {\n        stopped = !stopped;\n    }\n\n    function set_feeWhitelist(address zapAddress, bool status)\n        external\n        onlyOwner\n    {\n        feeWhitelist[zapAddress] = status;\n    }\n\n    function set_new_goodwill(uint256 _new_goodwill) public onlyOwner {\n        require(\n            _new_goodwill >= 0 && _new_goodwill <= 100,\n            \"GoodWill Value not allowed\"\n        );\n        goodwill = _new_goodwill;\n    }\n\n    function set_new_affiliateSplit(uint256 _new_affiliateSplit)\n        external\n        onlyOwner\n    {\n        require(\n            _new_affiliateSplit <= 100,\n            \"Affiliate Split Value not allowed\"\n        );\n        affiliateSplit = _new_affiliateSplit;\n    }\n\n    function set_affiliate(address _affiliate, bool _status)\n        external\n        onlyOwner\n    {\n        affiliates[_affiliate] = _status;\n    }\n\n    ///@notice Withdraw goodwill share, retaining affilliate share\n    function withdrawTokens(address[] calldata tokens) external onlyOwner {\n        for (uint256 i = 0; i < tokens.length; i++) {\n            uint256 qty;\n\n            if (tokens[i] == ETHAddress) {\n                qty = address(this).balance - totalAffiliateBalance[tokens[i]];\n\n                Address.sendValue(payable(owner()), qty);\n            } else {\n                qty =\n                    IERC20(tokens[i]).balanceOf(address(this)) -\n                    totalAffiliateBalance[tokens[i]];\n                IERC20(tokens[i]).safeTransfer(owner(), qty);\n            }\n        }\n    }\n\n    ///@notice Withdraw affilliate share, retaining goodwill share\n    function affilliateWithdraw(address[] calldata tokens) external {\n        uint256 tokenBal;\n        for (uint256 i = 0; i < tokens.length; i++) {\n            tokenBal = affiliateBalance[msg.sender][tokens[i]];\n            affiliateBalance[msg.sender][tokens[i]] = 0;\n            totalAffiliateBalance[tokens[i]] =\n                totalAffiliateBalance[tokens[i]] -\n                tokenBal;\n\n            if (tokens[i] == ETHAddress) {\n                Address.sendValue(payable(msg.sender), tokenBal);\n            } else {\n                IERC20(tokens[i]).safeTransfer(msg.sender, tokenBal);\n            }\n        }\n    }\n\n    function setApprovedTargets(\n        address[] calldata targets,\n        bool[] calldata isApproved\n    ) external onlyOwner {\n        require(targets.length == isApproved.length, \"Invalid Input length\");\n\n        for (uint256 i = 0; i < targets.length; i++) {\n            approvedTargets[targets[i]] = isApproved[i];\n        }\n    }\n\n    receive() external payable {\n        require(msg.sender != tx.origin, \"Do not send ETH directly\");\n    }\n}\n"
    },
    "contracts/_base/ZapInBaseV3.sol": {
      "content": "// SPDX-License-Identifier: GPL-2.0\n\npragma solidity ^0.8.0;\nimport \"./ZapBaseV2.sol\";\n\nabstract contract ZapInBaseV3 is ZapBaseV2 {\n    using SafeERC20 for IERC20;\n\n    function _pullTokens(\n        address token,\n        uint256 amount,\n        address affiliate,\n        bool enableGoodwill,\n        bool shouldSellEntireBalance\n    ) internal returns (uint256 value) {\n        uint256 totalGoodwillPortion;\n\n        if (token == address(0)) {\n            require(msg.value > 0, \"No eth sent\");\n\n            // subtract goodwill\n            totalGoodwillPortion = _subtractGoodwill(\n                ETHAddress,\n                msg.value,\n                affiliate,\n                enableGoodwill\n            );\n\n            return msg.value - totalGoodwillPortion;\n        }\n        require(amount > 0, \"Invalid token amount\");\n        require(msg.value == 0, \"Eth sent with token\");\n\n        //transfer token\n        if (shouldSellEntireBalance) {\n            require(\n                Address.isContract(msg.sender),\n                \"ERR: shouldSellEntireBalance is true for EOA\"\n            );\n            amount = IERC20(token).allowance(msg.sender, address(this));\n        }\n        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);\n\n        // subtract goodwill\n        totalGoodwillPortion = _subtractGoodwill(\n            token,\n            amount,\n            affiliate,\n            enableGoodwill\n        );\n\n        return amount - totalGoodwillPortion;\n    }\n\n    function _subtractGoodwill(\n        address token,\n        uint256 amount,\n        address affiliate,\n        bool enableGoodwill\n    ) internal returns (uint256 totalGoodwillPortion) {\n        bool whitelisted = feeWhitelist[msg.sender];\n        if (enableGoodwill && !whitelisted && goodwill > 0) {\n            totalGoodwillPortion = (amount * goodwill) / 10000;\n\n            if (affiliates[affiliate]) {\n                if (token == address(0)) {\n                    token = ETHAddress;\n                }\n\n                uint256 affiliatePortion =\n                    (totalGoodwillPortion * affiliateSplit) / 100;\n                affiliateBalance[affiliate][token] += affiliatePortion;\n                totalAffiliateBalance[token] += affiliatePortion;\n            }\n        }\n    }\n}\n"
    },
    "contracts/oz/0.8.0/access/Ownable.sol": {
      "content": "// SPDX-License-Identifier: MIT\n\npragma solidity ^0.8.0;\n\nimport \"../utils/Context.sol\";\n\n/**\n * @dev Contract module which provides a basic access control mechanism, where\n * there is an account (an owner) that can be granted exclusive access to\n * specific functions.\n *\n * By default, the owner account will be the one that deploys the contract. This\n * can later be changed with {transferOwnership}.\n *\n * This module is used through inheritance. It will make available the modifier\n * `onlyOwner`, which can be applied to your functions to restrict their use to\n * the owner.\n */\nabstract contract Ownable is Context {\n    address private _owner;\n\n    event OwnershipTransferred(\n        address indexed previousOwner,\n        address indexed newOwner\n    );\n\n    /**\n     * @dev Initializes the contract setting the deployer as the initial owner.\n     */\n    constructor() {\n        address msgSender = _msgSender();\n        _owner = msgSender;\n        emit OwnershipTransferred(address(0), msgSender);\n    }\n\n    /**\n     * @dev Returns the address of the current owner.\n     */\n    function owner() public view virtual returns (address) {\n        return _owner;\n    }\n\n    /**\n     * @dev Throws if called by any account other than the owner.\n     */\n    modifier onlyOwner() {\n        require(owner() == _msgSender(), \"Ownable: caller is not the owner\");\n        _;\n    }\n\n    /**\n     * @dev Leaves the contract without owner. It will not be possible to call\n     * `onlyOwner` functions anymore. Can only be called by the current owner.\n     *\n     * NOTE: Renouncing ownership will leave the contract without an owner,\n     * thereby removing any functionality that is only available to the owner.\n     */\n    function renounceOwnership() public virtual onlyOwner {\n        emit OwnershipTransferred(_owner, address(0));\n        _owner = address(0);\n    }\n\n    /**\n     * @dev Transfers ownership of the contract to a new account (`newOwner`).\n     * Can only be called by the current owner.\n     */\n    function transferOwnership(address newOwner) public virtual onlyOwner {\n        require(\n            newOwner != address(0),\n            \"Ownable: new owner is the zero address\"\n        );\n        emit OwnershipTransferred(_owner, newOwner);\n        _owner = newOwner;\n    }\n}\n"
    },
    "contracts/oz/0.8.0/token/ERC20/IERC20.sol": {
      "content": "// SPDX-License-Identifier: MIT\n\npragma solidity ^0.8.0;\n\n/**\n * @dev Interface of the ERC20 standard as defined in the EIP.\n */\ninterface IERC20 {\n    /**\n     * @dev Returns the amount of tokens in existence.\n     */\n    function totalSupply() external view returns (uint256);\n\n    /**\n     * @dev Returns the amount of tokens owned by `account`.\n     */\n    function balanceOf(address account) external view returns (uint256);\n\n    /**\n     * @dev Moves `amount` tokens from the caller's account to `recipient`.\n     *\n     * Returns a boolean value indicating whether the operation succeeded.\n     *\n     * Emits a {Transfer} event.\n     */\n    function transfer(address recipient, uint256 amount)\n        external\n        returns (bool);\n\n    /**\n     * @dev Returns the remaining number of tokens that `spender` will be\n     * allowed to spend on behalf of `owner` through {transferFrom}. This is\n     * zero by default.\n     *\n     * This value changes when {approve} or {transferFrom} are called.\n     */\n    function allowance(address owner, address spender)\n        external\n        view\n        returns (uint256);\n\n    /**\n     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.\n     *\n     * Returns a boolean value indicating whether the operation succeeded.\n     *\n     * IMPORTANT: Beware that changing an allowance with this method brings the risk\n     * that someone may use both the old and the new allowance by unfortunate\n     * transaction ordering. One possible solution to mitigate this race\n     * condition is to first reduce the spender's allowance to 0 and set the\n     * desired value afterwards:\n     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729\n     *\n     * Emits an {Approval} event.\n     */\n    function approve(address spender, uint256 amount) external returns (bool);\n\n    /**\n     * @dev Moves `amount` tokens from `sender` to `recipient` using the\n     * allowance mechanism. `amount` is then deducted from the caller's\n     * allowance.\n     *\n     * Returns a boolean value indicating whether the operation succeeded.\n     *\n     * Emits a {Transfer} event.\n     */\n    function transferFrom(\n        address sender,\n        address recipient,\n        uint256 amount\n    ) external returns (bool);\n\n    /**\n     * @dev Emitted when `value` tokens are moved from one account (`from`) to\n     * another (`to`).\n     *\n     * Note that `value` may be zero.\n     */\n    event Transfer(address indexed from, address indexed to, uint256 value);\n\n    /**\n     * @dev Emitted when the allowance of a `spender` for an `owner` is set by\n     * a call to {approve}. `value` is the new allowance.\n     */\n    event Approval(\n        address indexed owner,\n        address indexed spender,\n        uint256 value\n    );\n}\n"
    },
    "contracts/oz/0.8.0/token/ERC20/utils/SafeERC20.sol": {
      "content": "// SPDX-License-Identifier: MIT\n\npragma solidity ^0.8.0;\n\nimport \"../IERC20.sol\";\nimport \"../../../utils/Address.sol\";\n\n/**\n * @title SafeERC20\n * @dev Wrappers around ERC20 operations that throw on failure (when the token\n * contract returns false). Tokens that return no value (and instead revert or\n * throw on failure) are also supported, non-reverting calls are assumed to be\n * successful.\n * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,\n * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.\n */\nlibrary SafeERC20 {\n    using Address for address;\n\n    function safeTransfer(\n        IERC20 token,\n        address to,\n        uint256 value\n    ) internal {\n        _callOptionalReturn(\n            token,\n            abi.encodeWithSelector(token.transfer.selector, to, value)\n        );\n    }\n\n    function safeTransferFrom(\n        IERC20 token,\n        address from,\n        address to,\n        uint256 value\n    ) internal {\n        _callOptionalReturn(\n            token,\n            abi.encodeWithSelector(token.transferFrom.selector, from, to, value)\n        );\n    }\n\n    /**\n     * @dev Deprecated. This function has issues similar to the ones found in\n     * {IERC20-approve}, and its usage is discouraged.\n     *\n     * Whenever possible, use {safeIncreaseAllowance} and\n     * {safeDecreaseAllowance} instead.\n     */\n    function safeApprove(\n        IERC20 token,\n        address spender,\n        uint256 value\n    ) internal {\n        // safeApprove should only be called when setting an initial allowance,\n        // or when resetting it to zero. To increase and decrease it, use\n        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'\n        // solhint-disable-next-line max-line-length\n        require(\n            (value == 0) || (token.allowance(address(this), spender) == 0),\n            \"SafeERC20: approve from non-zero to non-zero allowance\"\n        );\n        _callOptionalReturn(\n            token,\n            abi.encodeWithSelector(token.approve.selector, spender, value)\n        );\n    }\n\n    function safeIncreaseAllowance(\n        IERC20 token,\n        address spender,\n        uint256 value\n    ) internal {\n        uint256 newAllowance = token.allowance(address(this), spender) + value;\n        _callOptionalReturn(\n            token,\n            abi.encodeWithSelector(\n                token.approve.selector,\n                spender,\n                newAllowance\n            )\n        );\n    }\n\n    function safeDecreaseAllowance(\n        IERC20 token,\n        address spender,\n        uint256 value\n    ) internal {\n        unchecked {\n            uint256 oldAllowance = token.allowance(address(this), spender);\n            require(\n                oldAllowance >= value,\n                \"SafeERC20: decreased allowance below zero\"\n            );\n            uint256 newAllowance = oldAllowance - value;\n            _callOptionalReturn(\n                token,\n                abi.encodeWithSelector(\n                    token.approve.selector,\n                    spender,\n                    newAllowance\n                )\n            );\n        }\n    }\n\n    /**\n     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement\n     * on the return value: the return value is optional (but if data is returned, it must not be false).\n     * @param token The token targeted by the call.\n     * @param data The call data (encoded using abi.encode or one of its variants).\n     */\n    function _callOptionalReturn(IERC20 token, bytes memory data) private {\n        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since\n        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that\n        // the target address contains contract code and also asserts for success in the low-level call.\n\n        bytes memory returndata =\n            address(token).functionCall(\n                data,\n                \"SafeERC20: low-level call failed\"\n            );\n        if (returndata.length > 0) {\n            // Return data is optional\n            // solhint-disable-next-line max-line-length\n            require(\n                abi.decode(returndata, (bool)),\n                \"SafeERC20: ERC20 operation did not succeed\"\n            );\n        }\n    }\n}\n"
    },
    "contracts/oz/0.8.0/utils/Address.sol": {
      "content": "// SPDX-License-Identifier: MIT\n\npragma solidity ^0.8.0;\n\n/**\n * @dev Collection of functions related to the address type\n */\nlibrary Address {\n    /**\n     * @dev Returns true if `account` is a contract.\n     *\n     * [IMPORTANT]\n     * ====\n     * It is unsafe to assume that an address for which this function returns\n     * false is an externally-owned account (EOA) and not a contract.\n     *\n     * Among others, `isContract` will return false for the following\n     * types of addresses:\n     *\n     *  - an externally-owned account\n     *  - a contract in construction\n     *  - an address where a contract will be created\n     *  - an address where a contract lived, but was destroyed\n     * ====\n     */\n    function isContract(address account) internal view returns (bool) {\n        // This method relies on extcodesize, which returns 0 for contracts in\n        // construction, since the code is only stored at the end of the\n        // constructor execution.\n\n        uint256 size;\n        // solhint-disable-next-line no-inline-assembly\n        assembly {\n            size := extcodesize(account)\n        }\n        return size > 0;\n    }\n\n    /**\n     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to\n     * `recipient`, forwarding all available gas and reverting on errors.\n     *\n     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost\n     * of certain opcodes, possibly making contracts go over the 2300 gas limit\n     * imposed by `transfer`, making them unable to receive funds via\n     * `transfer`. {sendValue} removes this limitation.\n     *\n     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].\n     *\n     * IMPORTANT: because control is transferred to `recipient`, care must be\n     * taken to not create reentrancy vulnerabilities. Consider using\n     * {ReentrancyGuard} or the\n     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].\n     */\n    function sendValue(address payable recipient, uint256 amount) internal {\n        require(\n            address(this).balance >= amount,\n            \"Address: insufficient balance\"\n        );\n\n        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value\n        (bool success, ) = recipient.call{ value: amount }(\"\");\n        require(\n            success,\n            \"Address: unable to send value, recipient may have reverted\"\n        );\n    }\n\n    /**\n     * @dev Performs a Solidity function call using a low level `call`. A\n     * plain`call` is an unsafe replacement for a function call: use this\n     * function instead.\n     *\n     * If `target` reverts with a revert reason, it is bubbled up by this\n     * function (like regular Solidity function calls).\n     *\n     * Returns the raw returned data. To convert to the expected return value,\n     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].\n     *\n     * Requirements:\n     *\n     * - `target` must be a contract.\n     * - calling `target` with `data` must not revert.\n     *\n     * _Available since v3.1._\n     */\n    function functionCall(address target, bytes memory data)\n        internal\n        returns (bytes memory)\n    {\n        return functionCall(target, data, \"Address: low-level call failed\");\n    }\n\n    /**\n     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with\n     * `errorMessage` as a fallback revert reason when `target` reverts.\n     *\n     * _Available since v3.1._\n     */\n    function functionCall(\n        address target,\n        bytes memory data,\n        string memory errorMessage\n    ) internal returns (bytes memory) {\n        return functionCallWithValue(target, data, 0, errorMessage);\n    }\n\n    /**\n     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],\n     * but also transferring `value` wei to `target`.\n     *\n     * Requirements:\n     *\n     * - the calling contract must have an ETH balance of at least `value`.\n     * - the called Solidity function must be `payable`.\n     *\n     * _Available since v3.1._\n     */\n    function functionCallWithValue(\n        address target,\n        bytes memory data,\n        uint256 value\n    ) internal returns (bytes memory) {\n        return\n            functionCallWithValue(\n                target,\n                data,\n                value,\n                \"Address: low-level call with value failed\"\n            );\n    }\n\n    /**\n     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but\n     * with `errorMessage` as a fallback revert reason when `target` reverts.\n     *\n     * _Available since v3.1._\n     */\n    function functionCallWithValue(\n        address target,\n        bytes memory data,\n        uint256 value,\n        string memory errorMessage\n    ) internal returns (bytes memory) {\n        require(\n            address(this).balance >= value,\n            \"Address: insufficient balance for call\"\n        );\n        require(isContract(target), \"Address: call to non-contract\");\n\n        // solhint-disable-next-line avoid-low-level-calls\n        (bool success, bytes memory returndata) =\n            target.call{ value: value }(data);\n        return _verifyCallResult(success, returndata, errorMessage);\n    }\n\n    /**\n     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],\n     * but performing a static call.\n     *\n     * _Available since v3.3._\n     */\n    function functionStaticCall(address target, bytes memory data)\n        internal\n        view\n        returns (bytes memory)\n    {\n        return\n            functionStaticCall(\n                target,\n                data,\n                \"Address: low-level static call failed\"\n            );\n    }\n\n    /**\n     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],\n     * but performing a static call.\n     *\n     * _Available since v3.3._\n     */\n    function functionStaticCall(\n        address target,\n        bytes memory data,\n        string memory errorMessage\n    ) internal view returns (bytes memory) {\n        require(isContract(target), \"Address: static call to non-contract\");\n\n        // solhint-disable-next-line avoid-low-level-calls\n        (bool success, bytes memory returndata) = target.staticcall(data);\n        return _verifyCallResult(success, returndata, errorMessage);\n    }\n\n    /**\n     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],\n     * but performing a delegate call.\n     *\n     * _Available since v3.4._\n     */\n    function functionDelegateCall(address target, bytes memory data)\n        internal\n        returns (bytes memory)\n    {\n        return\n            functionDelegateCall(\n                target,\n                data,\n                \"Address: low-level delegate call failed\"\n            );\n    }\n\n    /**\n     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],\n     * but performing a delegate call.\n     *\n     * _Available since v3.4._\n     */\n    function functionDelegateCall(\n        address target,\n        bytes memory data,\n        string memory errorMessage\n    ) internal returns (bytes memory) {\n        require(isContract(target), \"Address: delegate call to non-contract\");\n\n        // solhint-disable-next-line avoid-low-level-calls\n        (bool success, bytes memory returndata) = target.delegatecall(data);\n        return _verifyCallResult(success, returndata, errorMessage);\n    }\n\n    function _verifyCallResult(\n        bool success,\n        bytes memory returndata,\n        string memory errorMessage\n    ) private pure returns (bytes memory) {\n        if (success) {\n            return returndata;\n        } else {\n            // Look for revert reason and bubble it up if present\n            if (returndata.length > 0) {\n                // The easiest way to bubble the revert reason is using memory via assembly\n\n                // solhint-disable-next-line no-inline-assembly\n                assembly {\n                    let returndata_size := mload(returndata)\n                    revert(add(32, returndata), returndata_size)\n                }\n            } else {\n                revert(errorMessage);\n            }\n        }\n    }\n}\n"
    },
    "contracts/oz/0.8.0/utils/Context.sol": {
      "content": "// SPDX-License-Identifier: MIT\n\npragma solidity ^0.8.0;\n\n/*\n * @dev Provides information about the current execution context, including the\n * sender of the transaction and its data. While these are generally available\n * via msg.sender and msg.data, they should not be accessed in such a direct\n * manner, since when dealing with meta-transactions the account sending and\n * paying for execution may not be the actual sender (as far as an application\n * is concerned).\n *\n * This contract is only required for intermediate, library-like contracts.\n */\nabstract contract Context {\n    function _msgSender() internal view virtual returns (address) {\n        return msg.sender;\n    }\n\n    function _msgData() internal view virtual returns (bytes calldata) {\n        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691\n        return msg.data;\n    }\n}\n"
    },
    "contracts/yEarn/yVault_ZapIn_V4.sol": {
      "content": "// ███████╗░█████╗░██████╗░██████╗░███████╗██████╗░░░░███████╗██╗\n// ╚════██║██╔══██╗██╔══██╗██╔══██╗██╔════╝██╔══██╗░░░██╔════╝██║\n// ░░███╔═╝███████║██████╔╝██████╔╝█████╗░░██████╔╝░░░█████╗░░██║\n// ██╔══╝░░██╔══██║██╔═══╝░██╔═══╝░██╔══╝░░██╔══██╗░░░██╔══╝░░██║\n// ███████╗██║░░██║██║░░░░░██║░░░░░███████╗██║░░██║██╗██║░░░░░██║\n// ╚══════╝╚═╝░░╚═╝╚═╝░░░░░╚═╝░░░░░╚══════╝╚═╝░░╚═╝╚═╝╚═╝░░░░░╚═╝\n// Copyright (C) 2021 zapper\n\n// This program is free software: you can redistribute it and/or modify\n// it under the terms of the GNU Affero General Public License as published by\n// the Free Software Foundation, either version 2 of the License, or\n// (at your option) any later version.\n//\n// This program is distributed in the hope that it will be useful,\n// but WITHOUT ANY WARRANTY; without even the implied warranty of\n// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the\n// GNU Affero General Public License for more details.\n//\n\n///@author Zapper\n///@notice This contract adds liquidity to Yearn Vaults using ETH or ERC20 Tokens.\n// SPDX-License-Identifier: GPL-2.0\n\npragma solidity ^0.8.0;\nimport \"../_base/ZapInBaseV3.sol\";\n\ninterface IWETH {\n    function deposit() external payable;\n\n    function transfer(address to, uint256 value) external returns (bool);\n\n    function withdraw(uint256) external;\n}\n\ninterface IYVault {\n    function deposit(uint256) external;\n\n    function withdraw(uint256) external;\n\n    function getPricePerFullShare() external view returns (uint256);\n\n    function token() external view returns (address);\n\n    // V2\n    function pricePerShare() external view returns (uint256);\n}\n\n// -- Aave --\ninterface IAaveLendingPoolAddressesProvider {\n    function getLendingPool() external view returns (address);\n\n    function getLendingPoolCore() external view returns (address payable);\n}\n\ninterface IAaveLendingPoolCore {\n    function getReserveATokenAddress(address _reserve)\n        external\n        view\n        returns (address);\n}\n\ninterface IAaveLendingPool {\n    function deposit(\n        address _reserve,\n        uint256 _amount,\n        uint16 _referralCode\n    ) external payable;\n}\n\ncontract yVault_ZapIn_V4 is ZapInBaseV3 {\n    using SafeERC20 for IERC20;\n\n    IAaveLendingPoolAddressesProvider\n        private constant lendingPoolAddressProvider =\n        IAaveLendingPoolAddressesProvider(\n            0x24a42fD28C976A61Df5D00D0599C34c4f90748c8\n        );\n\n    address private constant wethTokenAddress =\n        0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;\n\n    event zapIn(address sender, address pool, uint256 tokensRec);\n\n    constructor(\n        address _curveZapIn,\n        uint256 _goodwill,\n        uint256 _affiliateSplit\n    ) ZapBaseV2(_goodwill, _affiliateSplit) {\n        // Curve ZapIn\n        approvedTargets[_curveZapIn] = true;\n        // 0x exchange\n        approvedTargets[0xDef1C0ded9bec7F1a1670819833240f027b25EfF] = true;\n    }\n\n    /**\n        @notice This function adds liquidity to a Yearn vaults with ETH or ERC20 tokens\n        @param fromToken The token used for entry (address(0) if ether)\n        @param amountIn The amount of fromToken to invest\n        @param toVault Yearn vault address\n        @param superVault Super vault to depoist toVault tokens into (address(0) if none)\n        @param isAaveUnderlying True if vault contains aave token\n        @param minYVTokens The minimum acceptable quantity vault tokens to receive. Reverts otherwise\n        @param intermediateToken Token to swap fromToken to before entering vault\n        @param swapTarget Excecution target for the swap or Zap\n        @param swapData DEX quote or Zap data\n        @param affiliate Affiliate address\n        @param shouldSellEntireBalance If True transfers entrire allowable amount from another contract\n        @return tokensReceived Quantity of Vault tokens received\n     */\n    function ZapIn(\n        address fromToken,\n        uint256 amountIn,\n        address toVault,\n        address superVault,\n        bool isAaveUnderlying,\n        uint256 minYVTokens,\n        address intermediateToken,\n        address swapTarget,\n        bytes calldata swapData,\n        address affiliate,\n        bool shouldSellEntireBalance\n    ) external payable stopInEmergency returns (uint256 tokensReceived) {\n        // get incoming tokens\n        uint256 toInvest =\n            _pullTokens(\n                fromToken,\n                amountIn,\n                affiliate,\n                true,\n                shouldSellEntireBalance\n            );\n\n        // get intermediate token\n        uint256 intermediateAmt =\n            _fillQuote(\n                fromToken,\n                intermediateToken,\n                toInvest,\n                swapTarget,\n                swapData\n            );\n\n        // get 'aIntermediateToken'\n        if (isAaveUnderlying) {\n            address aaveLendingPoolCore =\n                lendingPoolAddressProvider.getLendingPoolCore();\n            _approveToken(intermediateToken, aaveLendingPoolCore);\n\n            IAaveLendingPool(lendingPoolAddressProvider.getLendingPool())\n                .deposit(intermediateToken, intermediateAmt, 0);\n\n            intermediateToken = IAaveLendingPoolCore(aaveLendingPoolCore)\n                .getReserveATokenAddress(intermediateToken);\n        }\n\n        return\n            _zapIn(\n                toVault,\n                superVault,\n                minYVTokens,\n                intermediateToken,\n                intermediateAmt\n            );\n    }\n\n    function _zapIn(\n        address toVault,\n        address superVault,\n        uint256 minYVTokens,\n        address intermediateToken,\n        uint256 intermediateAmt\n    ) internal returns (uint256 tokensReceived) {\n        // Deposit to Vault\n        if (superVault == address(0)) {\n            tokensReceived = _vaultDeposit(\n                intermediateToken,\n                intermediateAmt,\n                toVault,\n                minYVTokens,\n                true\n            );\n        } else {\n            uint256 intermediateYVTokens =\n                _vaultDeposit(\n                    intermediateToken,\n                    intermediateAmt,\n                    toVault,\n                    0,\n                    false\n                );\n            // deposit to super vault\n            tokensReceived = _vaultDeposit(\n                IYVault(superVault).token(),\n                intermediateYVTokens,\n                superVault,\n                minYVTokens,\n                true\n            );\n        }\n    }\n\n    function _vaultDeposit(\n        address underlyingVaultToken,\n        uint256 amount,\n        address toVault,\n        uint256 minTokensRec,\n        bool shouldTransfer\n    ) internal returns (uint256 tokensReceived) {\n        _approveToken(underlyingVaultToken, toVault);\n\n        uint256 iniYVaultBal = IERC20(toVault).balanceOf(address(this));\n        IYVault(toVault).deposit(amount);\n        tokensReceived =\n            IERC20(toVault).balanceOf(address(this)) -\n            iniYVaultBal;\n        require(tokensReceived >= minTokensRec, \"Err: High Slippage\");\n\n        if (shouldTransfer) {\n            IERC20(toVault).safeTransfer(msg.sender, tokensReceived);\n            emit zapIn(msg.sender, toVault, tokensReceived);\n        }\n    }\n\n    function _fillQuote(\n        address _fromTokenAddress,\n        address toToken,\n        uint256 _amount,\n        address _swapTarget,\n        bytes memory swapData\n    ) internal returns (uint256 amtBought) {\n        if (_fromTokenAddress == toToken) {\n            return _amount;\n        }\n\n        if (_fromTokenAddress == address(0) && toToken == wethTokenAddress) {\n            IWETH(wethTokenAddress).deposit{ value: _amount }();\n            return _amount;\n        }\n\n        uint256 valueToSend;\n        if (_fromTokenAddress == address(0)) {\n            valueToSend = _amount;\n        } else {\n            _approveToken(_fromTokenAddress, _swapTarget);\n        }\n\n        uint256 iniBal = _getBalance(toToken);\n        require(approvedTargets[_swapTarget], \"Target not Authorized\");\n        (bool success, ) = _swapTarget.call{ value: valueToSend }(swapData);\n        require(success, \"Error Swapping Tokens 1\");\n        uint256 finalBal = _getBalance(toToken);\n\n        amtBought = finalBal - iniBal;\n    }\n}\n"
    }
  }
}}