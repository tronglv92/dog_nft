// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./IDogMarketPlace.sol";
import "./access/Ownable.sol";
import "./DogFactory.sol";

contract DogMarketPlace is IDogMarketPlace, Ownable {
    DogFactory internal _dogFactory;

    struct Offer {
        address payable seller;
        uint256 tokenId;
        uint256 price;
        uint256 index;
        bool isSireOffer;
        bool active;
    }

    Offer[] offers;
    mapping(uint256 => Offer) tokenIdToOffer;

    modifier isOnlyOnwerToken(uint256 tokenId) {
        require(msg.sender == _dogFactory.ownerOf(tokenId), "only onwer");
        _;
    }

    modifier marketApproved() {
        require(
            _dogFactory.isApprovedForAll(msg.sender, address(this)),
            "market must be approved operator"
        );
        _;
    }

    modifier noActiveOffer(uint256 tokenId) {
        require(tokenIdToOffer[tokenId].active == false, "is active");
        _;
    }
    modifier activeOffer(uint256 tokenId) {
        require(tokenIdToOffer[tokenId].active == true, "no active");
        _;
    }

    function setDogContract(address dogContractAddress) public {
        _dogFactory = DogFactory(dogContractAddress);
    }

    function setOffer(uint256 tokenId, uint256 price)
        public
        marketApproved
        isOnlyOnwerToken(tokenId)
        noActiveOffer(tokenId)
    {
        _setOffer(tokenId, price, "Create", false);
    }

    function _setOffer(
        uint256 tokenId,
        uint256 price,
        string memory txType,
        bool isSireOffer
    ) internal {
        Offer memory offer = Offer({
            seller: payable(msg.sender),
            tokenId: tokenId,
            price: price,
            index: offers.length,
            isSireOffer: false,
            active: true
        });
        offers.push(offer);
        tokenIdToOffer[offers.length - 1] = offer;
        emit MarketTransaction(txType, msg.sender, tokenId);
    }

    function setSireOffer(uint256 tokenId, uint256 price)
        public
        marketApproved
        isOnlyOnwerToken(tokenId)
        noActiveOffer(tokenId)
    {
        _setOffer(tokenId, price, "Create", true);
    }

    function buyDog(uint256 tokenId) external payable activeOffer(tokenId) {
        Offer memory offer = tokenIdToOffer[tokenId];
        require(msg.value == offer.price, "price must be exact");

        _executeOffer(offer);

        _dogFactory.safeTransferFrom(offer.seller, msg.sender, tokenId);

        emit MarketTransaction("Remove", msg.sender, tokenId);
    }

    function _executeOffer(Offer memory offer) internal {
        // Important: remove offer BEFORE payment
        // to prevent re-entry attack
        _setOfferInactive(offer.tokenId);

        if (offer.price > 0) offer.seller.transfer(msg.value);
    }

    function _setOfferInactive(uint256 _tokenId) internal {
        offers[tokenIdToOffer[_tokenId].index].active = false;
        delete tokenIdToOffer[_tokenId];
    }

    function buySireOffer(uint256 sireId, uint256 matronId)
        external
        payable
        isOnlyOnwerToken(matronId)
    {
        Offer memory offer = tokenIdToOffer[sireId];
        require(msg.value == offer.price, "price must be exact");
        require(_dogFactory.readyToBreed(matronId),"matronId not ready to breed");


        _executeOffer(offer);


        _dogFactory.sireApprove(sireId,matronId,true);
        uint256 newDogId= _dogFactory.breed(sireId, matronId);
        _dogFactory.safeTransferFrom(address(this), msg.sender, newDogId);
        emit MarketTransaction("Sire Rites", msg.sender, sireId);
    }

    function removeOffer(uint256 tokenId)
        public
        isOnlyOnwerToken(tokenId)
        activeOffer(tokenId)
    {
        _setOfferInactive(tokenId);
    }

    function getAllTokenOnSale()
        public
        view
        returns (uint256[] memory listOfOffers)
    {
        return _getActiveOffers(false);
    }

    function _getActiveOffers(bool isSireOffer)
        internal
        view
        returns (uint256[] memory listOfOffers)
    {
        if (offers.length == 0) return new uint256[](0);
        uint256 count;
        for (uint256 i = 0; i < offers.length; i++) {
            Offer memory offer = offers[i];
            if (offer.active && offer.isSireOffer == isSireOffer) {
                count++;
            }
        }

        // create an array of active orders
        listOfOffers = new uint256[](count);
        uint256 j;
        for (uint256 i = 0; i < offers.length; i++) {
            Offer memory offer = offers[i];
            if (offer.active && offer.isSireOffer == isSireOffer) {
                listOfOffers[j] = offer.tokenId;
                j++;
            }
            if (j >= count) {
                return listOfOffers;
            }
        }

        return listOfOffers;
    }

    function getAllTokenSireOffer()
        external
        view
        returns (uint256[] memory listOfSireOffers)
    {
        return _getActiveOffers(true);
    }

    function getOffer(uint256 _tokenId)
        public
        activeOffer(tokenId)
        returns (
            address seller,
            uint256 price,
            uint256 tokenId,
            uint256 index,
            bool isSireOffer,
            bool active
        )
    {
        Offer memory offer = tokenIdToOffer[_tokenId];
        tokenId = offer.tokenId;
        seller = offer.seller;
        price = offer.price;
        index = offer.index;
        isSireOffer = offer.isSireOffer;
        active = offer.active;
    }
}
