// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract PhanerozoicTest is ERC1155, Ownable, Pausable, ERC1155Burnable {

    // Token id increment
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdTracker;

    // Last block number tracker, used to evaluate if contract is a re-entry of same block
    uint private _blockNumberTracker = 0;

    // seed tracker, used for pseudo random number generating
    bytes32 private _seedTracker;

    mapping(uint256 => bytes32) private _seeds;

    uint private _mintQuota = 1;

    function generateSeed() private returns (bytes32) {
        bytes32 seedGen;

        // If tx executed from previous block, reset _seedTracker
        // Else, continue using current _seedTracker
        // Note this is doable only if mint is `onlyOwner`, otherwise
        if(_blockNumberTracker != block.number) {
            _seedTracker = keccak256(abi.encode(blockhash(block.number - 1)));
            _blockNumberTracker = block.number;
        }

        seedGen = keccak256(abi.encode(_seedTracker));
        _seedTracker = seedGen;
        return seedGen;
    }

    constructor() ERC1155("https://phanerozoic-gamefi.github.io/data/test/{id}.json") {}

    function setURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function mint(address account)
    public
    onlyOwner
    {
        if(_mintQuota == 0) {
            revert("Mint Quota exceeded");
        }

        _mint(account, _tokenIdTracker.current(), 1, "");
        _seeds[_tokenIdTracker.current()] = generateSeed();
        _tokenIdTracker.increment();
        _mintQuota--;
    }

    function mintBatch(address to, uint256 amount)
    public
    onlyOwner
    {
        if(_mintQuota == 0) {
            revert("Mint Quota exceeded");
        }

        uint256 amountAllowed = _mintQuota < amount? _mintQuota : amount;
        uint256[] memory ids = new uint256[](amountAllowed);
        uint256[] memory amounts = new uint256[](amountAllowed);

        for (uint256 i = 0; i < amountAllowed; i++) {
            ids[i] = _tokenIdTracker.current();
            _seeds[_tokenIdTracker.current()] = generateSeed();
            _tokenIdTracker.increment();
            amounts[i] = 1;
        }

        _mintQuota -= amountAllowed;
        _mintBatch(to, ids, amounts, "");
    }

    /**
     * reset quota  
     **/
    function resetQuota(uint quota) public onlyOwner {
        _mintQuota = quota;
    }

    /**
     * Get seed of a give token id
     **/
    function seed(uint32 id) public view returns (bytes32) {
        return _seeds[id];
    }

    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
    internal
    whenNotPaused
    override
    {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }
}