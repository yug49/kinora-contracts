// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

pragma solidity ^0.8.20;

/**
 * @title CINFT Vickrey Auction Contract
 * @author Yug Agarwal
 * @dev It is a Vickrey auction contract for CINFTs where users can put their CINFTs on sale, bid on them, and complete the auction.
 * @dev It is deployed on TEN
 * @dev It is only possible on TEN since it leverage its FHE capabilities to keep the bids secret until the auction is complete.
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
contract CINFTVickreyAuction {
    error CINFTVickreyAuction__NftAlreadyOnSale();
    error CINFTVickreyAuction__NftNotOnSale();
    error CINFTVickreyAuction__BidAmountNotEqualToValueSent();
    error CINFTVickreyAuction__BidAmountLowerThanMinBid(uint256 minBid);
    error CINFTVickreyAuction__BidTimeExpired();
    error CINFTVickreyAuction__BidTimeNotExpired();

    enum NftStatus{
        NOT_ON_SALE,
        ON_SALE
    }

    IERC721 private immutable i_cinft; // CINFT contract address
    uint256[] private s_nftOnSale; // list of nfts on sale
    mapping(uint256 => address[]) private s_biders; // biders in decending order of bids
    mapping(uint256 => uint256[]) private s_bids; // bids in decending order
    mapping(uint256 => uint256) private s_minBid; // minimum bid for each nft on sale
    mapping(uint256 => NftStatus) private s_nftStatus; // status of each nft (SALE or NOT_ON_SALE)
    mapping(uint256 => uint256) private s_bidEndTime; // bid end time for each nft on sale
    mapping(uint256 => address) private s_seller; // seller of each nft on sale
    mapping(address => uint256[]) private s_sellerToTokenIds; // list of cinfts on sale by a seller
    mapping(uint256 => string) private s_description; // description of a nft on sale by the seller

    /**
     * @param _cinft The address of the CINFT contract
     */
    constructor(address _cinft) {
        i_cinft = IERC721(_cinft);
    }

    /**
     * 
     * @param _tokenId The tokenId of the nft to be put on sale
     * @param _minBid Min bid for the nft
     * @param _bidTimeInSeconds The auction time (in secs) for this nft
     * @param _description The desciption by seller
     * @dev This function assumes that the owner has already approved the contract to transfer the nft
     */
    function putNftOnSale(uint256 _tokenId, uint256 _minBid, uint256 _bidTimeInSeconds, string memory _description) public {
        if(s_nftStatus[_tokenId] != NftStatus.NOT_ON_SALE)
            revert CINFTVickreyAuction__NftAlreadyOnSale();

        i_cinft.transferFrom(msg.sender, address(this), _tokenId);

        s_nftOnSale.push(_tokenId);
        // s_bidStartTime[_tokenId] = block.timestamp;
        s_bidEndTime[_tokenId] = block.timestamp + _bidTimeInSeconds;
        s_minBid[_tokenId] = _minBid;
        s_nftStatus[_tokenId] = NftStatus.ON_SALE;
        s_seller[_tokenId] = msg.sender;
        s_description[_tokenId] = _description;
        s_sellerToTokenIds[msg.sender].push(_tokenId);
    }

    /**
     * @param _tokenId The tokenId of the nft to bid on
     * @param _bid The bid amount
     * @dev to bid on a nft on sale, the bidder must send the bid amount in msg.value
     */
    function bid(uint256 _tokenId, uint256 _bid) public payable {
        if(s_nftStatus[_tokenId] != NftStatus.ON_SALE)
            revert CINFTVickreyAuction__NftNotOnSale();
        if(_bid < s_minBid[_tokenId]) revert CINFTVickreyAuction__BidAmountLowerThanMinBid(s_minBid[_tokenId]);
        if(msg.value != _bid) revert CINFTVickreyAuction__BidAmountNotEqualToValueSent();
        if(block.timestamp > s_bidEndTime[_tokenId]) revert CINFTVickreyAuction__BidTimeExpired();

        _insertBider(_bid, _tokenId, msg.sender);
    }

    /**
     * 
     * @param _tokenId The tokenId of the nft to complete the auction for
     * @dev This function can be called by anyone after the bid time has expired
     * @dev If there are no bids, the nft is returned to the seller
     * @dev The highest bidder gets the nft and pays the second highest bid amount to the seller
     * @dev The highest bidder is refunded the difference between their bid and the second highest bid
     * @dev All other bidders are refunded their bids
     * @dev If there is only one bid, the highest bidder gets the nft and pays
     */
    function completeAuction(uint256 _tokenId) public {
        if(s_nftStatus[_tokenId] != NftStatus.ON_SALE)
            revert CINFTVickreyAuction__NftNotOnSale();
        if(block.timestamp < s_bidEndTime[_tokenId]) revert CINFTVickreyAuction__BidTimeNotExpired();
        // if there are no bids, return the nft to the seller
        if(s_biders[_tokenId].length == 0) {
            i_cinft.transferFrom(address(this), s_seller[_tokenId], _tokenId);
        }
        // if there is only one bid
        else if(s_biders[_tokenId].length == 1) {
            // transfer nft to the highest bidder
            i_cinft.transferFrom(address(this), s_biders[_tokenId][0], _tokenId);
            // transfer the highest bid to the seller
            payable(s_seller[_tokenId]).transfer(s_bids[_tokenId][0]);
        }
        // if there are 2 or more bids
        else {
            // transfer nft to the highest bidder
            i_cinft.transferFrom(address(this), s_biders[_tokenId][0], _tokenId);
            // transfer the second highest bid to the seller
            payable(s_seller[_tokenId]).transfer(s_bids[_tokenId][1]);
            // refund extra bid amount to the highest bider
            payable(s_biders[_tokenId][0]).transfer(s_bids[_tokenId][0] - s_bids[_tokenId][1]);
            // refund all the other bids to the biders
            for(uint256 i = 2; i < s_biders[_tokenId].length; i++) {
                payable(s_biders[_tokenId][i]).transfer(s_bids[_tokenId][i]);
            }
        }

        // reset all the mappings and arrays
        for(uint256 i = 0; i < s_nftOnSale.length; i++){
            if(s_nftOnSale[i] == _tokenId){
                s_nftOnSale[i] = s_nftOnSale[s_nftOnSale.length - 1];
                s_nftOnSale.pop();
                break;
            }
        }
        for(uint256 i = 0 ; i < s_sellerToTokenIds[s_seller[_tokenId]].length; i++){
            if(s_sellerToTokenIds[s_seller[_tokenId]][i] == _tokenId){
                s_sellerToTokenIds[s_seller[_tokenId]][i] = s_sellerToTokenIds[s_seller[_tokenId]][s_sellerToTokenIds[s_seller[_tokenId]].length - 1];
                s_sellerToTokenIds[s_seller[_tokenId]].pop();
                break;
            }
        }
        delete s_biders[_tokenId];
        delete s_bids[_tokenId];
        s_minBid[_tokenId] = 0;
        s_nftStatus[_tokenId] = NftStatus.NOT_ON_SALE;
        s_bidEndTime[_tokenId] = 0;
        s_seller[_tokenId] = address(0);
        s_description[_tokenId] = "";
        
    }

    /**
     * This function inserts the bider and their bid in the correct position in the array to maintain the descending order of bids
     * @param value The bid value
     * @param _tokenId The tokenId of the nft
     * @param bider The address of the bidder
     */
    function _insertBider(uint256 value, uint256 _tokenId, address bider) private {
        // Find the position for insertion
        uint256 i = 0;
        while (i < s_bids[_tokenId].length && s_bids[_tokenId][i] > value) {
            i++;
        }

        // Insert at position i
        s_bids[_tokenId].push(value); // increase array size
        s_biders[_tokenId].push(bider);
        for (uint256 j = s_biders[_tokenId].length - 1; j > i; j--) {
            s_biders[_tokenId][j] = s_biders[_tokenId][j - 1];
            s_bids[_tokenId][j] = s_bids[_tokenId][j - 1];
        }
        s_biders[_tokenId][i] = bider;
        s_bids[_tokenId][i] = value;
    }
    
    // Getter functions

    /**
     * @return The address of the CINFT contract
     */
    function getNftsOnSale() public view returns(uint256[] memory) {
        return s_nftOnSale;
    }

    /**
     * @param _tokenId The tokenId of the nft
     * @return The status of NFT, true if ON_SALE, false if NOT_ON_SALE
     */
    function isNftOnSale(uint256 _tokenId) public view returns(bool) {
        return s_nftStatus[_tokenId] == NftStatus.ON_SALE;
    }

    /**
     * 
     * @param _tokenId The tokenId of the nft
     * @return The end time of the bid for the nft
     */
    function getNftsBidEndTime(uint256 _tokenId) public view returns(uint256) {
        return s_bidEndTime[_tokenId];
    }

    /**
     * 
     * @param _tokenId The tokenId of the nft
     * @return The minimum bid for the nft
     */
    function getMinBid(uint256 _tokenId) public view returns(uint256) {
        return s_minBid[_tokenId];
    }

    /**
     * 
     * @param _seller The address of the seller
     * @return The list of tokenIds of nfts put on sale by the seller
     */
    function getListOfNftsBySeller(address _seller) public view returns(uint256[] memory) {
        return s_sellerToTokenIds[_seller];
    }

    /**
     * @param _tokenId The token id of nft
     * @return The description of the NFT on Sale
     */
    function getDescription(uint256 _tokenId) public view returns(string memory) {
        return s_description[_tokenId];
    }

    receive() external payable { }
}