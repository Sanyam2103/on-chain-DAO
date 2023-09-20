// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";

interface IFakeNFTMarketplace {
  function getPrice() external view returns (uint256);

  function available(uint256 _tokenId) external view returns (bool);

  function purchase(uint256 _tokenId) external payable;
}

interface ICryptoDevsNFT {
  function balanceOf(address owner) external view returns (uint256);

  function tokenOfOwnerByIndex(
    address owner,
    uint256 index
  ) external view returns (uint256);
}

contract CryptoDevsDAO is Ownable {
  struct Proposal {
    uint256 nftTokenId; // token id of nft to purchase from marketplace by proposal
    uint256 deadline;
    uint256 upvotes;
    uint256 downvotes;
    bool executed;
    mapping(uint256 => bool) voters; // mapping of tokenids of users to if the nft tokenid is already used to vote or not
  }
  enum Vote {
    UP,
    DOWN
  }

  mapping(uint256 => Proposal) public proposals;
  uint256 public numProposals;

  IFakeNFTMarketplace nftMarketplace;
  ICryptoDevsNFT cryptoDevsNFT;

  constructor(address _nftMarketplace, address _cryptoDevsNFT) payable {
    nftMarketplace = IFakeNFTMarketplace(_nftMarketplace);
    cryptoDevsNFT = ICryptoDevsNFT(_cryptoDevsNFT);
  }

  modifier nftHolderOnly() {
    require(cryptoDevsNFT.balanceOf(msg.sender) > 0, "NOT A DAO MEMBER");
    _;
  }

  modifier activeProposalOnly(uint256 _proposalId) {
    require(block.timestamp <= proposals[_proposalId].deadline, "VOTING HAS ENDED");
    _;
  }

  modifier inactiveProposalOnly(uint256 _proposalId) {
    require(proposals[_proposalId].deadline <= block.timestamp, "VOTING IS NOT OVER");
    require(proposals[_proposalId].executed == false, "PROPOSAL_ALREADY_EXECUTED");
    _;
  }

  function createProposal(uint256 _nftTokenId) external nftHolderOnly returns (uint256) {
    require(nftMarketplace.available(_nftTokenId), "NFT NOT FOR SALE");

    Proposal storage proposal = proposals[numProposals];
    proposal.nftTokenId = _nftTokenId;

    proposal.deadline = block.timestamp + 5 minutes;
    numProposals++;

    return numProposals - 1;
  }

  function VoteOnProposals(
    uint256 _proposalId,
    Vote vote
  ) external nftHolderOnly activeProposalOnly(_proposalId) {
    Proposal storage proposal = proposals[_proposalId];
    uint256 voterNFTBalance = cryptoDevsNFT.balanceOf(msg.sender);
    uint256 numVotes = 0;

    for (uint256 i = 0; i < voterNFTBalance; i++) {
      uint256 tokenId = cryptoDevsNFT.tokenOfOwnerByIndex(msg.sender, i);
      if (proposal.voters[tokenId] == false) {
        numVotes++;
        proposal.voters[tokenId] = true;
      }
    }
    require(numVotes > 0, "ALREADY VOTED");
    if (vote == Vote.UP) {
      proposal.upvotes += numVotes;
    } else {
      proposal.downvotes += numVotes;
    }
  }

  function executeProposal(
    uint256 _proposalId
  ) external nftHolderOnly inactiveProposalOnly(_proposalId) {
    Proposal storage proposal = proposals[_proposalId];
    if (proposal.upvotes > proposal.downvotes) {
      uint256 nftprice = nftMarketplace.getPrice();
      require(address(this).balance >= nftprice, "NOT ENOUGH FUNDS");
      nftMarketplace.purchase{value: nftprice}(proposal.nftTokenId);
    }
    proposal.executed = true;
  }

  function withdrawEth() external onlyOwner {
    uint256 balance = address(this).balance;
    require(balance > 0, "NOT ENOUGH FUNDS");

    (bool sent, ) = payable(owner()).call{value: balance}("");
    require(sent, "UNABLE TO WITHDRAW ETH");
  }

  receive() external payable {}

  fallback() external payable {}
}
