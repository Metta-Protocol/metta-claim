// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract MettaClaim {
    event Claim(address indexed user, uint256 amount);

    bytes32 public merkleRoot;
    uint256 public totalClaimedAmount;
    mapping(address => bool) public hasClaimed;

    uint public claimStartTime;
    uint public claimPeriod;

    address public owner;
    address public devWallet;

    IERC20 public token;

    bool public claimOpened;

    constructor(
        bytes32 _merkleRoot,
        address _tokenAddress,
        address _devWallet
    ) {
        owner = msg.sender;
        merkleRoot = _merkleRoot;
        token = IERC20(_tokenAddress);

        devWallet = _devWallet;
    }

    function claim(uint256 amount, bytes32[] calldata merkleProof) public {
        require(claimStartTime + claimPeriod >= block.timestamp);
        require(!hasClaimed[msg.sender], "Already claimed");
        require(claimOpened == true);
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, amount));
        require(
            verifyMerkleProof(merkleProof, merkleRoot, leaf),
            "Invalid proof"
        );

        hasClaimed[msg.sender] = true;
        token.transfer(msg.sender, amount);
        totalClaimedAmount += amount;

        emit Claim(msg.sender, amount);
    }

    function openClaim() external onlyOwner {
        claimOpened = true;
        claimStartTime = block.timestamp;
    }

    function closeClaim() external onlyOwner {
        claimOpened = false;
    }

    function recoverAirdropBalance() external onlyOwner {
        require(
            claimStartTime + claimPeriod < block.timestamp,
            "still claiming"
        );
        uint balance = token.balanceOf(address(this));
        token.transfer(devWallet, balance);
    }

    function updateClaimPeriod(uint _newPeriod) external onlyOwner {
        claimPeriod = _newPeriod;
    }

    function updateDevWallet(address _devWallet) external onlyOwner {
        devWallet = _devWallet;
    }

    function withdrawTokens(IERC20 _token) external onlyOwner {
        uint256 balance = _token.balanceOf(address(this));
        require(_token.transfer(msg.sender, balance), "Transfer failed");
    }

    function transferOwnership(address _newAddress) external onlyOwner {
        owner = _newAddress;
    }

    function viewTokenAddress() public view returns (address) {
        return address(token);
    }

    function viewDevWallet() public view returns (address) {
        return devWallet;
    }

    function viewOwner() public view returns (address) {
        return owner;
    }

    function viewTotalClaimedAmount() public view returns (uint) {
        return totalClaimedAmount;
    }

    function verifyMerkleProof(
        bytes32[] calldata proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return MerkleProof.verify(proof, root, leaf);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Caller is not the owner");
        _;
    }
}
