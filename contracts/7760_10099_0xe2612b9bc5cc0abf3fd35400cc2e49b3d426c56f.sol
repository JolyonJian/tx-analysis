pragma solidity 0.4.24;

// File: contracts/commons/SafeMath.sol

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a / b;
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

// File: contracts/flavours/Ownable.sol

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {

    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor() public {
        owner = msg.sender;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

// File: contracts/flavours/Lockable.sol

/**
 * @title Lockable
 * @dev Base contract which allows children to
 *      implement main operations locking mechanism.
 */
contract Lockable is Ownable {
    event Lock();
    event Unlock();

    bool public locked = false;

    /**
     * @dev Modifier to make a function callable
    *       only when the contract is not locked.
     */
    modifier whenNotLocked() {
        require(!locked);
        _;
    }

    /**
     * @dev Modifier to make a function callable
     *      only when the contract is locked.
     */
    modifier whenLocked() {
        require(locked);
        _;
    }

    /**
     * @dev called by the owner to lock, triggers locked state
     */
    function lock() public onlyOwner whenNotLocked {
        locked = true;
        emit Lock();
    }

    /**
     * @dev called by the owner
     *      to unlock, returns to unlocked state
     */
    function unlock() public onlyOwner whenLocked {
        locked = false;
        emit Unlock();
    }
}

// File: contracts/base/ERC20Token.sol

interface ERC20Token {
    function transferFrom(address from_, address to_, uint value_) external returns (bool);
    function transfer(address to_, uint value_) external returns (bool);
    function balanceOf(address owner_) external returns (uint);
}

// File: contracts/base/BaseAirdrop.sol

contract BaseAirdrop is Lockable {
    using SafeMath for uint;

    ERC20Token public token;

    address public tokenHolder;

    mapping(address => bool) public users;

    event AirdropToken(address indexed to, uint amount);

    constructor(address _token, address _tokenHolder) public {
        require(_token != address(0) && _tokenHolder != address(0));
        token = ERC20Token(_token);
        tokenHolder = _tokenHolder;
    }

    function airdrop(uint8 v, bytes32 r, bytes32 s, uint amount) public whenNotLocked {
        if (users[msg.sender] || ecrecover(prefixedHash(amount), v, r, s) != owner) {
            revert();
        }
        users[msg.sender] = true;
        token.transferFrom(tokenHolder, msg.sender, amount);
        emit AirdropToken(msg.sender, amount);
    }

    function getAirdropStatus(address user) public constant returns (bool success) {
        return users[user];
    }

    function originalHash(uint amount) internal view returns (bytes32) {
        return keccak256(abi.encodePacked(
                "Signed for Airdrop",
                address(this),
                address(token),
                msg.sender,
                amount
            ));
    }

    function prefixedHash(uint amount) internal view returns (bytes32) {
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        return keccak256(abi.encodePacked(prefix, originalHash(amount)));
    }
}

// File: contracts/BITOXAirdrop.sol

/**
 * @title BITOX token airdrop contract.
 */
contract BITOXAirdrop is BaseAirdrop {

    constructor(address _token, address _tokenHolder) public BaseAirdrop(_token, _tokenHolder) {
        locked = true;
    }

    // Disable direct payments
    function() external payable {
        revert();
    }

    // withdraw funds only for owner
    function withdraw() public onlyOwner {
        owner.transfer(address(this).balance);
    }

    // withdraw stuck tokens only for owner
    function withdrawTokens(address _someToken) public onlyOwner {
        ERC20Token someToken = ERC20Token(_someToken);
        uint balance = someToken.balanceOf(this);
        someToken.transfer(owner, balance);
    }
}