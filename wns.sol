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
    string public referral;
    IERC20 public feeToken;
    mapping(address => string ) public userRefral;

    // Events
    event FeeUpdated(uint256 ethFee, uint256 tokenFee, address feeToken);
    event NFTMinted(uint256 tokenId, string name, address mintedBy, string referredBy);

    constructor(address __owner) ERC721("NameNFT", "NNFT") Ownable(__owner) {}

    function setFees(uint256 _ethFee, uint256 _tokenFee, address _feeToken) external onlyOwner {
        ethFee = _ethFee;
        tokenFee = _tokenFee;
        feeToken = IERC20(_feeToken);
        emit FeeUpdated(_ethFee, _tokenFee, _feeToken);
    }

    function setUserReferal( string memory ref )public {
        userRefral[msg.sender] = ref;
    }

    function mintNFTWithETH(string memory name, string memory _referral) external payable nonReentrant {
        require(!nameExists[name], "Name already exists");
        require(msg.value >= ethFee, "Insufficient  sent");
        referral = _referral;

        _mintNFT(name,_referral);
    }

    function mintNFTWithToken(string memory name, uint256 amount,string memory _referral) external nonReentrant {
        require(!nameExists[name], "Name already exists");
        require(amount >= tokenFee, "Insufficient token amount");
        
        feeToken.safeTransferFrom(msg.sender, address(this), amount);
        _mintNFT(name,_referral);
    }

    function _mintNFT(string memory name,string memory _referral) private {
        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();
        
        _mint(msg.sender, newItemId);
        nameExists[name] = true;

        emit NFTMinted(newItemId, name, msg.sender, _referral);
    }

    function withdraw() external onlyOwner {
        uint256 ethBalance = address(this).balance;
        payable(owner()).transfer(ethBalance);

        uint256 tokenBalance = feeToken.balanceOf(address(this));
        feeToken.safeTransfer(owner(), tokenBalance);
    }
}
