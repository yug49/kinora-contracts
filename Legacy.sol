// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import "ICINFT.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

/**
 * @title Legacy contract
 * @author Yug Agarwal
 * @dev This contract helps NFT minters to will their NFTs to their nominees in case they forget to ping the contract within a year.
 * The minter can send their NFT to this contract along with the nominee's address. 
 *                                                                         
                         .            .                                   .#                        
                       +#####+---+###+#############+-                  -+###.                       
                       +###+++####+##-+++++##+++##++####+-.         -+###+++                        
                       +#########.-#+--+####++###- -########+---+++#####+++                         
                       +#######+#+++--+####+-..-+-.###+++########+-++###++.                         
                      +######.     +#-#####+-.-------+############+++####-                          
                     +####++...     ########-++-        +##########++++++.                          
                    -#######-+.    .########+++          -++######+++-                               
                    #++########--+-+####++++-- . ..    .-#++--+##+####.                              
                   -+++++++++#####---###---.----###+-+########..-+#++##-                            
                   ++###+++++#####-..---.. .+##++++#++#++-+--.   .-++++#                             
                  .###+.  .+#+-+###+ ..    +##+##+#++----...---.  .-+--+.                            
                  ###+---------+####+   -####+-.......    ...--++.  .---.                           
                 -#++++-----#######+-  .-+###+.... .....      .-+##-.  .                            
                 ##+++###++######++-.   .--+---++---........  ...---.  .                            
                -####+-+#++###++-.        .--.--...-----.......--..... .                            
                +######+++###+--..---.....  ...---------------.. .. .  .                            
               .-#########+#+++--++--------......----++--.--.  .--+---.                             
                -+++########++--++++----------------------.--+++--+++--                             
           .######-.-++++###+----------------------..---++--++-+++---..                             
           -##########-------+-----------------------+-++-++----..----+----+#####++--..             
           -#############+..  ..--..----------.....-+++++++++++++++++##################+.           
           --+++++#########+-   . ....  ....... -+++++++++++++++++++############-.----+##-          
           -----....-+#######+-             .. -+++++++++++++++++++++##+######+.       +++.         
           --------.....---+#####+--......----.+++++++++++++++++++++##+-+++##+.        -++-         
           -------...   .--++++++---.....-----.+++++++++++++++++++++++. -+++##-        .---         
           #################+--.....-------.  .+++++++++++++++++++++-       -+-.       .---         
           +#########++++-.. .......-+--..--++-++++++++++++++++++++-         .-... ....----         
           -#####++---..   .--       -+++-.  ..+++++++++++++++++++--        .-+-......-+---         
           +####+---...    -+#-   .  --++++-. .+++++++++++++++++++---        --        -+--         
           ++++++++++--....-++.--++--.--+++++-.+++++++++++++++++++---. .......         ----         
          .--++#########++-.--.+++++--++++###+-++++++++++++++++++++----   .-++-        ----         
           .-+#############+-.++#+-+-++#######-++++++++++++++++++++----   -++++-      ..---         
          .---+############+.+###++--++#####++-+++++++++++++++++++++-------++++-........-+-         
           --+-+##########-+######+++++-++++++-++++++++++++++++++++++-----.----.......---+-         
          .--+---#######..+#######+++++++--+++-+++++++++++++++++++++++-----------------+++-         
          .++--..-+##-.-########+++++---++ .+-.+++++++++++++++++++++++++++++++++++---+++++-         
          -+++. ..-..-+#########++-++--..--....+++++++++++++++++++++++++++++++++++++++++++-         
          -++-......-+++############++++----- .+++++++++++++++++++++++++++++++++++++++++++-         
          +##-.....---+#######+####+####+--++-.+++++++++++++++++++++++++++++++++++++++++++-         
         .#+++-...-++######++-+-----..----++##-+++++++++++++++++++++++++++++++++++++++++++-         
         .+++--------+##----+------+-..----+++-+++++++++++++++++++++++++++++++++++++++++++-         
          ----.-----+++-+-...------++-----...--+++++++++++++++++++++++++++++++++++++++++++-         
         .-..-.--.----..--.... ....++--.  ....-+++++++++++++++++++++++++++++++++++++++++++-         
          -----------.---..--..   ..+.  . ... .+++++++++++++++++++++++++++++++++++++++++++-         
        .+#+#+---####+-.    .....--...   .    .+++++++++++++++++++++++++++++++++++++++++++-         
        -+++++#++++++++.    ..-...--.. ..     .+++++++++++++++++++++++++++++++++++++++++++-         
        ++++++-------++--   . ....--.. . . .. .+++++++++++++++++++++++++-+----------...             
        -++++--++++.------......-- ...  ..  . .---------------...                                   
        -++-+####+++---..-.........                                                                  
          .....                                                                                      
 */
contract Legacy is IERC721Receiver {
    error Legacy__TheNFTReceivedIsNotFromTheDesiredCollection();
    error Legacy__TheNFTReceivedIsNotFromTheMinter();
    error Legacy__TheRefreshTimeHasNotPassed();
    error Legacy__NoNFTsToClaim();

    mapping(address => address[]) private s_subscribersToNominees; // subscriber => nominees
    mapping(address => uint256[]) private s_subscribersToTokenIds; // subscriber => tokenIds
    mapping(address => uint256) private s_lastPingedTime; // subscriber => lastPingedTime
    uint32 constant public REFRESH_TIME = 365 days + 4 hours; // Adding 4 hours to account for leap years
    ICINFT public immutable i_cinft; // The contract address of the CINFT collection

    event Claimed(address indexed subscriber , address[] nominees); // event when NFTs are claimed by nominees

    /**
     * @dev Sets the address of the CINFT contract.
     * @param _cinftContractAddress The address of the CINFT contract.
     */
    constructor(address _cinftContractAddress) {
        i_cinft = ICINFT(_cinftContractAddress);
    }

    /**
     * @dev Handles the receipt of an NFT.\
     * @param from The address that previously owned the NFT.
     * @param tokenId The ID of the NFT being transferred.
     * @param data Additional data with no specified format. It constains the nominee's address only.
     * @return bytes4 A selector to confirm the callback execution.
     * The user just have to safeTransferFrom their NFT to this contract with the nominee's address as data. and the nominee will be added here for him in this contract.
     */
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

    /**
     * @dev Allows subscribers to update their last pinged time to the current block timestamp.
     */
    function ping() public {
        s_lastPingedTime[msg.sender] = block.timestamp;
    }

    /**
     * 
     * @param _subscriber The address of the subscriber whose nominees are claiming the NFTs.
     * Allows anyone to claim the NFTs on behalf of the nominees if the subscriber has not pinged within the REFRESH_TIME.
     * It will be called automatically by the backend service also that will be keeping the note of the time.
     */
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
    /**
     * @dev Internal function to add a nominee for a subscriber.
     * @param _minter The address of the subscriber (minter).
     * @param _tokenId The ID of the token being willed.
     * @param _nomineeAddress The address of the nominee.
     */
    function _addNominee(address _minter, uint256 _tokenId, address _nomineeAddress) internal {
        s_subscribersToTokenIds[_minter].push(_tokenId);
        s_subscribersToNominees[_minter].push(_nomineeAddress);
        s_lastPingedTime[msg.sender] = block.timestamp;
    }

    /**
     * @dev Returns the last pinged timestamp of the caller.
     * @return The last pinged timestamp.
     */
    function getLastPingedTimeStamp() external view returns(uint256) {
        return s_lastPingedTime[msg.sender];
    }
    
}