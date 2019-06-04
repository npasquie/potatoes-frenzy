pragma solidity ^0.5.7;

// used to support string[] would need to stop using ERC721Metadata and convert string[] to bytes32 to allow batch creation

// EF announced bugs related to the encoder fixed in 0.5.7: https://blog.ethereum.org/2019/03/26/solidity-optimizer-and-abiencoderv2-bug/

pragma experimental ABIEncoderV2;

import "github.com/OpenZeppelin/openzeppelin-solidity/contracts/token/ERC721/ERC721MetadataMintable.sol";

import "github.com/OpenZeppelin/openzeppelin-solidity/contracts/ownership/Ownable.sol";

import "github.com/OpenZeppelin/openzeppelin-solidity/contracts/drafts/Counters.sol";

contract PotatoesCore is ERC721MetadataMintable, Ownable {

 using Counters for Counters.Counter;

 mapping(uint=>bytes32) private IPFSUri;

 mapping(uint=>Potatoes) private tokenData;

 struct Potatoes {

   string name;

 }

 Counters.Counter private tokenCounter;

 constructor(string memory _name, string memory _symbol) public ERC721Metadata(_name, _symbol) {

 }

 function mintOne(address _to, string memory _uri, string memory name) public onlyMinter {

   mintWithTokenURI(_to, tokenCounter.current(), _uri);

   Potatoes storage token = tokenData[tokenCounter.current()];

   token.name = name;

   tokenCounter.increment();

 }

 // TBD: Using experimental compiler here to support string[]

 function mintMany(address[] memory _to, string[] memory _uris, string[] memory names) public onlyMinter {

   require(_to.length==_uris.length);

   for (uint i=0; i<_to.length;i++) {

     mintWithTokenURI(_to[i], tokenCounter.current(), _uris[i]);

     Potatoes storage token = tokenData[tokenCounter.current()];

     token.name = names[i];

     tokenCounter.increment();

   }

 }
 
}