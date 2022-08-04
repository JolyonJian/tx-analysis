// contracts/ShitBeast.sol

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "erc721a/contracts/extensions/ERC721AQueryable.sol";

enum Stage {
    NotStarted,
    ShitClaim,
    Sale
}

interface IShitCoin {
    function holderClaim(address holder, uint256 amount) external;
}

contract ShitBeast is ERC2981, ERC721AQueryable, Ownable {
    using Address for address payable;
    using Strings for uint256;

    address public constant BLACKHOLE = 0x000000000000000000000000000000000000dEaD;

    IERC721 public immutable _shit;
    IShitCoin public immutable _shitCoin;
    uint256 public immutable _shitCoinPerPair;
    uint256 public immutable _price;
    uint32 public immutable _maxSupply;
    uint32 public immutable _holderSupply;
    uint32 public immutable _teamSupply;
    uint32 public immutable _walletLimit;

    uint32 public _teamMinted;
    uint32 public _holderClaimed;
    string public _metadataURI = "https://metadata.pieceofshit.wtf/shitbeast/json/";
    Stage public _stage = Stage.NotStarted;

    struct Status {
        // config
        uint256 price;
        uint256 shitCoinPerPair;
        uint32 maxSupply;
        uint32 publicSupply;
        uint32 walletLimit;

        // state
        uint32 publicMinted;
        uint32 userMinted;
        bool soldout;
        Stage stage;
    }

    constructor(
        address shit,
        address shitCoin,
        uint256 shitCoinPerPair,
        uint256 price,
        uint32 maxSupply,
        uint32 holderSupply,
        uint32 teamSupply,
        uint32 walletLimit
    ) ERC721A("ShitBeast", "SB") {
        require(shit != address(0));
        require(shitCoin != address(0));
        require(maxSupply >= holderSupply + teamSupply);

        _shit = IERC721(shit);
        _shitCoin = IShitCoin(shitCoin);
        _shitCoinPerPair = shitCoinPerPair;
        _price = price;
        _maxSupply = maxSupply;
        _holderSupply = holderSupply;
        _teamSupply = teamSupply;
        _walletLimit = walletLimit;

        setFeeNumerator(750);
    }

    function shitClaim(uint256[] memory tokenIds) external {
        require(_stage == Stage.ShitClaim, "ShitBeast: Claiming is not started yet");
        require(tokenIds.length > 0 && tokenIds.length % 2 == 0, "ShitBeast: You must provide token pairs");
        uint32 pairs = uint32(tokenIds.length / 2);
        require(pairs + _holderClaimed <= _holderSupply, "ShitBeast: Exceed holder supply");

        for (uint256 i = 0; i < tokenIds.length; ) {
            _shit.transferFrom(msg.sender, BLACKHOLE, tokenIds[i]);
            unchecked {
                i++;
            }
        }

        _setAux(msg.sender, _getAux(msg.sender) + pairs);
        _shitCoin.holderClaim(msg.sender, pairs * _shitCoinPerPair);
        _safeMint(msg.sender, pairs);
    }

    function mint(uint32 amount) external payable {
        require(_stage == Stage.Sale, "ShitBeast: Sale is not started");
        require(amount + _publicMinted() <= _publicSupply(), "ShitBeast: Exceed max supply");
        require(amount + uint32(_numberMinted(msg.sender)) - uint32(_getAux(msg.sender)) <= _walletLimit, "ShitBeast: Exceed wallet limit");
        require(msg.value == amount * _price, "ShitBeast: Insufficient fund");

        _safeMint(msg.sender, amount);
    }

    function _publicMinted() public view returns (uint32) {
        return uint32(_totalMinted()) - _teamMinted;
    }

    function _publicSupply() public view returns (uint32) {
        return _maxSupply - _teamSupply;
    }

    function _status(address minter) external view returns (Status memory) {
        uint32 publicSupply = _publicSupply();
        uint32 publicMinted = _publicMinted();

        return Status({
            // config
            price: _price,
            maxSupply: _maxSupply,
            publicSupply: publicSupply,
            shitCoinPerPair: _shitCoinPerPair,
            walletLimit: _walletLimit,

            // state
            publicMinted: publicMinted,
            soldout: publicMinted >= publicSupply,
            userMinted: uint32(_numberMinted(minter)) - uint32(_getAux(msg.sender)),
            stage: _stage
        });
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI = _metadataURI;
        return string(abi.encodePacked(baseURI, tokenId.toString(), ".json"));
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC2981, ERC721A) returns (bool) {
        return
            interfaceId == type(IERC2981).interfaceId ||
            interfaceId == type(IERC721).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function devMint(address to, uint32 amount) external onlyOwner {
        _teamMinted += amount;
        require(_teamMinted <= _teamSupply, "ShitBeast: Exceed max supply");
        _safeMint(to, amount);
    }

    function setFeeNumerator(uint96 feeNumerator) public onlyOwner {
        _setDefaultRoyalty(owner(), feeNumerator);
    }

    function setStage(Stage stage) external onlyOwner {
        _stage = stage;
    }

    function setMetadataURI(string memory uri) external onlyOwner {
        _metadataURI = uri;
    }

    function withdraw() external onlyOwner {
        payable(msg.sender).sendValue(address(this).balance);
    }
}


