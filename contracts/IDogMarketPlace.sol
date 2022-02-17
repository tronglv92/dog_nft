// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IDogMarketPlace{

    event MarketTransaction(string TxType,address owner,uint256 tokenId);

    function setOffer(uint256 tokenId,uint256 price) external ;

    function setSireOffer(uint256 tokenId,uint256 price) external ;

    function buyDog(uint256 tokenId) external payable;

    function buySireOffer(uint256 sireId,uint256 matronId) external payable;

    function removeOffer(uint256 tokenId) external;

    function getAllTokenOnSale() external view returns(uint256[] memory listOfOffers);

    function getAllTokenSireOffer() external view returns(uint256[] memory listOfSireOffers);

    function getOffer(uint256 _tokenId) external returns(address seller,uint256 price,uint256 tokenId,uint256 index,bool isSireOffer,bool active);

    function setDogContract(address dogContractAddress) external;

}