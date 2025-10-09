// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import "ICINFT.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract Legacy is IERC721Receiver {
    error Legacy__TheNFTReceivedIsNotFromTheDesiredCollection();
    error Legacy__TheNFTReceivedIsNotFromTheMinter();
    error Legacy__TheRefreshTimeHasNotPassed();
    error Legacy__NoNFTsToClaim();

    mapping(address => address[]) private s_subscribersToNominees;
    mapping(address => uint256[]) private s_subscribersToTokenIds;
    mapping(address => uint256) private s_lastPingedTime;
    uint32 constant public REFRESH_TIME = 365 days + 4 hours;
    ICINFT public immutable i_cinft;

    event Claimed(address indexed subscriber , address[] nominees);

    constructor(address _cinftContractAddress) {
        i_cinft = ICINFT(_cinftContractAddress);
    }

    function onERC721Received(
        address /* operator */,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external override  returns (bytes4) {
        // 🔹 Your custom logic here:
        if(msg.sender != address(i_cinft)) revert Legacy__TheNFTReceivedIsNotFromTheDesiredCollection();
        if(i_cinft.getMinter(tokenId) != from) revert Legacy__TheNFTReceivedIsNotFromTheMinter();

        address nomineeAddress = abi.decode(data, (address));
        _addNominee(from, tokenId, nomineeAddress);

        // 🔹 You must return this selector or the transfer will revert
        return IERC721Receiver.onERC721Received.selector;
    }

    function ping() public {
        s_lastPingedTime[msg.sender] = block.timestamp;
    }

    function claim(address _subscriber) public {
        if(block.timestamp - s_lastPingedTime[_subscriber] < REFRESH_TIME) revert Legacy__TheRefreshTimeHasNotPassed();

        uint256[] memory tokenIds = s_subscribersToTokenIds[_subscriber];

        if(tokenIds.length == 0) revert Legacy__NoNFTsToClaim();

        for(uint256 i = 0; i < tokenIds.length; i++) {
            address nominee = s_subscribersToNominees[_subscriber][i];
            IERC721(address(i_cinft)).safeTransferFrom(address(this), nominee, tokenIds[i]);
            delete s_subscribersToNominees[_subscriber][i];
            delete s_subscribersToTokenIds[_subscriber][i];
        }

        s_lastPingedTime[_subscriber] = 0;
        
        emit Claimed(_subscriber, s_subscribersToNominees[_subscriber]);
    }

    function _addNominee(address _minter, uint256 _tokenId, address _nomineeAddress) internal {
        s_subscribersToTokenIds[_minter].push(_tokenId);
        s_subscribersToNominees[_minter].push(_nomineeAddress);
        s_lastPingedTime[msg.sender] = block.timestamp;
    }

    function getLastPingedTimeStamp() external view returns(uint256) {
        return s_lastPingedTime[msg.sender];
    }
    
}