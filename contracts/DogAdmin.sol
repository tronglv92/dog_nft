// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "./access/Ownable.sol";

contract DogAdmin is Ownable {
    mapping(address => uint256) addressToKittyCreatorId;
    address[] kittyCreators;

    event KittyCreatorAdded(address creator);
    event KittyCreatorRemoved(address creator);

    constructor() {
        _addKittyCreator(address(0));
        _addKittyCreator(owner());
    }

    modifier onlyKittyCreator() {
        require(isKittyCreator(msg.sender), "must be a kitty creator");
        _;
    }

    function isKittyCreator(address _address) public view returns (bool) {
        return addressToKittyCreatorId[_address] != 0;
    }

    function addKittyCreator(address _address) external onlyOwner {
        require(_address != address(0), "zero address");
        require(_address != address(this), "contract address");
        _addKittyCreator(_address);
    }

    function _addKittyCreator(address _address) internal {
        kittyCreators.push(_address);
        addressToKittyCreatorId[_address] = kittyCreators.length - 1;
        emit KittyCreatorAdded(_address);
    }

    function removeCreator(address _address) external onlyOwner {
        uint256 id = addressToKittyCreatorId[_address];
        delete kittyCreators[id];
        delete addressToKittyCreatorId[_address];
    }

    function getKittyCreators() external view returns (address[] memory) {
        return kittyCreators;
    }
}
