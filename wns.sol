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
    mapping(address => address) private userRefral;
    mapping(uint256 => address) public user_Address;
    mapping(address => uint256) public addressToId;
    mapping (address=>string) public givenName;
    uint256 public ethFee;
    uint256 public tokenFee;
    string public referral;
    IERC20 public feeToken;
    uint256 public lastUserId = 1;

    // Events
    event FeeUpdated(uint256 ethFee, uint256 tokenFee, address feeToken);
    event NFTMinted(uint256 tokenId, string name, address mintedBy,uint timestamp);
    event Registration(
        address indexed user,
        address refferedBy,
        uint256 timestamp
    );

    modifier onlyRegistered() {
        require(addressToId[msg.sender] != 0, "Sender not registered");
        _;
    }

    constructor(address __owner) ERC721("NameNFT", "NNFT") Ownable(__owner) {
        user_Address[lastUserId] = __owner;
        addressToId[__owner] = lastUserId;
        lastUserId++;
    }

    function register(address _refrral) public {
        require(addressToId[msg.sender] == 0, "Address already registered");
        require(addressToId[_refrral] != 0, "Invalid refrral");
        user_Address[lastUserId] = msg.sender;
        addressToId[msg.sender] = lastUserId;
        setUserReferal(_refrral);
        lastUserId++;
        emit Registration(msg.sender, _refrral, block.timestamp);
    }

    function setFees(
        uint256 _ethFee,
        uint256 _tokenFee,
        address _feeToken
    ) external onlyOwner {
        ethFee = _ethFee;
        tokenFee = _tokenFee;
        feeToken = IERC20(_feeToken);
        emit FeeUpdated(_ethFee, _tokenFee, _feeToken);
    }

    function setUserReferal(address ref) private {
        require(addressToId[ref] != 0, "Invalid Refrral code");
        userRefral[msg.sender] = ref;
    }

    function mintNFTWithETH(string memory name)
        external
        payable
        nonReentrant
        onlyRegistered
    {
        require(!nameExists[name], "Name already exists");
        require(msg.value >= ethFee, "Insufficient  sent");
        _mintNFT(name);
    }

    function mintNFTWithToken(string memory name, uint256 amount)
        external
        nonReentrant
        onlyRegistered
    {
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
        givenName[msg.sender]=name;
        emit NFTMinted(newItemId, name, msg.sender,block.timestamp);
    }

    function withdraw() external onlyOwner {
        uint256 ethBalance = address(this).balance;
        payable(owner()).transfer(ethBalance);
        uint256 tokenBalance = feeToken.balanceOf(address(this));
        feeToken.safeTransfer(owner(), tokenBalance);
    }

    function getUserDetail(address walletAddress)
        public
        view
        returns (address, uint256,string memory)
    {
        address refferredBy = userRefral[walletAddress];
        uint256 userId = addressToId[walletAddress];
        string memory given_Name=givenName[msg.sender];
        return (refferredBy, userId,given_Name);
    }

    function isUserExist(address wallet_address) public view  returns (bool){
        if(addressToId[wallet_address]==0){
            return false;
        }else{
            return true;
        }
    }
}

