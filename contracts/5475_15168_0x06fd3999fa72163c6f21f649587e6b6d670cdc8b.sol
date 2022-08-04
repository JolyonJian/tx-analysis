// contracts/ERC721A-Merkle.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./ERC721A.sol";

contract sunniesNFT is Ownable, PaymentSplitter, ERC721A, ReentrancyGuard {
    uint256 public immutable MAX_SUPPLY = 9141;
    uint256 public constant PRICE = 0.05 ether;
    uint256 public maxPresale = 3;
    uint256 public maxPublic = 5; //max total for public mint
    uint256 public maxPublicTx; //max per tx public mint

    uint256 public immutable amountForTeam;

    bool public _isActive = false;
    bool public _presaleActive = false;

    mapping(address => bool) public allowList;
    mapping(address => uint8) public _preSaleListCounter;
    mapping(address => uint256) public _publicCounter;
    mapping(address => uint256) public _teamCounter;

    // merkle root
    bytes32 public preSaleRoot;

    constructor(
        string memory name,
        string memory symbol,
        uint256 _amountForTeam,
        uint256 _maxPublicTx,
        address[] memory payees,
        uint256[] memory shares
    )
        ERC721A(name, symbol, _amountForTeam, _maxPublicTx)
        PaymentSplitter(payees, shares)
    {
        maxPublicTx = _maxPublicTx;
        amountForTeam = _amountForTeam;
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    //set variables
    function setActive(bool isActive) external onlyOwner {
        _isActive = isActive;
    }

    function presaleActive(bool isActive) external onlyOwner {
        _presaleActive = isActive;
    }

    function setMaxPresale(uint256 _maxPresale) external onlyOwner {
        maxPresale = _maxPresale;
    }

    function setMaxMints(uint256 maxMints_) public onlyOwner {
        maxPublic = maxMints_;
    }

    function setPreSaleRoot(bytes32 _root) external onlyOwner {
        preSaleRoot = _root;
    }

    // Internal for marketing, devs, etc
    function internalMint(uint256 quantity, address to) external onlyOwner {
        require(
            _teamCounter[msg.sender] + quantity <= amountForTeam,
            "too many already minted for internal mint"
        );
        require(
            totalSupply() + quantity <= MAX_SUPPLY,
            "would exceed max supply"
        );
        _safeMint(to, quantity);
        _teamCounter[msg.sender] = _teamCounter[msg.sender] + quantity;
    }

    // metadata URI
    string private _baseTokenURI;

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    // Presale
    function mintPreSaleTokens(uint8 quantity, bytes32[] calldata _merkleProof)
        external
        payable
        callerIsUser
        nonReentrant
    {
        require(_presaleActive, "Pre mint is not active");
        require(
            _preSaleListCounter[msg.sender] + quantity <= maxPresale,
            "Exceeded max available to purchase"
        );
        require(quantity > 0, "Must mint more than 0 tokens");
        require(
            totalSupply() + quantity <= MAX_SUPPLY,
            "Purchase would exceed max supply of Tokens"
        );
        require(PRICE * quantity == msg.value, "Incorrect funds");

        // check proof & mint
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(
            MerkleProof.verify(_merkleProof, preSaleRoot, leaf) ||
                allowList[msg.sender],
            "Invalid MerkleProof"
        );
        _safeMint(msg.sender, quantity);
        _preSaleListCounter[msg.sender] =
            _preSaleListCounter[msg.sender] +
            quantity;
    }

    function addToPreSaleOverflow(address[] calldata addresses)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < addresses.length; i++) {
            allowList[addresses[i]] = true;
        }
    }

    //withdraw to owner wallet
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    // public mint
    function publicSaleMint(uint256 quantity)
        external
        payable
        nonReentrant
        callerIsUser
    {
        require(quantity > 0, "Must mint more than 0 tokens");
        require(_isActive, "public sale has not begun yet");
        require(PRICE * quantity == msg.value, "Incorrect funds");
        require(quantity <= maxPublicTx, "exceeds max per transaction");
        require(
            _publicCounter[msg.sender] + quantity <= maxPublic,
            "exceeds max per address"
        );
        require(totalSupply() + quantity <= MAX_SUPPLY, "reached max supply");

        _safeMint(msg.sender, quantity);
        _publicCounter[msg.sender] = _publicCounter[msg.sender] + quantity;
    }
}


