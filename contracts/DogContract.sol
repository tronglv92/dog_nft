// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./tokens/ERC721.sol";

contract DogContract is ERC721 {
    string private name = "DogPet";
    string private symbol = "DOG";

    struct Dog {
        uint32 dadId;
        uint32 mumId;
        uint64 birthTime;
        uint16 generation;
        uint16 cooldownIndex;
        uint64 cooldownEndTime;
        uint256 genes;
    }

    Dog[] internal dogs;
    

    constructor() ERC721(name, symbol) {
        dogs.push(
            Dog({
                dadId: 0,
                mumId: 0,
                birthTime: 0,
                generation: 0,
                cooldownIndex: 0,
                cooldownEndTime: 0,
                genes: 0
            })
        );
    }

    function isOnlyOnwer(uint256 tokenId) internal returns(bool){
        return ownerOf(tokenId)==msg.sender;
       
    }
    modifier isApprovedOrOwner(uint256 tokenId){
         require( _isApprovedOrOwner(msg.sender,tokenId),"sender is not dog owner or approve");
         _;
    }

    function getDog(uint256 tokenId) public returns(Dog memory){
        Dog memory dog=dogs[tokenId];
        return dog;
    }
}
