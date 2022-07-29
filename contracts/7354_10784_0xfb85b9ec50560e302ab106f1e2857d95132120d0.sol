{{
  "language": "Solidity",
  "sources": {
    "/Users/js/Downloads/NFT_Marketplace/farming_contracts/contracts/SDAOTokenStaking.sol": {
      "content": "// SPDX-License-Identifier: MIT\npragma solidity 0.6.12;\npragma experimental ABIEncoderV2;\n\nimport \"./libraries/BoringMath.sol\";\nimport \"./libraries/SignedSafeMath.sol\";\nimport \"./libraries/BoringERC20.sol\";\nimport \"@openzeppelin/contracts/access/Ownable.sol\";\nimport \"@openzeppelin/contracts/utils/ReentrancyGuard.sol\";\n/************************************************************************************************\nOriginally from\nhttps://github.com/sushiswap/sushiswap/blob/master/contracts/MasterChefV2.sol\nand\nhttps://github.com/sdaoswap/sushiswap/blob/master/contracts/MasterChef.sol\nThis source code has been modified from the original, which was copied from the github repository\nat commit hash 10148a31d9192bc803dac5d24fe0319b52ae99a4.\n*************************************************************************************************/\n\n\ncontract SDAOTokenStaking is Ownable,ReentrancyGuard {\n  using BoringMath for uint256;\n  using BoringERC20 for IERC20;\n  using SignedSafeMath for int256;\n\n  //==========  Structs  ==========\n  \n  /// @dev Info of each user.\n  /// @param amount LP token amount the user has provided.\n  /// @param rewardDebt The amount of rewards entitled to the user.\n  struct UserInfo {\n    uint256 amount;\n    int256 rewardDebt;\n  }\n\n\n  /// @dev Info of each rewards pool.\n  /// @param tokenPerBlock Reward tokens per block number.\n  /// @param lpSupply Total staked amount.\n  /// @param accRewardsPerShare Total rewards accumulated per staked token.\n  /// @param lastRewardBlock Last time rewards were updated for the pool.\n  /// @param endOfEpochBlock End of epoc block number for compute and to avoid deposits.\n  struct PoolInfo {\n    uint256 tokenPerBlock;\n    uint256 lpSupply;\n    uint256 accRewardsPerShare;\n    uint256 lastRewardBlock;\n    uint256 endOfEpochBlock;\n  }\n\n  //==========  Constants  ==========\n\n  /// @dev For percision calculation while computing the rewards.\n  uint256 private constant ACC_REWARDS_PRECISION = 1e18;\n\n  /// @dev ERC20 token used to distribute rewards.   \n  IERC20 public immutable rewardsToken;\n\n  /** ==========  Storage  ========== */\n\n  /// @dev Indicates whether a staking pool exists for a given staking token.\n  //mapping(address => bool) public stakingPoolExists;\n  \n  /// @dev Info of each staking pool.\n  PoolInfo[] public poolInfo;\n  \n  /// @dev Address of the LP token for each staking pool.\n  mapping(uint256 => IERC20) public lpToken;\n  \n  /// @dev Info of each user that stakes tokens.\n  mapping(uint256 => mapping(address => UserInfo)) public userInfo;\n\n  /// @dev Total rewards received from governance for distribution.\n  /// Used to return remaining rewards if staking is canceled.\n  uint256 public totalRewardsReceived;\n\n  // ==========  Events  ==========\n\n  event Deposit(address indexed user, uint256 indexed pid, uint256 amount, address indexed to);\n  event Withdraw(address indexed user, uint256 indexed pid, uint256 amount, address indexed to);\n  event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount, address indexed to);\n  event Harvest(address indexed user, uint256 indexed pid, uint256 amount);\n  event LogPoolAddition(uint256 indexed pid, IERC20 indexed lpToken);\n  event LogUpdatePool(uint256 indexed pid, uint256 lastRewardBlock, uint256 lpSupply, uint256 accRewardsPerShare);\n  event RewardsAdded(uint256 amount);\n  event ExtendPool(uint256 indexed pid, uint256 rewardBlock, uint256 endOfEpochBlock);\n\n  // ==========  Constructor  ==========\n\n  /// @dev During the deployment of the contract pass the ERC-20 contract address used for rewards.\n  constructor(address _rewardsToken) public {\n    rewardsToken = IERC20(_rewardsToken);\n  }\n\n  /// @dev Add rewards to be distributed.\n  /// Note: This function must be used to add rewards if the owner\n  /// wants to retain the option to cancel distribution and reclaim\n  /// undistributed tokens.  \n  function addRewards(uint256 amount) external onlyOwner {\n    \n    require(rewardsToken.balanceOf(msg.sender) > 0, \"ERC20: not enough tokens to transfer\");\n\n    totalRewardsReceived = totalRewardsReceived.add(amount);\n    rewardsToken.safeTransferFrom(msg.sender, address(this), amount);\n    \n    emit RewardsAdded(amount);\n  }\n\n  // ==========  Pools  ==========\n  \n  /// @dev Add a new LP to the pool.\n  /// Can only be called by the owner or the points allocator.\n  /// @param _lpToken Address of the LP ERC-20 token.\n  /// @param _sdaoPerBlock Rewards per block.\n  /// @param _endOfEpochBlock Epocs end block number.\n  function add(IERC20 _lpToken, uint256 _sdaoPerBlock, uint256 _endOfEpochBlock) public onlyOwner {\n\n    //This is not needed as we are going to use the contract for multiple pools with the same LP Tokens\n    //require(!stakingPoolExists[address(_lpToken)], \" Staking pool already exists.\");\n    \n    require(_endOfEpochBlock > block.number, \"Cannot create the pool for past time.\");\n\n    uint256 pid = poolInfo.length;\n\n    lpToken[pid] = _lpToken;\n\n    poolInfo.push(PoolInfo({\n      tokenPerBlock: _sdaoPerBlock,\n      endOfEpochBlock:_endOfEpochBlock,\n      lastRewardBlock: block.number,\n      lpSupply:0,\n      accRewardsPerShare: 0\n    }));\n\n    //stakingPoolExists[address(_lpToken)] = true;\n\n    emit LogPoolAddition(pid, _lpToken);\n  }\n\n  /// @dev Add a new LP to the pool.\n  /// Can only be called by the owner or the points allocator.\n  /// @param _pid Pool Id to extend the schedule.\n  /// @param _sdaoPerBlock Rewards per block.\n  /// @param _endOfEpochBlock Epocs end block number.\n  function extendPool(uint256 _pid, uint256 _sdaoPerBlock, uint256 _endOfEpochBlock) public onlyOwner {\n    \n    require(_endOfEpochBlock > block.number && _endOfEpochBlock > poolInfo[_pid].endOfEpochBlock, \"Cannot extend the pool for past time.\");\n\n    // Update the accumulated rewards\n    PoolInfo memory pool = updatePool(_pid);\n\n    pool.tokenPerBlock = _sdaoPerBlock;\n    pool.endOfEpochBlock = _endOfEpochBlock;\n    pool.lastRewardBlock = block.number;\n\n    // Update the Pool Storage\n    poolInfo[_pid] = pool;\n\n    emit ExtendPool(_pid, _sdaoPerBlock, _endOfEpochBlock);\n  }\n\n  /// @dev To get the rewards per block.\n  function sdaoPerBlock(uint256 _pid) public view returns (uint256 amount) {\n      PoolInfo memory pool = poolInfo[_pid];\n      amount = pool.tokenPerBlock;\n  }\n\n  /// @dev Update reward variables for all pools in `pids`.\n  /// Note: This can become very expensive.\n  /// @param pids Pool IDs of all to be updated. Make sure to update all active pools.\n  function massUpdatePools(uint256[] calldata pids) external onlyOwner {\n    uint256 len = pids.length;\n    for (uint256 i = 0; i < len; ++i) {\n      updatePool(pids[i]);\n    }\n  }\n\n\n  /// @dev Update reward variables of the given pool.\n  /// @param _pid The index of the pool. See `poolInfo`.\n  /// @return pool Returns the pool that was updated.\n function updatePool(uint256 _pid) private returns (PoolInfo memory pool) {\n\n    pool = poolInfo[_pid];\n    uint256 lpSupply = pool.lpSupply;\n\n    if (block.number > pool.lastRewardBlock && pool.lastRewardBlock < pool.endOfEpochBlock) {\n\n       if(lpSupply > 0){\n         \n           uint256 blocks;\n           if(block.number < pool.endOfEpochBlock) {\n             blocks = block.number.sub(pool.lastRewardBlock);\n           } else {\n             blocks = pool.endOfEpochBlock.sub(pool.lastRewardBlock);\n          }\n\n          uint256 sdaoReward = blocks.mul(sdaoPerBlock(_pid));\n          pool.accRewardsPerShare = pool.accRewardsPerShare.add((sdaoReward.mul(ACC_REWARDS_PRECISION) / lpSupply));\n\n       }\n\n       pool.lastRewardBlock = block.number;\n       poolInfo[_pid] = pool;\n       emit LogUpdatePool(_pid, pool.lastRewardBlock, lpSupply, pool.accRewardsPerShare);\n\n    }\n\n  }\n\n\n\n  // ==========  Users  ==========\n\n  /// @dev View function to see pending rewards on frontend.\n  /// @param _pid The index of the pool. See `poolInfo`.\n  /// @param _user Address of user.\n  /// @return pending rewards for a given user.\n  function pendingRewards(uint256 _pid, address _user) external view returns (uint256 pending) {\n\n    PoolInfo memory pool = poolInfo[_pid];\n    UserInfo storage user = userInfo[_pid][_user];\n\n    uint256 accRewardsPerShare = pool.accRewardsPerShare;\n    uint256 lpSupply = pool.lpSupply;\n\n    if (block.number > pool.lastRewardBlock && pool.lastRewardBlock < pool.endOfEpochBlock) {\n\n      if(lpSupply > 0){\n\n        uint256 blocks;\n\n        if(block.number < pool.endOfEpochBlock) {\n            blocks = block.number.sub(pool.lastRewardBlock);\n        } else {\n          blocks = pool.endOfEpochBlock.sub(pool.lastRewardBlock);\n        }\n        \n        uint256 sdaoReward = blocks.mul(sdaoPerBlock(_pid));\n        accRewardsPerShare = accRewardsPerShare.add(sdaoReward.mul(ACC_REWARDS_PRECISION) / lpSupply);\n\n      }\n\n    }\n\n    pending = int256(user.amount.mul(accRewardsPerShare) / ACC_REWARDS_PRECISION).sub(user.rewardDebt).toUInt256();\n  }\n\n\n  /// @dev Deposit LP tokens to earn rewards.\n  /// @param _pid The index of the pool. See `poolInfo`.\n  /// @param _amount LP token amount to deposit.\n  /// @param _to The receiver of `_amount` deposit benefit.\n  function deposit(uint256 _pid, uint256 _amount, address _to) external nonReentrant {\n\n    // Input Validation\n    require(_amount > 0 && _to != address(0), \"Invalid inputs for deposit.\");\n\n    PoolInfo memory pool = updatePool(_pid);\n    UserInfo storage user = userInfo[_pid][_to];\n\n    // check if epoch as ended or if pool doesnot exist \n    require (pool.endOfEpochBlock > block.number,\"This pool epoch has ended. Please join staking new session.\");\n    \n    user.amount = user.amount.add(_amount);\n    user.rewardDebt = user.rewardDebt.add(int256(_amount.mul(pool.accRewardsPerShare) / ACC_REWARDS_PRECISION));\n\n    // Add to total supply\n    pool.lpSupply = pool.lpSupply.add(_amount);\n    // Update the pool back\n    poolInfo[_pid] = pool;\n\n    // Interactions\n    lpToken[_pid].safeTransferFrom(msg.sender, address(this), _amount);\n\n    emit Deposit(msg.sender, _pid, _amount, _to);\n  }\n\n  /// @dev Withdraw LP tokens from the staking contract.\n  /// @param _pid The index of the pool. See `poolInfo`.\n  /// @param _amount LP token amount to withdraw.\n  /// @param _to Receiver of the LP tokens.\n  function withdraw(uint256 _pid, uint256 _amount, address _to) external nonReentrant {\n\n    require(_to != address(0), \"ERC20: transfer to the zero address\");\n\n    PoolInfo memory pool = updatePool(_pid);\n    UserInfo storage user = userInfo[_pid][msg.sender];\n\n    // Check whether user has deposited stake\n    require(user.amount >= _amount && _amount > 0, \"Invalid amount to withdraw.\");\n\n    // Effects\n    user.rewardDebt = user.rewardDebt.sub(int256(_amount.mul(pool.accRewardsPerShare) / ACC_REWARDS_PRECISION));\n    user.amount = user.amount.sub(_amount);\n\n    // Subtract from total supply\n    pool.lpSupply = pool.lpSupply.sub(_amount);\n    // Update the pool back\n    poolInfo[_pid] = pool;\n\n    // Interactions\n    lpToken[_pid].safeTransfer(_to, _amount);\n\n    emit Withdraw(msg.sender, _pid, _amount, _to);\n  }\n\n\n   /// @dev Harvest proceeds for transaction sender to `_to`.\n   /// @param _pid The index of the pool. See `poolInfo`.\n   /// @param _to Receiver of rewards.\n   function harvest(uint256 _pid, address _to) external nonReentrant {\n    \n    require(_to != address(0), \"ERC20: transfer to the zero address\");\n\n    PoolInfo memory pool = updatePool(_pid);\n    UserInfo storage user = userInfo[_pid][msg.sender];\n\n    int256 accumulatedRewards = int256(user.amount.mul(pool.accRewardsPerShare) / ACC_REWARDS_PRECISION);\n    uint256 _pendingRewards = accumulatedRewards.sub(user.rewardDebt).toUInt256();\n\n    // Effects\n    user.rewardDebt = accumulatedRewards;\n\n    // Interactions\n    if(_pendingRewards > 0 ) {\n      rewardsToken.safeTransfer(_to, _pendingRewards);\n    }\n    \n    emit Harvest(msg.sender, _pid, _pendingRewards);\n  }\n\n  //// @dev Withdraw LP tokens and harvest accumulated rewards, sending both to `to`.\n  /// @param _pid The index of the pool. See `poolInfo`.\n  /// @param _amount LP token amount to withdraw.\n  /// @param _to Receiver of the LP tokens and rewards.\n  function withdrawAndHarvest(uint256 _pid, uint256 _amount, address _to) external nonReentrant {\n\n    require(_to != address(0), \"ERC20: transfer to the zero address\");\n\n    PoolInfo memory pool = updatePool(_pid);\n    UserInfo storage user = userInfo[_pid][msg.sender];\n\n    // Check if the user has stake in the pool\n    require(user.amount >= _amount && _amount > 0, \"Cannot withdraw more than staked.\");\n\n    int256 accumulatedRewards = int256(user.amount.mul(pool.accRewardsPerShare) / ACC_REWARDS_PRECISION);\n    uint256 _pendingRewards = accumulatedRewards.sub(user.rewardDebt).toUInt256();\n\n    // Effects\n    user.rewardDebt = accumulatedRewards.sub(int256(_amount.mul(pool.accRewardsPerShare) / ACC_REWARDS_PRECISION));\n    user.amount = user.amount.sub(_amount);\n\n    // Subtract from total supply\n    pool.lpSupply = pool.lpSupply.sub(_amount);\n    // Update the pool back\n    poolInfo[_pid] = pool;\n\n    // Interactions\n    if(_pendingRewards > 0) {\n      rewardsToken.safeTransfer(_to, _pendingRewards);\n    }\n    lpToken[_pid].safeTransfer(_to, _amount);\n\n    emit Harvest(msg.sender, _pid, _pendingRewards);\n    emit Withdraw(msg.sender, _pid, _amount, _to);\n  }\n\n\n  /// @dev Withdraw without caring about rewards. EMERGENCY ONLY.\n  /// @param _pid The index of the pool. See `poolInfo`.\n  /// @param _to Receiver of the LP tokens.  \n  function emergencyWithdraw(uint256 _pid, address _to) external nonReentrant { \n\n    require(_to != address(0), \"ERC20: transfer to the zero address\");\n\n    UserInfo storage user = userInfo[_pid][msg.sender];\n    uint256 amount = user.amount;\n    user.amount = 0;\n    user.rewardDebt = 0;\n\n    PoolInfo memory pool = updatePool(_pid);\n    pool.lpSupply = pool.lpSupply.sub(amount);\n    // Update the pool back\n    poolInfo[_pid] = pool;\n\n    // Note: transfer can fail or succeed if `amount` is zero.\n    lpToken[_pid].safeTransfer(_to, amount);\n\n    emit EmergencyWithdraw(msg.sender, _pid, amount, _to);\n  }\n\n\n  function withdrawETHAndAnyTokens(address token) external onlyOwner {\n    msg.sender.send(address(this).balance);\n    IERC20 Token = IERC20(token);\n    uint256 currentTokenBalance = Token.balanceOf(address(this));\n    Token.safeTransfer(msg.sender, currentTokenBalance); \n  }\n\n  // ==========  Getter Functions  ==========\n\n  function poolLength() external view returns (uint256) {\n    return poolInfo.length;\n  }\n\n\n\n}"
    },
    "/Users/js/Downloads/NFT_Marketplace/farming_contracts/contracts/interfaces/IERC20.sol": {
      "content": "// SPDX-License-Identifier: MIT\npragma solidity 0.6.12;\n\ninterface IERC20 {\n    function totalSupply() external view returns (uint256);\n\n    function balanceOf(address account) external view returns (uint256);\n\n    function allowance(address owner, address spender) external view returns (uint256);\n\n    function approve(address spender, uint256 amount) external returns (bool);\n\n    event Transfer(address indexed from, address indexed to, uint256 value);\n    event Approval(address indexed owner, address indexed spender, uint256 value);\n\n    /// @notice EIP 2612\n    function permit(\n        address owner,\n        address spender,\n        uint256 value,\n        uint256 deadline,\n        uint8 v,\n        bytes32 r,\n        bytes32 s\n    ) external;\n}"
    },
    "/Users/js/Downloads/NFT_Marketplace/farming_contracts/contracts/libraries/BoringERC20.sol": {
      "content": "// SPDX-License-Identifier: MIT\npragma solidity 0.6.12;\nimport \"../interfaces/IERC20.sol\";\n\n// solhint-disable avoid-low-level-calls\n\nlibrary BoringERC20 {\n    bytes4 private constant SIG_SYMBOL = 0x95d89b41; // symbol()\n    bytes4 private constant SIG_NAME = 0x06fdde03; // name()\n    bytes4 private constant SIG_DECIMALS = 0x313ce567; // decimals()\n    bytes4 private constant SIG_TRANSFER = 0xa9059cbb; // transfer(address,uint256)\n    bytes4 private constant SIG_TRANSFER_FROM = 0x23b872dd; // transferFrom(address,address,uint256)\n\n    function returnDataToString(bytes memory data) internal pure returns (string memory) {\n        if (data.length >= 64) {\n            return abi.decode(data, (string));\n        } else if (data.length == 32) {\n            uint8 i = 0;\n            while(i < 32 && data[i] != 0) {\n                i++;\n            }\n            bytes memory bytesArray = new bytes(i);\n            for (i = 0; i < 32 && data[i] != 0; i++) {\n                bytesArray[i] = data[i];\n            }\n            return string(bytesArray);\n        } else {\n            return \"???\";\n        }\n    }\n\n    /// @notice Provides a safe ERC20.symbol version which returns '???' as fallback string.\n    /// @param token The address of the ERC-20 token contract.\n    /// @return (string) Token symbol.\n    function safeSymbol(IERC20 token) internal view returns (string memory) {\n        (bool success, bytes memory data) = address(token).staticcall(abi.encodeWithSelector(SIG_SYMBOL));\n        return success ? returnDataToString(data) : \"???\";\n    }\n\n    /// @notice Provides a safe ERC20.name version which returns '???' as fallback string.\n    /// @param token The address of the ERC-20 token contract.\n    /// @return (string) Token name.\n    function safeName(IERC20 token) internal view returns (string memory) {\n        (bool success, bytes memory data) = address(token).staticcall(abi.encodeWithSelector(SIG_NAME));\n        return success ? returnDataToString(data) : \"???\";\n    }\n\n    /// @notice Provides a safe ERC20.decimals version which returns '18' as fallback value.\n    /// @param token The address of the ERC-20 token contract.\n    /// @return (uint8) Token decimals.\n    function safeDecimals(IERC20 token) internal view returns (uint8) {\n        (bool success, bytes memory data) = address(token).staticcall(abi.encodeWithSelector(SIG_DECIMALS));\n        return success && data.length == 32 ? abi.decode(data, (uint8)) : 18;\n    }\n\n    /// @notice Provides a safe ERC20.transfer version for different ERC-20 implementations.\n    /// Reverts on a failed transfer.\n    /// @param token The address of the ERC-20 token.\n    /// @param to Transfer tokens to.\n    /// @param amount The token amount.\n    function safeTransfer(\n        IERC20 token,\n        address to,\n        uint256 amount\n    ) internal {\n        (bool success, bytes memory data) = address(token).call(abi.encodeWithSelector(SIG_TRANSFER, to, amount));\n        require(success && (data.length == 0 || abi.decode(data, (bool))), \"BoringERC20: Transfer failed\");\n    }\n\n    /// @notice Provides a safe ERC20.transferFrom version for different ERC-20 implementations.\n    /// Reverts on a failed transfer.\n    /// @param token The address of the ERC-20 token.\n    /// @param from Transfer tokens from.\n    /// @param to Transfer tokens to.\n    /// @param amount The token amount.\n    function safeTransferFrom(\n        IERC20 token,\n        address from,\n        address to,\n        uint256 amount\n    ) internal {\n        (bool success, bytes memory data) = address(token).call(abi.encodeWithSelector(SIG_TRANSFER_FROM, from, to, amount));\n        require(success && (data.length == 0 || abi.decode(data, (bool))), \"BoringERC20: TransferFrom failed\");\n    }\n}"
    },
    "/Users/js/Downloads/NFT_Marketplace/farming_contracts/contracts/libraries/BoringMath.sol": {
      "content": "// SPDX-License-Identifier: MIT\npragma solidity 0.6.12;\n\n/// @notice A library for performing overflow-/underflow-safe math,\n/// updated with awesomeness from of DappHub (https://github.com/dapphub/ds-math).\nlibrary BoringMath {\n    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {\n        require((c = a + b) >= b, \"BoringMath: Add Overflow\");\n    }\n\n    function sub(uint256 a, uint256 b) internal pure returns (uint256 c) {\n        require((c = a - b) <= a, \"BoringMath: Underflow\");\n    }\n\n    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {\n        require(b == 0 || (c = a * b) / b == a, \"BoringMath: Mul Overflow\");\n    }\n\n    function to128(uint256 a) internal pure returns (uint128 c) {\n        require(a <= uint128(-1), \"BoringMath: uint128 Overflow\");\n        c = uint128(a);\n    }\n\n    function to64(uint256 a) internal pure returns (uint64 c) {\n        require(a <= uint64(-1), \"BoringMath: uint64 Overflow\");\n        c = uint64(a);\n    }\n\n    function to32(uint256 a) internal pure returns (uint32 c) {\n        require(a <= uint32(-1), \"BoringMath: uint32 Overflow\");\n        c = uint32(a);\n    }\n}\n\n/// @notice A library for performing overflow-/underflow-safe addition and subtraction on uint128.\nlibrary BoringMath128 {\n    function add(uint128 a, uint128 b) internal pure returns (uint128 c) {\n        require((c = a + b) >= b, \"BoringMath: Add Overflow\");\n    }\n\n    function sub(uint128 a, uint128 b) internal pure returns (uint128 c) {\n        require((c = a - b) <= a, \"BoringMath: Underflow\");\n    }\n}\n\n/// @notice A library for performing overflow-/underflow-safe addition and subtraction on uint64.\nlibrary BoringMath64 {\n    function add(uint64 a, uint64 b) internal pure returns (uint64 c) {\n        require((c = a + b) >= b, \"BoringMath: Add Overflow\");\n    }\n\n    function sub(uint64 a, uint64 b) internal pure returns (uint64 c) {\n        require((c = a - b) <= a, \"BoringMath: Underflow\");\n    }\n}\n\n/// @notice A library for performing overflow-/underflow-safe addition and subtraction on uint32.\nlibrary BoringMath32 {\n    function add(uint32 a, uint32 b) internal pure returns (uint32 c) {\n        require((c = a + b) >= b, \"BoringMath: Add Overflow\");\n    }\n\n    function sub(uint32 a, uint32 b) internal pure returns (uint32 c) {\n        require((c = a - b) <= a, \"BoringMath: Underflow\");\n    }\n}"
    },
    "/Users/js/Downloads/NFT_Marketplace/farming_contracts/contracts/libraries/SignedSafeMath.sol": {
      "content": "// SPDX-License-Identifier: MIT\npragma solidity 0.6.12;\n\nlibrary SignedSafeMath {\n  int256 constant private _INT256_MIN = -2**255;\n\n  /**\n    * @dev Returns the multiplication of two signed integers, reverting on\n    * overflow.\n    *\n    * Counterpart to Solidity's `*` operator.\n    *\n    * Requirements:\n    *\n    * - Multiplication cannot overflow.\n    */\n  function mul(int256 a, int256 b) internal pure returns (int256) {\n    // Gas optimization: this is cheaper than requiring 'a' not being zero, but the\n    // benefit is lost if 'b' is also tested.\n    // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522\n    if (a == 0) {\n      return 0;\n    }\n\n    require(!(a == -1 && b == _INT256_MIN), \"SignedSafeMath: multiplication overflow\");\n\n    int256 c = a * b;\n    require(c / a == b, \"SignedSafeMath: multiplication overflow\");\n\n    return c;\n  }\n\n  /**\n    * @dev Returns the integer division of two signed integers. Reverts on\n    * division by zero. The result is rounded towards zero.\n    *\n    * Counterpart to Solidity's `/` operator. Note: this function uses a\n    * `revert` opcode (which leaves remaining gas untouched) while Solidity\n    * uses an invalid opcode to revert (consuming all remaining gas).\n    *\n    * Requirements:\n    *\n    * - The divisor cannot be zero.\n    */\n  function div(int256 a, int256 b) internal pure returns (int256) {\n    require(b != 0, \"SignedSafeMath: division by zero\");\n    require(!(b == -1 && a == _INT256_MIN), \"SignedSafeMath: division overflow\");\n\n    int256 c = a / b;\n\n    return c;\n  }\n\n  /**\n    * @dev Returns the subtraction of two signed integers, reverting on\n    * overflow.\n    *\n    * Counterpart to Solidity's `-` operator.\n    *\n    * Requirements:\n    *\n    * - Subtraction cannot overflow.\n    */\n  function sub(int256 a, int256 b) internal pure returns (int256) {\n    int256 c = a - b;\n    require((b >= 0 && c <= a) || (b < 0 && c > a), \"SignedSafeMath: subtraction overflow\");\n\n    return c;\n  }\n\n  /**\n    * @dev Returns the addition of two signed integers, reverting on\n    * overflow.\n    *\n    * Counterpart to Solidity's `+` operator.\n    *\n    * Requirements:\n    *\n    * - Addition cannot overflow.\n    */\n  function add(int256 a, int256 b) internal pure returns (int256) {\n    int256 c = a + b;\n    require((b >= 0 && c >= a) || (b < 0 && c < a), \"SignedSafeMath: addition overflow\");\n\n    return c;\n  }\n\n  function toUInt256(int256 a) internal pure returns (uint256) {\n    require(a >= 0, \"Integer < 0\");\n    return uint256(a);\n  }\n}"
    },
    "@openzeppelin/contracts/GSN/Context.sol": {
      "content": "// SPDX-License-Identifier: MIT\n\npragma solidity ^0.6.0;\n\n/*\n * @dev Provides information about the current execution context, including the\n * sender of the transaction and its data. While these are generally available\n * via msg.sender and msg.data, they should not be accessed in such a direct\n * manner, since when dealing with GSN meta-transactions the account sending and\n * paying for execution may not be the actual sender (as far as an application\n * is concerned).\n *\n * This contract is only required for intermediate, library-like contracts.\n */\nabstract contract Context {\n    function _msgSender() internal view virtual returns (address payable) {\n        return msg.sender;\n    }\n\n    function _msgData() internal view virtual returns (bytes memory) {\n        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691\n        return msg.data;\n    }\n}\n"
    },
    "@openzeppelin/contracts/access/Ownable.sol": {
      "content": "// SPDX-License-Identifier: MIT\n\npragma solidity ^0.6.0;\n\nimport \"../GSN/Context.sol\";\n/**\n * @dev Contract module which provides a basic access control mechanism, where\n * there is an account (an owner) that can be granted exclusive access to\n * specific functions.\n *\n * By default, the owner account will be the one that deploys the contract. This\n * can later be changed with {transferOwnership}.\n *\n * This module is used through inheritance. It will make available the modifier\n * `onlyOwner`, which can be applied to your functions to restrict their use to\n * the owner.\n */\ncontract Ownable is Context {\n    address private _owner;\n\n    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);\n\n    /**\n     * @dev Initializes the contract setting the deployer as the initial owner.\n     */\n    constructor () internal {\n        address msgSender = _msgSender();\n        _owner = msgSender;\n        emit OwnershipTransferred(address(0), msgSender);\n    }\n\n    /**\n     * @dev Returns the address of the current owner.\n     */\n    function owner() public view returns (address) {\n        return _owner;\n    }\n\n    /**\n     * @dev Throws if called by any account other than the owner.\n     */\n    modifier onlyOwner() {\n        require(_owner == _msgSender(), \"Ownable: caller is not the owner\");\n        _;\n    }\n\n    /**\n     * @dev Leaves the contract without owner. It will not be possible to call\n     * `onlyOwner` functions anymore. Can only be called by the current owner.\n     *\n     * NOTE: Renouncing ownership will leave the contract without an owner,\n     * thereby removing any functionality that is only available to the owner.\n     */\n    function renounceOwnership() public virtual onlyOwner {\n        emit OwnershipTransferred(_owner, address(0));\n        _owner = address(0);\n    }\n\n    /**\n     * @dev Transfers ownership of the contract to a new account (`newOwner`).\n     * Can only be called by the current owner.\n     */\n    function transferOwnership(address newOwner) public virtual onlyOwner {\n        require(newOwner != address(0), \"Ownable: new owner is the zero address\");\n        emit OwnershipTransferred(_owner, newOwner);\n        _owner = newOwner;\n    }\n}\n"
    },
    "@openzeppelin/contracts/utils/ReentrancyGuard.sol": {
      "content": "// SPDX-License-Identifier: MIT\n\npragma solidity ^0.6.0;\n\n/**\n * @dev Contract module that helps prevent reentrant calls to a function.\n *\n * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier\n * available, which can be applied to functions to make sure there are no nested\n * (reentrant) calls to them.\n *\n * Note that because there is a single `nonReentrant` guard, functions marked as\n * `nonReentrant` may not call one another. This can be worked around by making\n * those functions `private`, and then adding `external` `nonReentrant` entry\n * points to them.\n *\n * TIP: If you would like to learn more about reentrancy and alternative ways\n * to protect against it, check out our blog post\n * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].\n */\ncontract ReentrancyGuard {\n    // Booleans are more expensive than uint256 or any type that takes up a full\n    // word because each write operation emits an extra SLOAD to first read the\n    // slot's contents, replace the bits taken up by the boolean, and then write\n    // back. This is the compiler's defense against contract upgrades and\n    // pointer aliasing, and it cannot be disabled.\n\n    // The values being non-zero value makes deployment a bit more expensive,\n    // but in exchange the refund on every call to nonReentrant will be lower in\n    // amount. Since refunds are capped to a percentage of the total\n    // transaction's gas, it is best to keep them low in cases like this one, to\n    // increase the likelihood of the full refund coming into effect.\n    uint256 private constant _NOT_ENTERED = 1;\n    uint256 private constant _ENTERED = 2;\n\n    uint256 private _status;\n\n    constructor () internal {\n        _status = _NOT_ENTERED;\n    }\n\n    /**\n     * @dev Prevents a contract from calling itself, directly or indirectly.\n     * Calling a `nonReentrant` function from another `nonReentrant`\n     * function is not supported. It is possible to prevent this from happening\n     * by making the `nonReentrant` function external, and make it call a\n     * `private` function that does the actual work.\n     */\n    modifier nonReentrant() {\n        // On the first call to nonReentrant, _notEntered will be true\n        require(_status != _ENTERED, \"ReentrancyGuard: reentrant call\");\n\n        // Any calls to nonReentrant after this point will fail\n        _status = _ENTERED;\n\n        _;\n\n        // By storing the original value once again, a refund is triggered (see\n        // https://eips.ethereum.org/EIPS/eip-2200)\n        _status = _NOT_ENTERED;\n    }\n}\n"
    }
  },
  "settings": {
    "remappings": [],
    "optimizer": {
      "enabled": true,
      "runs": 200
    },
    "evmVersion": "istanbul",
    "libraries": {},
    "outputSelection": {
      "*": {
        "*": [
          "evm.bytecode",
          "evm.deployedBytecode",
          "abi"
        ]
      }
    }
  }
}}