// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title Whitelist
 * @dev A contract to manage whitelisted addresses that can interact with the Jar contract
 */
contract Whitelist is Ownable {
    // Mapping to store whitelisted addresses
    mapping(address => bool) private _whitelistedAddresses;
    
    // Array to keep track of all whitelisted addresses
    address[] private _whitelistArray;
    
    event AddressWhitelisted(address indexed account);
    event AddressRemovedFromWhitelist(address indexed account);
    event BatchWhitelistAdded(uint256 count);
    
    /**
     * @dev Add a single address to whitelist
     * @param _address The address to whitelist
     */
    function addToWhitelist(address _address) external onlyOwner {
        require(!_whitelistedAddresses[_address], "Address already whitelisted");
        _whitelistedAddresses[_address] = true;
        _whitelistArray.push(_address);
        emit AddressWhitelisted(_address);
    }
    
    /**
     * @dev Add multiple addresses to whitelist
     * @param _addresses Array of addresses to whitelist
     */
    function addBatchToWhitelist(address[] calldata _addresses) external onlyOwner {
        for (uint256 i = 0; i < _addresses.length; i++) {
            if (!_whitelistedAddresses[_addresses[i]]) {
                _whitelistedAddresses[_addresses[i]] = true;
                _whitelistArray.push(_addresses[i]);
            }
        }
        emit BatchWhitelistAdded(_addresses.length);
    }
    
    /**
     * @dev Remove an address from the whitelist
     * @param _address The address to remove from whitelist
     */
    function removeFromWhitelist(address _address) external onlyOwner {
        require(_whitelistedAddresses[_address], "Address not whitelisted");
        _whitelistedAddresses[_address] = false;
        
        // Remove from array
        for (uint256 i = 0; i < _whitelistArray.length; i++) {
            if (_whitelistArray[i] == _address) {
                _whitelistArray[i] = _whitelistArray[_whitelistArray.length - 1];
                _whitelistArray.pop();
                break;
            }
        }
        
        emit AddressRemovedFromWhitelist(_address);
    }

    /**
     * @dev Check if an address is whitelisted
     * @param _address The address to check
     * @return bool Whether the address is whitelisted
     */
    function isWhitelisted(address _address) external view returns (bool) {
        return _whitelistedAddresses[_address];
    }
    
    /**
     * @dev Get all whitelisted addresses
     * @return address[] Array of whitelisted addresses
     */
    function getWhitelistedAddresses() external view returns (address[] memory) {
        return _whitelistArray;
    }
    
    /**
     * @dev Get total number of whitelisted addresses
     * @return uint256 Number of whitelisted addresses
     */
    function getWhitelistCount() external view returns (uint256) {
        return _whitelistArray.length;
    }
}
