// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract WNS is ERC721, Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;
    using SafeERC20 for IERC20;

    Counters.Counter private _tokenIds;

    mapping(string => bool) public nameExists;
    uint256 public ethFee;
    uint256 public tokenFee;
    IERC20 public feeToken;

    // Events
    event FeeUpdated(uint256 ethFee, uint256 tokenFee, address feeToken);
    event NFTMinted(uint256 tokenId, string name, address mintedBy);

    constructor(address __owner) ERC721("NameNFT", "NNFT") Ownable(__owner) {}

    function setFees(uint256 _ethFee, uint256 _tokenFee, address _feeToken) external onlyOwner {
        ethFee = _ethFee;
        tokenFee = _tokenFee;
        feeToken = IERC20(_feeToken);
        emit FeeUpdated(_ethFee, _tokenFee, _feeToken);
    }

    function mintNFTWithETH(string memory name) external payable nonReentrant {
        require(!nameExists[name], "Name already exists");
        require(msg.value >= ethFee, "Insufficient WYZ sent");

        _mintNFT(name);
    }

    function mintNFTWithToken(string memory name, uint256 amount) external nonReentrant {
        require(!nameExists[name], "Name already exists");
        require(amount >= tokenFee, "Insufficient token amount");
        
        feeToken.safeTransferFrom(msg.sender, address(this), amount);
        _mintNFT(name);
    }

    function _mintNFT(string memory name) private {
        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();
        
        _mint(msg.sender, newItemId);
        nameExists[name] = true;

        emit NFTMinted(newItemId, name, msg.sender);
    }

    function withdraw() external onlyOwner {
        uint256 ethBalance = address(this).balance;
        payable(owner()).transfer(ethBalance);

        uint256 tokenBalance = feeToken.balanceOf(address(this));
        feeToken.safeTransfer(owner(), tokenBalance);
    }
}
