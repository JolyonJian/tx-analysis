{"BMPToken.sol":{"content":"pragma solidity ^0.4.24;\nimport \"./ERC20Detailed.sol\";\nimport \"./ERC20Burnable.sol\";\nimport \"./Stopable.sol\";\n\n/// @author \n/// @title Token contract\ncontract BMPToken is ERC20Detailed, ERC20Burnable, Stoppable {\n\n    constructor (\n            string memory name,\n            string memory symbol,\n            uint256 totalSupply,\n            uint8 decimals\n    ) ERC20Detailed(name, symbol, decimals)\n    public {\n        _mint(owner(), totalSupply * 10**uint(decimals));\n    }\n\n    // Don\u0027t accept ETH\n    function () payable external {\n        revert();\n    }\n    \n    //------------------------\n    // Lock account transfer \n\n    mapping (address =\u003e uint256) private _lockTimes;\n    mapping (address =\u003e uint256) private _lockAmounts;\n\n    event LockChanged(address indexed account, uint256 releaseTime, uint256 amount);\n\n    /// Lock user amount.  (run only owner)\n    /// @param account account to lock\n    /// @param releaseTime Time to release from lock state.\n    /// @param amount  amount to lock.\n    /// @return Boolean\n    function setLock(address account, uint256 releaseTime, uint256 amount) onlyOwner public {\n        //require(now \u003c releaseTime, \"ERC20 : Current time is greater than release time\");\n        require(block.timestamp \u003c releaseTime, \"ERC20 : Current time is greater than release time\");\n        require(amount != 0, \"ERC20: Amount error\");\n        _lockTimes[account] = releaseTime; \n        _lockAmounts[account] = amount;\n        emit LockChanged( account, releaseTime, amount ); \n    }\n\n    /// Get Lock information  (run anyone)\n    /// @param account user acount\n    /// @return lokced time and locked amount.\n    function getLock(address account) public view returns (uint256 lockTime, uint256 lockAmount) {\n        return (_lockTimes[account], _lockAmounts[account]);\n    }\n\n    /// Check lock state  (run anyone)\n    /// @param account user acount\n    /// @param amount amount to check.\n    /// @return Boolean : Don\u0027t use balance (true)\n    function _isLocked(address account, uint256 amount) internal view returns (bool) {\n        return _lockAmounts[account] != 0 \u0026\u0026 \n            _lockTimes[account] \u003e block.timestamp \u0026\u0026\n            (\n                balanceOf(account) \u003c= _lockAmounts[account] ||\n                balanceOf(account).sub(_lockAmounts[account]) \u003c amount\n            );\n    }\n\n    /// Transfer token  (run anyone)\n    /// @param recipient Token trasfer destination acount.\n    /// @param amount Token transfer amount.\n    /// @return Boolean \n    function transfer(address recipient, uint256 amount) enabled public returns (bool) {\n        require( !_isLocked( msg.sender, amount ) , \"ERC20: Locked balance\");\n        return super.transfer(recipient, amount);\n    }\n\n    /// Transfer token  (run anyone)\n    /// @param sender Token trasfer source acount.\n    /// @param recipient Token transfer destination acount.\n    /// @param amount Token transfer amount.\n    /// @return Boolean \n    function transferFrom(address sender, address recipient, uint256 amount) enabled public returns (bool) {\n        require( !_isLocked( sender, amount ) , \"ERC20: Locked balance\");\n        return super.transferFrom(sender, recipient, amount);\n    }\n\n    /// Decrease token balance (run only owner)\n    /// @param value Amount to decrease.\n    function burn(uint256 value) onlyOwner public {\n        require( !_isLocked( msg.sender, value ) , \"ERC20: Locked balance\");\n        super.burn(value);\n    }\n}"},"ERC20.sol":{"content":"pragma solidity ^0.4.24;\n\nimport \"./IERC20.sol\";\nimport \"./SafeMath.sol\";\n\n/**\n * @title Standard ERC20 token\n *\n * @dev Implementation of the basic standard token.\n * https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md\n * Originally based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol\n */\ncontract ERC20 is IERC20 {\n  using SafeMath for uint256;\n\n  mapping (address =\u003e uint256) private _balances;\n\n  mapping (address =\u003e mapping (address =\u003e uint256)) private _allowed;\n\n  uint256 private _totalSupply;\n\n  /**\n  * @dev Total number of tokens in existence\n  */\n  function totalSupply() public view returns (uint256) {\n    return _totalSupply;\n  }\n\n  /**\n  * @dev Gets the balance of the specified address.\n  * @param owner The address to query the balance of.\n  * @return An uint256 representing the amount owned by the passed address.\n  */\n  function balanceOf(address owner) public view returns (uint256) {\n    return _balances[owner];\n  }\n\n  /**\n   * @dev Function to check the amount of tokens that an owner allowed to a spender.\n   * @param owner address The address which owns the funds.\n   * @param spender address The address which will spend the funds.\n   * @return A uint256 specifying the amount of tokens still available for the spender.\n   */\n  function allowance(\n    address owner,\n    address spender\n   )\n    public\n    view\n    returns (uint256)\n  {\n    return _allowed[owner][spender];\n  }\n\n  /**\n  * @dev Transfer token for a specified address\n  * @param to The address to transfer to.\n  * @param value The amount to be transferred.\n  */\n  function transfer(address to, uint256 value) public returns (bool) {\n    _transfer(msg.sender, to, value);\n    return true;\n  }\n\n  /**\n   * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.\n   * Beware that changing an allowance with this method brings the risk that someone may use both the old\n   * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this\n   * race condition is to first reduce the spender\u0027s allowance to 0 and set the desired value afterwards:\n   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729\n   * @param spender The address which will spend the funds.\n   * @param value The amount of tokens to be spent.\n   */\n  function approve(address spender, uint256 value) public returns (bool) {\n    require(spender != address(0));\n\n    _allowed[msg.sender][spender] = value;\n    emit Approval(msg.sender, spender, value);\n    return true;\n  }\n\n  /**\n   * @dev Transfer tokens from one address to another\n   * @param from address The address which you want to send tokens from\n   * @param to address The address which you want to transfer to\n   * @param value uint256 the amount of tokens to be transferred\n   */\n  function transferFrom(\n    address from,\n    address to,\n    uint256 value\n  )\n    public\n    returns (bool)\n  {\n    require(value \u003c= _allowed[from][msg.sender]);\n\n    _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);\n    _transfer(from, to, value);\n    return true;\n  }\n\n  /**\n   * @dev Increase the amount of tokens that an owner allowed to a spender.\n   * approve should be called when allowed_[_spender] == 0. To increment\n   * allowed value is better to use this function to avoid 2 calls (and wait until\n   * the first transaction is mined)\n   * From MonolithDAO Token.sol\n   * @param spender The address which will spend the funds.\n   * @param addedValue The amount of tokens to increase the allowance by.\n   */\n  function increaseAllowance(\n    address spender,\n    uint256 addedValue\n  )\n    public\n    returns (bool)\n  {\n    require(spender != address(0));\n\n    _allowed[msg.sender][spender] = (\n      _allowed[msg.sender][spender].add(addedValue));\n    emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);\n    return true;\n  }\n\n  /**\n   * @dev Decrease the amount of tokens that an owner allowed to a spender.\n   * approve should be called when allowed_[_spender] == 0. To decrement\n   * allowed value is better to use this function to avoid 2 calls (and wait until\n   * the first transaction is mined)\n   * From MonolithDAO Token.sol\n   * @param spender The address which will spend the funds.\n   * @param subtractedValue The amount of tokens to decrease the allowance by.\n   */\n  function decreaseAllowance(\n    address spender,\n    uint256 subtractedValue\n  )\n    public\n    returns (bool)\n  {\n    require(spender != address(0));\n\n    _allowed[msg.sender][spender] = (\n      _allowed[msg.sender][spender].sub(subtractedValue));\n    emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);\n    return true;\n  }\n\n  /**\n  * @dev Transfer token for a specified addresses\n  * @param from The address to transfer from.\n  * @param to The address to transfer to.\n  * @param value The amount to be transferred.\n  */\n  function _transfer(address from, address to, uint256 value) internal {\n    require(value \u003c= _balances[from]);\n    require(to != address(0));\n\n    _balances[from] = _balances[from].sub(value);\n    _balances[to] = _balances[to].add(value);\n    emit Transfer(from, to, value);\n  }\n\n  /**\n   * @dev Internal function that mints an amount of the token and assigns it to\n   * an account. This encapsulates the modification of balances such that the\n   * proper events are emitted.\n   * @param account The account that will receive the created tokens.\n   * @param value The amount that will be created.\n   */\n  function _mint(address account, uint256 value) internal {\n    require(account != 0);\n    _totalSupply = _totalSupply.add(value);\n    _balances[account] = _balances[account].add(value);\n    emit Transfer(address(0), account, value);\n  }\n\n  /**\n   * @dev Internal function that burns an amount of the token of a given\n   * account.\n   * @param account The account whose tokens will be burnt.\n   * @param value The amount that will be burnt.\n   */\n  function _burn(address account, uint256 value) internal {\n    require(account != 0);\n    require(value \u003c= _balances[account]);\n\n    _totalSupply = _totalSupply.sub(value);\n    _balances[account] = _balances[account].sub(value);\n    emit Transfer(account, address(0), value);\n  }\n\n  /**\n   * @dev Internal function that burns an amount of the token of a given\n   * account, deducting from the sender\u0027s allowance for said account. Uses the\n   * internal burn function.\n   * @param account The account whose tokens will be burnt.\n   * @param value The amount that will be burnt.\n   */\n  function _burnFrom(address account, uint256 value) internal {\n    require(value \u003c= _allowed[account][msg.sender]);\n\n    // Should https://github.com/OpenZeppelin/zeppelin-solidity/issues/707 be accepted,\n    // this function needs to emit an event with the updated approval.\n    _allowed[account][msg.sender] = _allowed[account][msg.sender].sub(\n      value);\n    _burn(account, value);\n  }\n}\n"},"ERC20Burnable.sol":{"content":"pragma solidity ^0.4.24;\n\nimport \"./ERC20.sol\";\n\n/**\n * @title Burnable Token\n * @dev Token that can be irreversibly burned (destroyed).\n */\ncontract ERC20Burnable is ERC20 {\n\n  /**\n   * @dev Burns a specific amount of tokens.\n   * @param value The amount of token to be burned.\n   */\n  function burn(uint256 value) public {\n    _burn(msg.sender, value);\n  }\n\n  /**\n   * @dev Burns a specific amount of tokens from the target address and decrements allowance\n   * @param from address The address which you want to send tokens from\n   * @param value uint256 The amount of token to be burned\n   */\n  /*\n  --Do not use \n  function burnFrom(address from, uint256 value) public {\n    _burnFrom(from, value);\n    //Only the owner\u0027s address can be burned.  @ejkang\n  }\n  */\n}\n"},"ERC20Detailed.sol":{"content":"pragma solidity ^0.4.24;\n\nimport \"./IERC20.sol\";\n\n/**\n * @title ERC20Detailed token\n * @dev The decimals are only for visualization purposes.\n * All the operations are done using the smallest and indivisible token unit,\n * just as on Ethereum all the operations are done in wei.\n */\ncontract ERC20Detailed is IERC20 {\n  string private _name;\n  string private _symbol;\n  uint8 private _decimals;\n\n  constructor(string name, string symbol, uint8 decimals) public {\n    _name = name;\n    _symbol = symbol;\n    _decimals = decimals;\n  }\n\n  /**\n   * @return the name of the token.\n   */\n  function name() public view returns(string) {\n    return _name;\n  }\n\n  /**\n   * @return the symbol of the token.\n   */\n  function symbol() public view returns(string) {\n    return _symbol;\n  }\n\n  /**\n   * @return the number of decimals of the token.\n   */\n  function decimals() public view returns(uint8) {\n    return _decimals;\n  }\n}\n"},"IERC20.sol":{"content":"pragma solidity ^0.4.24;\n\n/**\n * @title ERC20 interface\n * @dev see https://github.com/ethereum/EIPs/issues/20\n */\ninterface IERC20 {\n  function totalSupply() external view returns (uint256);\n\n  function balanceOf(address who) external view returns (uint256);\n\n  function allowance(address owner, address spender)\n    external view returns (uint256);\n\n  function transfer(address to, uint256 value) external returns (bool);\n\n  function approve(address spender, uint256 value)\n    external returns (bool);\n\n  function transferFrom(address from, address to, uint256 value)\n    external returns (bool);\n\n  event Transfer(\n    address indexed from,\n    address indexed to,\n    uint256 value\n  );\n\n  event Approval(\n    address indexed owner,\n    address indexed spender,\n    uint256 value\n  );\n}\n"},"Ownable.sol":{"content":"pragma solidity ^0.4.24;\n\n/**\n * @title Ownable\n * @dev The Ownable contract has an owner address, and provides basic authorization control\n * functions, this simplifies the implementation of \"user permissions\".\n */\ncontract Ownable {\n  address private _owner;\n\n  event OwnershipTransferred(\n    address indexed previousOwner,\n    address indexed newOwner\n  );\n\n  /**\n   * @dev The Ownable constructor sets the original `owner` of the contract to the sender\n   * account.\n   */\n  constructor() internal {\n    _owner = msg.sender;\n    emit OwnershipTransferred(address(0), _owner);\n  }\n\n  /**\n   * @return the address of the owner.\n   */\n  function owner() public view returns(address) {\n    return _owner;\n  }\n\n  /**\n   * @dev Throws if called by any account other than the owner.\n   */\n  modifier onlyOwner() {\n    require(isOwner());\n    _;\n  }\n\n  /**\n   * @return true if `msg.sender` is the owner of the contract.\n   */\n  function isOwner() public view returns(bool) {\n    return msg.sender == _owner;\n  }\n\n  /**\n   * @dev Allows the current owner to relinquish control of the contract.\n   * @notice Renouncing to ownership will leave the contract without an owner.\n   * It will not be possible to call the functions with the `onlyOwner`\n   * modifier anymore.\n   * Don\u0027t use this function.\n   */\n   /*\n  function renounceOwnership() public onlyOwner {\n    emit OwnershipTransferred(_owner, address(0));\n    _owner = address(0);\n  }\n  */\n  /**\n   * @dev Allows the current owner to transfer control of the contract to a newOwner.\n   * @param newOwner The address to transfer ownership to.\n   */\n  function transferOwnership(address newOwner) public onlyOwner {\n    _transferOwnership(newOwner);\n  }\n\n  /**\n   * @dev Transfers control of the contract to a newOwner.\n   * @param newOwner The address to transfer ownership to.\n   */\n  function _transferOwnership(address newOwner) internal {\n    require(newOwner != address(0));\n    emit OwnershipTransferred(_owner, newOwner);\n    _owner = newOwner;\n  }\n}\n"},"SafeMath.sol":{"content":"pragma solidity ^0.4.24;\n\n/**\n * @title SafeMath\n * @dev Math operations with safety checks that revert on error\n */\nlibrary SafeMath {\n\n  /**\n  * @dev Multiplies two numbers, reverts on overflow.\n  */\n  function mul(uint256 a, uint256 b) internal pure returns (uint256) {\n    // Gas optimization: this is cheaper than requiring \u0027a\u0027 not being zero, but the\n    // benefit is lost if \u0027b\u0027 is also tested.\n    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522\n    if (a == 0) {\n      return 0;\n    }\n\n    uint256 c = a * b;\n    require(c / a == b);\n\n    return c;\n  }\n\n  /**\n  * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.\n  */\n  function div(uint256 a, uint256 b) internal pure returns (uint256) {\n    require(b \u003e 0); // Solidity only automatically asserts when dividing by 0\n    uint256 c = a / b;\n    // assert(a == b * c + a % b); // There is no case in which this doesn\u0027t hold\n\n    return c;\n  }\n\n  /**\n  * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).\n  */\n  function sub(uint256 a, uint256 b) internal pure returns (uint256) {\n    require(b \u003c= a);\n    uint256 c = a - b;\n\n    return c;\n  }\n\n  /**\n  * @dev Adds two numbers, reverts on overflow.\n  */\n  function add(uint256 a, uint256 b) internal pure returns (uint256) {\n    uint256 c = a + b;\n    require(c \u003e= a);\n\n    return c;\n  }\n\n  /**\n  * @dev Divides two numbers and returns the remainder (unsigned integer modulo),\n  * reverts when dividing by zero.\n  */\n  function mod(uint256 a, uint256 b) internal pure returns (uint256) {\n    require(b != 0);\n    return a % b;\n  }\n}\n"},"Stopable.sol":{"content":"pragma solidity ^0.4.24;\n\nimport \"./Ownable.sol\";\n\ncontract Stoppable is Ownable{\n    bool public stopped = false;\n    \n    modifier enabled {\n        require (!stopped);\n        _;\n    }\n    \n    function stop() external onlyOwner { \n        stopped = true; \n    }\n    \n    function start() external onlyOwner {\n        stopped = false;\n    }    \n}\n"}}