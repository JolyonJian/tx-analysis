{"Address.sol":{"content":"pragma solidity ^0.5.0;\n\n/**\n * @dev Collection of functions related to the address type,\n */\nlibrary Address {\n    /**\n     * @dev Returns true if `account` is a contract.\n     *\n     * This test is non-exhaustive, and there may be false-negatives: during the\n     * execution of a contract\u0027s constructor, its address will be reported as\n     * not containing a contract.\n     *\n     * \u003e It is unsafe to assume that an address for which this function returns\n     * false is an externally-owned account (EOA) and not a contract.\n     */\n    function isContract(address account) internal view returns (bool) {\n        // This method relies in extcodesize, which returns 0 for contracts in\n        // construction, since the code is only stored at the end of the\n        // constructor execution.\n\n        uint256 size;\n        // solhint-disable-next-line no-inline-assembly\n        assembly { size := extcodesize(account) }\n        return size \u003e 0;\n    }\n}\n"},"CarefulMath.sol":{"content":"pragma solidity \u003e=0.5.17;\n\n/**\n  * @title Careful Math\n  * @author Compound\n  * @notice Derived from OpenZeppelin\u0027s SafeMath library\n  *         https://github.com/OpenZeppelin/openzeppelin-solidity/blob/master/contracts/math/SafeMath.sol\n  */\ncontract CarefulMath {\n\n    /**\n     * @dev Possible error codes that we can return\n     */\n    enum MathError {\n        NO_ERROR,\n        DIVISION_BY_ZERO,\n        INTEGER_OVERFLOW,\n        INTEGER_UNDERFLOW\n    }\n\n    /**\n    * @dev Multiplies two numbers, returns an error on overflow.\n    */\n    function mulUInt(uint a, uint b) internal pure returns (MathError, uint) {\n        if (a == 0) {\n            return (MathError.NO_ERROR, 0);\n        }\n\n        uint c = a * b;\n\n        if (c / a != b) {\n            return (MathError.INTEGER_OVERFLOW, 0);\n        } else {\n            return (MathError.NO_ERROR, c);\n        }\n    }\n\n    /**\n    * @dev Integer division of two numbers, truncating the quotient.\n    */\n    function divUInt(uint a, uint b) internal pure returns (MathError, uint) {\n        if (b == 0) {\n            return (MathError.DIVISION_BY_ZERO, 0);\n        }\n\n        return (MathError.NO_ERROR, a / b);\n    }\n\n    /**\n    * @dev Subtracts two numbers, returns an error on overflow (i.e. if subtrahend is greater than minuend).\n    */\n    function subUInt(uint a, uint b) internal pure returns (MathError, uint) {\n        if (b \u003c= a) {\n            return (MathError.NO_ERROR, a - b);\n        } else {\n            return (MathError.INTEGER_UNDERFLOW, 0);\n        }\n    }\n\n    /**\n    * @dev Adds two numbers, returns an error on overflow.\n    */\n    function addUInt(uint a, uint b) internal pure returns (MathError, uint) {\n        uint c = a + b;\n\n        if (c \u003e= a) {\n            return (MathError.NO_ERROR, c);\n        } else {\n            return (MathError.INTEGER_OVERFLOW, 0);\n        }\n    }\n\n    /**\n    * @dev add a and b and then subtract c\n    */\n    function addThenSubUInt(uint a, uint b, uint c) internal pure returns (MathError, uint) {\n        (MathError err0, uint sum) = addUInt(a, b);\n\n        if (err0 != MathError.NO_ERROR) {\n            return (err0, 0);\n        }\n\n        return subUInt(sum, c);\n    }\n}\n"},"IERC20.sol":{"content":"pragma solidity ^0.5.0;\n\n/**\n * @dev Interface of the ERC20 standard as defined in the EIP. Does not include\n * the optional functions; to access them see `ERC20Detailed`.\n */\ninterface IERC20 {\n    /**\n     * @dev Returns the amount of tokens in existence.\n     */\n    function totalSupply() external view returns (uint256);\n\n    /**\n     * @dev Returns the amount of tokens owned by `account`.\n     */\n    function balanceOf(address account) external view returns (uint256);\n\n    /**\n     * @dev Moves `amount` tokens from the caller\u0027s account to `recipient`.\n     *\n     * Returns a boolean value indicating whether the operation succeeded.\n     *\n     * Emits a `Transfer` event.\n     */\n    function transfer(address recipient, uint256 amount) external returns (bool);\n\n    /**\n     * @dev Returns the remaining number of tokens that `spender` will be\n     * allowed to spend on behalf of `owner` through `transferFrom`. This is\n     * zero by default.\n     *\n     * This value changes when `approve` or `transferFrom` are called.\n     */\n    function allowance(address owner, address spender) external view returns (uint256);\n\n    /**\n     * @dev Sets `amount` as the allowance of `spender` over the caller\u0027s tokens.\n     *\n     * Returns a boolean value indicating whether the operation succeeded.\n     *\n     * \u003e Beware that changing an allowance with this method brings the risk\n     * that someone may use both the old and the new allowance by unfortunate\n     * transaction ordering. One possible solution to mitigate this race\n     * condition is to first reduce the spender\u0027s allowance to 0 and set the\n     * desired value afterwards:\n     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729\n     *\n     * Emits an `Approval` event.\n     */\n    function approve(address spender, uint256 amount) external returns (bool);\n\n    /**\n     * @dev Moves `amount` tokens from `sender` to `recipient` using the\n     * allowance mechanism. `amount` is then deducted from the caller\u0027s\n     * allowance.\n     *\n     * Returns a boolean value indicating whether the operation succeeded.\n     *\n     * Emits a `Transfer` event.\n     */\n    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);\n\n    /**\n     * @dev Emitted when `value` tokens are moved from one account (`from`) to\n     * another (`to`).\n     *\n     * Note that `value` may be zero.\n     */\n    event Transfer(address indexed from, address indexed to, uint256 value);\n\n    /**\n     * @dev Emitted when the allowance of a `spender` for an `owner` is set by\n     * a call to `approve`. `value` is the new allowance.\n     */\n    event Approval(address indexed owner, address indexed spender, uint256 value);\n}\n"},"ISablier.sol":{"content":"pragma solidity \u003e=0.5.17;\n\n/**\n * @title ISablier\n * @author Sablier\n */\ninterface ISablier {\n    /**\n     * @notice Emits when a stream is successfully created.\n     */\n    event CreateStream(\n        uint256 indexed streamId,\n        address indexed sender,\n        address indexed recipient,\n        uint256 deposit,\n        address tokenAddress,\n        uint256 startTime,\n        uint256 stopTime\n    );\n\n    /**\n     * @notice Emits when the recipient of a stream withdraws a portion or all their pro rata share of the stream.\n     */\n    event WithdrawFromStream(uint256 indexed streamId, address indexed recipient, uint256 amount);\n\n    /**\n     * @notice Emits when a stream is successfully cancelled and tokens are transferred back on a pro rata basis.\n     */\n    event CancelStream(\n        uint256 indexed streamId,\n        address indexed sender,\n        address indexed recipient,\n        uint256 senderBalance,\n        uint256 recipientBalance\n    );\n\n    function balanceOf(uint256 streamId, address who) external view returns (uint256 balance);\n\n    function getStream(uint256 streamId)\n        external\n        view\n        returns (\n            address sender,\n            address recipient,\n            uint256 deposit,\n            address token,\n            uint256 startTime,\n            uint256 stopTime,\n            uint256 remainingBalance,\n            uint256 ratePerSecond\n        );\n\n    function createStream(address recipient, uint256 deposit, address tokenAddress, uint256 startTime, uint256 stopTime)\n        external\n        returns (uint256 streamId);\n\n    function withdrawFromStream(uint256 streamId, uint256 funds) external returns (bool);\n\n    function cancelStream(uint256 streamId) external returns (bool);\n}\n"},"ReentrancyGuard.sol":{"content":"pragma solidity ^0.5.0;\n\n/**\n * @dev Contract module that helps prevent reentrant calls to a function.\n *\n * Inheriting from `ReentrancyGuard` will make the `nonReentrant` modifier\n * available, which can be aplied to functions to make sure there are no nested\n * (reentrant) calls to them.\n *\n * Note that because there is a single `nonReentrant` guard, functions marked as\n * `nonReentrant` may not call one another. This can be worked around by making\n * those functions `private`, and then adding `external` `nonReentrant` entry\n * points to them.\n */\ncontract ReentrancyGuard {\n    /// @dev counter to allow mutex lock with only one SSTORE operation\n    uint256 private _guardCounter;\n\n    constructor () internal {\n        // The counter starts at one to prevent changing it from zero to a non-zero\n        // value, which is a more expensive operation.\n        _guardCounter = 1;\n    }\n\n    /**\n     * @dev Prevents a contract from calling itself, directly or indirectly.\n     * Calling a `nonReentrant` function from another `nonReentrant`\n     * function is not supported. It is possible to prevent this from happening\n     * by making the `nonReentrant` function external, and make it call a\n     * `private` function that does the actual work.\n     */\n    modifier nonReentrant() {\n        _guardCounter += 1;\n        uint256 localCounter = _guardCounter;\n        _;\n        require(localCounter == _guardCounter, \"ReentrancyGuard: reentrant call\");\n    }\n}\n"},"Sablier.sol":{"content":"pragma solidity =0.5.17;\n\nimport \"./IERC20.sol\";\nimport \"./SafeERC20.sol\";\nimport \"./ReentrancyGuard.sol\";\nimport \"./CarefulMath.sol\";\n\nimport \"./ISablier.sol\";\nimport \"./Types.sol\";\n\n/**\n * @title Sablier\n * @author Sablier\n * @notice Money streaming.\n */\ncontract Sablier is ISablier, ReentrancyGuard, CarefulMath {\n    using SafeERC20 for IERC20;\n\n    /*** Storage Properties ***/\n\n    /**\n     * @notice Counter for new stream ids.\n     */\n    uint256 public nextStreamId;\n\n    /**\n     * @notice The stream objects identifiable by their unsigned integer ids.\n     */\n    mapping(uint256 =\u003e Types.Stream) private streams;\n\n    /*** Modifiers ***/\n\n    /**\n     * @dev Throws if the caller is not the sender of the recipient of the stream.\n     */\n    modifier onlySenderOrRecipient(uint256 streamId) {\n        require(\n            msg.sender == streams[streamId].sender || msg.sender == streams[streamId].recipient,\n            \"caller is not the sender or the recipient of the stream\"\n        );\n        _;\n    }\n\n    /**\n     * @dev Throws if the provided id does not point to a valid stream.\n     */\n    modifier streamExists(uint256 streamId) {\n        require(streams[streamId].isEntity, \"stream does not exist\");\n        _;\n    }\n\n    /*** Contract Logic Starts Here */\n\n    constructor() public {\n        nextStreamId = 100000;\n    }\n\n    /*** View Functions ***/\n\n    /**\n     * @notice Returns the stream with all its properties.\n     * @dev Throws if the id does not point to a valid stream.\n     * @param streamId The id of the stream to query.\n     * @return The stream object.\n     */\n    function getStream(uint256 streamId)\n        external\n        view\n        streamExists(streamId)\n        returns (\n            address sender,\n            address recipient,\n            uint256 deposit,\n            address tokenAddress,\n            uint256 startTime,\n            uint256 stopTime,\n            uint256 remainingBalance,\n            uint256 ratePerSecond\n        )\n    {\n        sender = streams[streamId].sender;\n        recipient = streams[streamId].recipient;\n        deposit = streams[streamId].deposit;\n        tokenAddress = streams[streamId].tokenAddress;\n        startTime = streams[streamId].startTime;\n        stopTime = streams[streamId].stopTime;\n        remainingBalance = streams[streamId].remainingBalance;\n        ratePerSecond = streams[streamId].ratePerSecond;\n    }\n\n    /**\n     * @notice Returns either the delta in seconds between `block.timestamp` and `startTime` or\n     *  between `stopTime` and `startTime, whichever is smaller. If `block.timestamp` is before\n     *  `startTime`, it returns 0.\n     * @dev Throws if the id does not point to a valid stream.\n     * @param streamId The id of the stream for which to query the delta.\n     * @return The time delta in seconds.\n     */\n    function deltaOf(uint256 streamId) public view streamExists(streamId) returns (uint256 delta) {\n        Types.Stream memory stream = streams[streamId];\n        if (block.timestamp \u003c= stream.startTime) return 0;\n        if (block.timestamp \u003c stream.stopTime) return block.timestamp - stream.startTime;\n        return stream.stopTime - stream.startTime;\n    }\n\n    struct BalanceOfLocalVars {\n        MathError mathErr;\n        uint256 recipientBalance;\n        uint256 withdrawalAmount;\n        uint256 senderBalance;\n    }\n\n    /**\n     * @notice Returns the available funds for the given stream id and address.\n     * @dev Throws if the id does not point to a valid stream.\n     * @param streamId The id of the stream for which to query the balance.\n     * @param who The address for which to query the balance.\n     * @return The total funds allocated to `who` as uint256.\n     */\n    function balanceOf(uint256 streamId, address who) public view streamExists(streamId) returns (uint256 balance) {\n        Types.Stream memory stream = streams[streamId];\n        BalanceOfLocalVars memory vars;\n\n        uint256 delta = deltaOf(streamId);\n        (vars.mathErr, vars.recipientBalance) = mulUInt(delta, stream.ratePerSecond);\n        require(vars.mathErr == MathError.NO_ERROR, \"recipient balance calculation error\");\n\n        /*\n         * If the stream `balance` does not equal `deposit`, it means there have been withdrawals.\n         * We have to subtract the total amount withdrawn from the amount of money that has been\n         * streamed until now.\n         */\n        if (stream.deposit \u003e stream.remainingBalance) {\n            (vars.mathErr, vars.withdrawalAmount) = subUInt(stream.deposit, stream.remainingBalance);\n            assert(vars.mathErr == MathError.NO_ERROR);\n            (vars.mathErr, vars.recipientBalance) = subUInt(vars.recipientBalance, vars.withdrawalAmount);\n            /* `withdrawalAmount` cannot and should not be bigger than `recipientBalance`. */\n            assert(vars.mathErr == MathError.NO_ERROR);\n        }\n\n        if (who == stream.recipient) return vars.recipientBalance;\n        if (who == stream.sender) {\n            (vars.mathErr, vars.senderBalance) = subUInt(stream.remainingBalance, vars.recipientBalance);\n            /* `recipientBalance` cannot and should not be bigger than `remainingBalance`. */\n            assert(vars.mathErr == MathError.NO_ERROR);\n            return vars.senderBalance;\n        }\n        return 0;\n    }\n\n    /*** Public Effects \u0026 Interactions Functions ***/\n\n    struct CreateStreamLocalVars {\n        MathError mathErr;\n        uint256 duration;\n        uint256 ratePerSecond;\n    }\n\n    /**\n     * @notice Creates a new stream funded by `msg.sender` and paid towards `recipient`.\n     * @dev Throws if the recipient is the zero address, the contract itself or the caller.\n     *  Throws if the deposit is 0.\n     *  Throws if the start time is before `block.timestamp`.\n     *  Throws if the stop time is before the start time.\n     *  Throws if the duration calculation has a math error.\n     *  Throws if the deposit is smaller than the duration.\n     *  Throws if the deposit is not a multiple of the duration.\n     *  Throws if the rate calculation has a math error.\n     *  Throws if the next stream id calculation has a math error.\n     *  Throws if the contract is not allowed to transfer enough tokens.\n     *  Throws if there is a token transfer failure.\n     * @param recipient The address towards which the money is streamed.\n     * @param deposit The amount of money to be streamed.\n     * @param tokenAddress The ERC20 token to use as streaming currency.\n     * @param startTime The unix timestamp for when the stream starts.\n     * @param stopTime The unix timestamp for when the stream stops.\n     * @return The uint256 id of the newly created stream.\n     */\n    function createStream(address recipient, uint256 deposit, address tokenAddress, uint256 startTime, uint256 stopTime)\n        public\n        returns (uint256)\n    {\n        require(recipient != address(0x00), \"stream to the zero address\");\n        require(recipient != address(this), \"stream to the contract itself\");\n        require(recipient != msg.sender, \"stream to the caller\");\n        require(deposit \u003e 0, \"deposit is zero\");\n        require(startTime \u003e= block.timestamp, \"start time before block.timestamp\");\n        require(stopTime \u003e startTime, \"stop time before the start time\");\n\n        CreateStreamLocalVars memory vars;\n        (vars.mathErr, vars.duration) = subUInt(stopTime, startTime);\n        /* `subUInt` can only return MathError.INTEGER_UNDERFLOW but we know `stopTime` is higher than `startTime`. */\n        assert(vars.mathErr == MathError.NO_ERROR);\n\n        /* Without this, the rate per second would be zero. */\n        require(deposit \u003e= vars.duration, \"deposit smaller than time delta\");\n\n        /* This condition avoids dealing with remainders */\n        require(deposit % vars.duration == 0, \"deposit not multiple of time delta\");\n\n        (vars.mathErr, vars.ratePerSecond) = divUInt(deposit, vars.duration);\n        /* `divUInt` can only return MathError.DIVISION_BY_ZERO but we know `duration` is not zero. */\n        assert(vars.mathErr == MathError.NO_ERROR);\n\n        /* Create and store the stream object. */\n        uint256 streamId = nextStreamId;\n        streams[streamId] = Types.Stream({\n            remainingBalance: deposit,\n            deposit: deposit,\n            isEntity: true,\n            ratePerSecond: vars.ratePerSecond,\n            recipient: recipient,\n            sender: msg.sender,\n            startTime: startTime,\n            stopTime: stopTime,\n            tokenAddress: tokenAddress\n        });\n\n        /* Increment the next stream id. */\n        (vars.mathErr, nextStreamId) = addUInt(nextStreamId, uint256(1));\n        require(vars.mathErr == MathError.NO_ERROR, \"next stream id calculation error\");\n\n        IERC20(tokenAddress).safeTransferFrom(msg.sender, address(this), deposit);\n        emit CreateStream(streamId, msg.sender, recipient, deposit, tokenAddress, startTime, stopTime);\n        return streamId;\n    }\n\n    /**\n     * @notice Withdraws from the contract to the recipient\u0027s account.\n     * @dev Throws if the id does not point to a valid stream.\n     *  Throws if the caller is not the sender or the recipient of the stream.\n     *  Throws if the amount exceeds the available balance.\n     *  Throws if there is a token transfer failure.\n     * @param streamId The id of the stream to withdraw tokens from.\n     * @param amount The amount of tokens to withdraw.\n     */\n    function withdrawFromStream(uint256 streamId, uint256 amount)\n        external\n        nonReentrant\n        streamExists(streamId)\n        onlySenderOrRecipient(streamId)\n        returns (bool)\n    {\n        require(amount \u003e 0, \"amount is zero\");\n        Types.Stream memory stream = streams[streamId];\n\n        uint256 balance = balanceOf(streamId, stream.recipient);\n        require(balance \u003e= amount, \"amount exceeds the available balance\");\n\n        MathError mathErr;\n        (mathErr, streams[streamId].remainingBalance) = subUInt(stream.remainingBalance, amount);\n        /**\n         * `subUInt` can only return MathError.INTEGER_UNDERFLOW but we know that `remainingBalance` is at least\n         * as big as `amount`.\n         */\n        assert(mathErr == MathError.NO_ERROR);\n\n        if (streams[streamId].remainingBalance == 0) delete streams[streamId];\n\n        IERC20(stream.tokenAddress).safeTransfer(stream.recipient, amount);\n        emit WithdrawFromStream(streamId, stream.recipient, amount);\n        return true;\n    }\n\n    /**\n     * @notice Cancels the stream and transfers the tokens back on a pro rata basis.\n     * @dev Throws if the id does not point to a valid stream.\n     *  Throws if the caller is not the sender or the recipient of the stream.\n     *  Throws if there is a token transfer failure.\n     * @param streamId The id of the stream to cancel.\n     * @return bool true=success, otherwise false.\n     */\n    function cancelStream(uint256 streamId)\n        external\n        nonReentrant\n        streamExists(streamId)\n        onlySenderOrRecipient(streamId)\n        returns (bool)\n    {\n        Types.Stream memory stream = streams[streamId];\n        uint256 senderBalance = balanceOf(streamId, stream.sender);\n        uint256 recipientBalance = balanceOf(streamId, stream.recipient);\n\n        delete streams[streamId];\n\n        IERC20 token = IERC20(stream.tokenAddress);\n        if (recipientBalance \u003e 0) token.safeTransfer(stream.recipient, recipientBalance);\n        if (senderBalance \u003e 0) token.safeTransfer(stream.sender, senderBalance);\n\n        emit CancelStream(streamId, stream.sender, stream.recipient, senderBalance, recipientBalance);\n        return true;\n    }\n}\n"},"SafeERC20.sol":{"content":"pragma solidity ^0.5.0;\n\nimport \"./IERC20.sol\";\nimport \"./SafeMath.sol\";\nimport \"./Address.sol\";\n\n/**\n * @title SafeERC20\n * @dev Wrappers around ERC20 operations that throw on failure (when the token\n * contract returns false). Tokens that return no value (and instead revert or\n * throw on failure) are also supported, non-reverting calls are assumed to be\n * successful.\n * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,\n * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.\n */\nlibrary SafeERC20 {\n    using SafeMath for uint256;\n    using Address for address;\n\n    function safeTransfer(IERC20 token, address to, uint256 value) internal {\n        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));\n    }\n\n    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {\n        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));\n    }\n\n    function safeApprove(IERC20 token, address spender, uint256 value) internal {\n        // safeApprove should only be called when setting an initial allowance,\n        // or when resetting it to zero. To increase and decrease it, use\n        // \u0027safeIncreaseAllowance\u0027 and \u0027safeDecreaseAllowance\u0027\n        // solhint-disable-next-line max-line-length\n        require((value == 0) || (token.allowance(address(this), spender) == 0),\n            \"SafeERC20: approve from non-zero to non-zero allowance\"\n        );\n        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));\n    }\n\n    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {\n        uint256 newAllowance = token.allowance(address(this), spender).add(value);\n        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));\n    }\n\n    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {\n        uint256 newAllowance = token.allowance(address(this), spender).sub(value);\n        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));\n    }\n\n    /**\n     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement\n     * on the return value: the return value is optional (but if data is returned, it must not be false).\n     * @param token The token targeted by the call.\n     * @param data The call data (encoded using abi.encode or one of its variants).\n     */\n    function callOptionalReturn(IERC20 token, bytes memory data) private {\n        // We need to perform a low level call here, to bypass Solidity\u0027s return data size checking mechanism, since\n        // we\u0027re implementing it ourselves.\n\n        // A Solidity high level call has three parts:\n        //  1. The target address is checked to verify it contains contract code\n        //  2. The call itself is made, and success asserted\n        //  3. The return value is decoded, which in turn checks the size of the returned data.\n        // solhint-disable-next-line max-line-length\n        require(address(token).isContract(), \"SafeERC20: call to non-contract\");\n\n        // solhint-disable-next-line avoid-low-level-calls\n        (bool success, bytes memory returndata) = address(token).call(data);\n        require(success, \"SafeERC20: low-level call failed\");\n\n        if (returndata.length \u003e 0) { // Return data is optional\n            // solhint-disable-next-line max-line-length\n            require(abi.decode(returndata, (bool)), \"SafeERC20: ERC20 operation did not succeed\");\n        }\n    }\n}\n"},"SafeMath.sol":{"content":"pragma solidity ^0.5.0;\n\n/**\n * @dev Wrappers over Solidity\u0027s arithmetic operations with added overflow\n * checks.\n *\n * Arithmetic operations in Solidity wrap on overflow. This can easily result\n * in bugs, because programmers usually assume that an overflow raises an\n * error, which is the standard behavior in high level programming languages.\n * `SafeMath` restores this intuition by reverting the transaction when an\n * operation overflows.\n *\n * Using this library instead of the unchecked operations eliminates an entire\n * class of bugs, so it\u0027s recommended to use it always.\n */\nlibrary SafeMath {\n    /**\n     * @dev Returns the addition of two unsigned integers, reverting on\n     * overflow.\n     *\n     * Counterpart to Solidity\u0027s `+` operator.\n     *\n     * Requirements:\n     * - Addition cannot overflow.\n     */\n    function add(uint256 a, uint256 b) internal pure returns (uint256) {\n        uint256 c = a + b;\n        require(c \u003e= a, \"SafeMath: addition overflow\");\n\n        return c;\n    }\n\n    /**\n     * @dev Returns the subtraction of two unsigned integers, reverting on\n     * overflow (when the result is negative).\n     *\n     * Counterpart to Solidity\u0027s `-` operator.\n     *\n     * Requirements:\n     * - Subtraction cannot overflow.\n     */\n    function sub(uint256 a, uint256 b) internal pure returns (uint256) {\n        require(b \u003c= a, \"SafeMath: subtraction overflow\");\n        uint256 c = a - b;\n\n        return c;\n    }\n\n    /**\n     * @dev Returns the multiplication of two unsigned integers, reverting on\n     * overflow.\n     *\n     * Counterpart to Solidity\u0027s `*` operator.\n     *\n     * Requirements:\n     * - Multiplication cannot overflow.\n     */\n    function mul(uint256 a, uint256 b) internal pure returns (uint256) {\n        // Gas optimization: this is cheaper than requiring \u0027a\u0027 not being zero, but the\n        // benefit is lost if \u0027b\u0027 is also tested.\n        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522\n        if (a == 0) {\n            return 0;\n        }\n\n        uint256 c = a * b;\n        require(c / a == b, \"SafeMath: multiplication overflow\");\n\n        return c;\n    }\n\n    /**\n     * @dev Returns the integer division of two unsigned integers. Reverts on\n     * division by zero. The result is rounded towards zero.\n     *\n     * Counterpart to Solidity\u0027s `/` operator. Note: this function uses a\n     * `revert` opcode (which leaves remaining gas untouched) while Solidity\n     * uses an invalid opcode to revert (consuming all remaining gas).\n     *\n     * Requirements:\n     * - The divisor cannot be zero.\n     */\n    function div(uint256 a, uint256 b) internal pure returns (uint256) {\n        // Solidity only automatically asserts when dividing by 0\n        require(b \u003e 0, \"SafeMath: division by zero\");\n        uint256 c = a / b;\n        // assert(a == b * c + a % b); // There is no case in which this doesn\u0027t hold\n\n        return c;\n    }\n\n    /**\n     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),\n     * Reverts when dividing by zero.\n     *\n     * Counterpart to Solidity\u0027s `%` operator. This function uses a `revert`\n     * opcode (which leaves remaining gas untouched) while Solidity uses an\n     * invalid opcode to revert (consuming all remaining gas).\n     *\n     * Requirements:\n     * - The divisor cannot be zero.\n     */\n    function mod(uint256 a, uint256 b) internal pure returns (uint256) {\n        require(b != 0, \"SafeMath: modulo by zero\");\n        return a % b;\n    }\n}\n"},"Types.sol":{"content":"pragma solidity =0.5.17;\n\n/**\n * @title Sablier Types\n * @author Sablier\n */\nlibrary Types {\n    struct Stream {\n        uint256 deposit;\n        uint256 ratePerSecond;\n        uint256 remainingBalance;\n        uint256 startTime;\n        uint256 stopTime;\n        address recipient;\n        address sender;\n        address tokenAddress;\n        bool isEntity;\n    }\n}\n"}}