{{
  "language": "Solidity",
  "sources": {
    "contracts/dependencies/open-zeppelin/SafeMath.sol": {
      "content": "// SPDX-License-Identifier: MIT\npragma solidity 0.7.5;\n\n/**\n * @dev Wrappers over Solidity's arithmetic operations with added overflow\n * checks.\n *\n * Arithmetic operations in Solidity wrap on overflow. This can easily result\n * in bugs, because programmers usually assume that an overflow raises an\n * error, which is the standard behavior in high level programming languages.\n * `SafeMath` restores this intuition by reverting the transaction when an\n * operation overflows.\n *\n * Using this library instead of the unchecked operations eliminates an entire\n * class of bugs, so it's recommended to use it always.\n */\nlibrary SafeMath {\n  /**\n   * @dev Returns the addition of two unsigned integers, reverting on\n   * overflow.\n   *\n   * Counterpart to Solidity's `+` operator.\n   *\n   * Requirements:\n   * - Addition cannot overflow.\n   */\n  function add(uint256 a, uint256 b) internal pure returns (uint256) {\n    uint256 c = a + b;\n    require(c >= a, 'SafeMath: addition overflow');\n\n    return c;\n  }\n\n  /**\n   * @dev Returns the subtraction of two unsigned integers, reverting on\n   * overflow (when the result is negative).\n   *\n   * Counterpart to Solidity's `-` operator.\n   *\n   * Requirements:\n   * - Subtraction cannot overflow.\n   */\n  function sub(uint256 a, uint256 b) internal pure returns (uint256) {\n    return sub(a, b, 'SafeMath: subtraction overflow');\n  }\n\n  /**\n   * @dev Returns the subtraction of two unsigned integers, reverting with custom message on\n   * overflow (when the result is negative).\n   *\n   * Counterpart to Solidity's `-` operator.\n   *\n   * Requirements:\n   * - Subtraction cannot overflow.\n   */\n  function sub(\n    uint256 a,\n    uint256 b,\n    string memory errorMessage\n  ) internal pure returns (uint256) {\n    require(b <= a, errorMessage);\n    uint256 c = a - b;\n\n    return c;\n  }\n\n  /**\n   * @dev Returns the multiplication of two unsigned integers, reverting on\n   * overflow.\n   *\n   * Counterpart to Solidity's `*` operator.\n   *\n   * Requirements:\n   * - Multiplication cannot overflow.\n   */\n  function mul(uint256 a, uint256 b) internal pure returns (uint256) {\n    // Gas optimization: this is cheaper than requiring 'a' not being zero, but the\n    // benefit is lost if 'b' is also tested.\n    // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522\n    if (a == 0) {\n      return 0;\n    }\n\n    uint256 c = a * b;\n    require(c / a == b, 'SafeMath: multiplication overflow');\n\n    return c;\n  }\n\n  /**\n   * @dev Returns the integer division of two unsigned integers. Reverts on\n   * division by zero. The result is rounded towards zero.\n   *\n   * Counterpart to Solidity's `/` operator. Note: this function uses a\n   * `revert` opcode (which leaves remaining gas untouched) while Solidity\n   * uses an invalid opcode to revert (consuming all remaining gas).\n   *\n   * Requirements:\n   * - The divisor cannot be zero.\n   */\n  function div(uint256 a, uint256 b) internal pure returns (uint256) {\n    return div(a, b, 'SafeMath: division by zero');\n  }\n\n  /**\n   * @dev Returns the integer division of two unsigned integers. Reverts with custom message on\n   * division by zero. The result is rounded towards zero.\n   *\n   * Counterpart to Solidity's `/` operator. Note: this function uses a\n   * `revert` opcode (which leaves remaining gas untouched) while Solidity\n   * uses an invalid opcode to revert (consuming all remaining gas).\n   *\n   * Requirements:\n   * - The divisor cannot be zero.\n   */\n  function div(\n    uint256 a,\n    uint256 b,\n    string memory errorMessage\n  ) internal pure returns (uint256) {\n    // Solidity only automatically asserts when dividing by 0\n    require(b > 0, errorMessage);\n    uint256 c = a / b;\n    // assert(a == b * c + a % b); // There is no case in which this doesn't hold\n\n    return c;\n  }\n\n  /**\n   * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),\n   * Reverts when dividing by zero.\n   *\n   * Counterpart to Solidity's `%` operator. This function uses a `revert`\n   * opcode (which leaves remaining gas untouched) while Solidity uses an\n   * invalid opcode to revert (consuming all remaining gas).\n   *\n   * Requirements:\n   * - The divisor cannot be zero.\n   */\n  function mod(uint256 a, uint256 b) internal pure returns (uint256) {\n    return mod(a, b, 'SafeMath: modulo by zero');\n  }\n\n  /**\n   * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),\n   * Reverts with custom message when dividing by zero.\n   *\n   * Counterpart to Solidity's `%` operator. This function uses a `revert`\n   * opcode (which leaves remaining gas untouched) while Solidity uses an\n   * invalid opcode to revert (consuming all remaining gas).\n   *\n   * Requirements:\n   * - The divisor cannot be zero.\n   */\n  function mod(\n    uint256 a,\n    uint256 b,\n    string memory errorMessage\n  ) internal pure returns (uint256) {\n    require(b != 0, errorMessage);\n    return a % b;\n  }\n}\n"
    },
    "contracts/misc/ClaimsProxy.sol": {
      "content": "// SPDX-License-Identifier: Apache-2.0\n// Contracts by dYdX Foundation. Individual files are released under different licenses.\n//\n// https://dydx.community\n// https://github.com/dydxfoundation/governance-contracts\n\n\npragma solidity 0.7.5;\npragma experimental ABIEncoderV2;\n\nimport { SafeMath } from '../dependencies/open-zeppelin/SafeMath.sol';\n\ninterface ISafetyModuleV1 {\n  function claimRewardsFor(\n    address staker,\n    address recipient\n  )\n    external\n    returns (uint256);\n}\n\ninterface ILiquidityStakingV1 {\n  function claimRewardsFor(\n    address staker,\n    address recipient\n  )\n    external\n    returns (uint256);\n}\n\ninterface IMerkleDistributorV1 {\n  function claimRewardsFor(\n    address user,\n    uint256 cumulativeAmount,\n    bytes32[] calldata merkleProof\n  )\n    external\n    returns (uint256);\n}\n\ninterface ITreasuryVester {\n  function claim() external;\n}\n\n/**\n * @title ClaimsProxy\n * @author dYdX\n *\n * @notice Contract which claims DYDX rewards from multiple contracts on behalf of a user.\n *\n *  Requires the following permissions:\n *    - Set as the CLAIMS_PROXY on the SafetyModuleV1 contract.\n *    - Has role CLAIM_OPERATOR_ROLE on the LiquidityStakingV1 contract.\n *    - Has role CLAIM_OPERATOR_ROLE on the MerkleDistributorV1 contract.\n */\ncontract ClaimsProxy {\n  using SafeMath for uint256;\n\n  // ============ Constants ============\n\n  ISafetyModuleV1 public immutable SAFETY_MODULE;\n  ILiquidityStakingV1 public immutable LIQUIDITY_STAKING;\n  IMerkleDistributorV1 public immutable MERKLE_DISTRIBUTOR;\n  ITreasuryVester public immutable REWARDS_TREASURY_VESTER;\n\n  // ============ Constructor ============\n\n  constructor(\n    ISafetyModuleV1 safetyModule,\n    ILiquidityStakingV1 liquidityStaking,\n    IMerkleDistributorV1 merkleDistributor,\n    ITreasuryVester rewardsTreasuryVester\n  ) {\n    SAFETY_MODULE = safetyModule;\n    LIQUIDITY_STAKING = liquidityStaking;\n    MERKLE_DISTRIBUTOR = merkleDistributor;\n    REWARDS_TREASURY_VESTER = rewardsTreasuryVester;\n  }\n\n  // ============ External Functions ============\n\n  /**\n   * @notice Claim rewards from zero or more rewards contracts. All rewards are sent directly to\n   *  the sender's address.\n   *\n   * @param  claimSafetyRewards       Whether or not to claim rewards from SafetyModuleV1.\n   * @param  claimLiquidityRewards    Whether or not to claim rewards from LiquidityStakingV1.\n   * @param  merkleCumulativeAmount   The cumulative rewards amount for the user in the\n   *                                  MerkleDistributorV1 rewards Merkle tree, or zero to skip\n   *                                  claiming from this contract.\n   * @param  merkleProof              The Merkle proof for the user's cumulative rewards.\n   * @param  vestFromTreasuryVester   Whether or not to vest rewards from the rewards treasury\n   *                                  vester to the rewards treasury (e.g. set to true if rewards\n   *                                  treasury has insufficient funds for users, and false otherwise).\n   *\n   * @return The total number of rewards claimed.\n   */\n  function claimRewards(\n    bool claimSafetyRewards,\n    bool claimLiquidityRewards,\n    uint256 merkleCumulativeAmount,\n    bytes32[] calldata merkleProof,\n    bool vestFromTreasuryVester\n  )\n    external\n    returns (uint256)\n  {\n    if (vestFromTreasuryVester) {\n      // call rewards treasury vester so that rewards treasury has sufficient rewards\n      REWARDS_TREASURY_VESTER.claim();\n    }\n\n    address user = msg.sender;\n\n    uint256 amount1 = 0;\n    uint256 amount2 = 0;\n    uint256 amount3 = 0;\n\n    if (claimSafetyRewards) {\n      amount1 = SAFETY_MODULE.claimRewardsFor(user, user);\n    }\n    if (claimLiquidityRewards) {\n      amount2 = LIQUIDITY_STAKING.claimRewardsFor(user, user);\n    }\n    if (merkleCumulativeAmount != 0) {\n      amount3 = MERKLE_DISTRIBUTOR.claimRewardsFor(user, merkleCumulativeAmount, merkleProof);\n    }\n\n    return amount1.add(amount2).add(amount3);\n  }\n}\n"
    }
  },
  "settings": {
    "optimizer": {
      "enabled": true,
      "runs": 200
    },
    "evmVersion": "istanbul",
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