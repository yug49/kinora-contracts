// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

interface ContractTransparencyConfig {
    enum Field { TOPIC1, TOPIC2, TOPIC3, SENDER, EVERYONE }
    enum ContractCfg { TRANSPARENT, PRIVATE }

    struct EventLogConfig {
        bytes32 eventSignature;
        Field[] visibleTo;
    }

    struct VisibilityConfig {
        ContractCfg contractCfg;
        EventLogConfig[] eventLogConfigs;
    }

    function visibilityRules() external pure returns (VisibilityConfig memory);
}

/**
 * @title CINFT - Confidential Intelligent NFT
 * @notice This contract implements an ERC721 token with private journaling and personality traits features on TEN chain.
 * @author Yug Agarwal
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
contract CINFT is ContractTransparencyConfig, ERC721Enumerable {
    error CINFT__OnlyHolderOfTheCINFTCanSubmitAPromptForThis();
    error CINFT__NotNftHolder();
    error CINFT__OnlyTratitsAgentCanFullfillRequest();
    error CINFT__RequestDoesNotExist();
    error CINFT__OnlyPersonaAgentCanFullfillRequest();
    error CINFT__NotAuthorized();

    struct PersonalityTraits {
        // --- Slot 1 ---
        uint32 openness;
        uint32 conscientiousness;
        uint32 extraversion;
        uint32 agreeableness;
        uint32 neuroticism;
        uint32 achievement;
        uint32 compassion;
        uint32 creativity;
        // --- Slot 2 ---
        uint32 security;
        uint32 adventure;
        uint32 knowledge;
        uint32 autonomy;
        uint32 community;
        uint32 skillsHobbiesFrequency;
        uint32 interestsKnowledgeFrequency;
        uint32 keyEntitiesFrequency;
    }

    struct RequestFullfillmentConfig {
        bool[8] data;
    }

    // Counter for generating unique token IDs
    uint256 private _tokenIdCounter; 

    // Public keys of the off-chain agents
    address private _traitsAgentPublicKey; // public key of the agent that extracts traits
    address private _personaAgentPublicKey; // public key of the agent that personates someone

    // Private mapping to store CIDs for each token ID
    mapping(address => string) private _cid; // minter address to CID of some core memories
    mapping(address => PersonalityTraits) private _ownerToPersonalityTraits;
    
    // mapping to track the minter of each token
    mapping(uint256 => address) private _tokenMinter; // tokenId to minter address
    mapping(uint256 => string) private _tokenIdToImageUrl; // tokenId to image URL

    // mappings to manage prompts and responses
    mapping(address => bytes32[]) private _ownerToPromptIds; // owner to list of prompt IDs - will be used to manage and anaylse prompts for a owner (can even sell later)
    mapping(bytes32 => string) private _promptIdToPrompt; // prompt ID to prompt string
    mapping(bytes32 => address) private _promptIdToSender; // prompt ID to sender address
    mapping(bytes32 => string) private _promptIdToResponse; // prompt ID to response string
    mapping(bytes32 => address) private _promptIdToOwner; // prompt ID to owner address (the minter of the token)
    
    // mappings to manage memory entry requests
    mapping(bytes32 => string) private _requestIdToMemory; // request ID to memory string
    mapping(bytes32 => address) private _requestIdToOwner; // request ID to owner address (the minter of the token)

    event EntryRequested(
        address indexed requester,
        bytes32 indexed requestId,
        address indexed traitsAgent
    );
    event ResponseRequested(
        bytes32 indexed promptId,
        address indexed personaAgent
    );
    event Responded(
        address indexed requester,
        string response
    );

    // Constructor to initialize the ERC721 token with name and symbol
    constructor(
        address publicKeyOfTraitsAgent,
        address publicKeyOfPersonaAgent
    ) ERC721("Confidential Intelligent NFT", "CINFT") {
        _traitsAgentPublicKey = publicKeyOfTraitsAgent;
        _personaAgentPublicKey = publicKeyOfPersonaAgent;
    }

    // Public function to mint a new token
    
    /**
     * @param _imageUrl The URL of the image associated with the NFT.
     * @dev Mints a new CINFT of the caller to his own address with the provided image URL
     */
    function mint(string memory _imageUrl) public {
        mint(msg.sender, _imageUrl);
    }

    /**
     * @param _to The address to mint the NFT to.
     * @param _imageUrl The URL of the image associated with the NFT.
     * @dev Mints a new CINFT of the specified address with the provided image URL
     */
    function mint(address _to, string memory _imageUrl) public {
        // Increment the token ID counter
        _tokenIdCounter++;
        uint256 newTokenId = _tokenIdCounter;

        // Mint the new token to the caller
        _mint(_to, newTokenId);
        _tokenIdToImageUrl[newTokenId] = _imageUrl;
        _tokenMinter[newTokenId] = msg.sender;
    }

    // functions to enter a memory

    /**
     * @param _memory The memory entry to register.
     * @dev Requests to register a new memory entry for the caller.
     * @return requestId The ID of the memory entry request.
     */
    function registerEntry(string memory _memory) public returns (bytes32 requestId){
        requestId = keccak256(abi.encodePacked(_memory));
        _requestIdToMemory[requestId] = _memory;
        _requestIdToOwner[requestId] = msg.sender;

        emit EntryRequested(msg.sender, requestId, _traitsAgentPublicKey);
    }

    /**
     * @param _requestId The ID of the memory entry request to fulfill.
     * @param _fullfilmentConfig The configuration for fulfilling the request.
     * @dev Fulfills a memory entry request from the traits agent.
     */
    function fullfillEntry(
        bytes32 _requestId,
        string memory _newCid,
        RequestFullfillmentConfig memory _fullfilmentConfig
    ) public {
        if (msg.sender != _traitsAgentPublicKey)
            revert CINFT__OnlyTratitsAgentCanFullfillRequest();
        if (bytes(_requestIdToMemory[_requestId]).length == 0)
            revert CINFT__RequestDoesNotExist();

        _cid[_requestIdToOwner[_requestId]] = _newCid;
        if (_fullfilmentConfig.data[0]) {
            if(_ownerToPersonalityTraits[_requestIdToOwner[_requestId]].openness != type(uint32).max) // to avoid overflow
                    _ownerToPersonalityTraits[_requestIdToOwner[_requestId]].openness++;
        }
        if (_fullfilmentConfig.data[1]) {
            if(_ownerToPersonalityTraits[_requestIdToOwner[_requestId]].conscientiousness != type(uint32).max) 
                    _ownerToPersonalityTraits[_requestIdToOwner[_requestId]].conscientiousness++;
        }
        if (_fullfilmentConfig.data[2]) {
            if(_ownerToPersonalityTraits[_requestIdToOwner[_requestId]].extraversion != type(uint32).max) 
                    _ownerToPersonalityTraits[_requestIdToOwner[_requestId]].extraversion++;
        }
        if (_fullfilmentConfig.data[3]) {
            if(_ownerToPersonalityTraits[_requestIdToOwner[_requestId]].agreeableness != type(uint32).max) 
                    _ownerToPersonalityTraits[_requestIdToOwner[_requestId]].agreeableness++;
        }
        if (_fullfilmentConfig.data[4]) {
            if(_ownerToPersonalityTraits[_requestIdToOwner[_requestId]].neuroticism != type(uint32).max) 
                    _ownerToPersonalityTraits[_requestIdToOwner[_requestId]].neuroticism++;
        }
        if (_fullfilmentConfig.data[5]) {
            if(_ownerToPersonalityTraits[_requestIdToOwner[_requestId]].achievement != type(uint32).max) 
                    _ownerToPersonalityTraits[_requestIdToOwner[_requestId]].achievement++;
        }
        if (_fullfilmentConfig.data[6]) {
            if(_ownerToPersonalityTraits[_requestIdToOwner[_requestId]].compassion != type(uint32).max) 
                    _ownerToPersonalityTraits[_requestIdToOwner[_requestId]].compassion++;
        }
        if (_fullfilmentConfig.data[7]) {
            if(_ownerToPersonalityTraits[_requestIdToOwner[_requestId]].creativity != type(uint32).max) 
                    _ownerToPersonalityTraits[_requestIdToOwner[_requestId]].creativity++;
        }

        _requestIdToMemory[_requestId] = "";
        _requestIdToOwner[_requestId] = address(0);
    }

    // Functions to handle prompts and responses

    /**
     * @param _tokenId The ID of the CINFT token.
     * @param _prompt The prompt to submit.
     * @dev Submits a prompt for the specified CINFT token. Only the token holder
     * @return promptId The ID of the submitted prompt.
     */
    function submitPrompt(uint256 _tokenId, string memory _prompt) public returns (bytes32 promptId) {
        if (msg.sender != ownerOf(_tokenId)) {
            revert CINFT__OnlyHolderOfTheCINFTCanSubmitAPromptForThis();
        }
        promptId = keccak256(abi.encodePacked(_prompt));
        _promptIdToPrompt[promptId] = _prompt;
        _promptIdToSender[promptId] = msg.sender;
        _promptIdToOwner[promptId] = _tokenMinter[_tokenId];
        _ownerToPromptIds[msg.sender].push(promptId);

        emit ResponseRequested(
            promptId,
            _personaAgentPublicKey
        );
    }


    /**
     * @param _promptId The ID of the prompt to respond to.
     * @param _response The response to the prompt.
     * @return The response string.
     * @dev Responds to a submitted prompt. Only the persona agent can fulfill the request.
     */
    function respond(bytes32 _promptId, string memory _response) public returns (string memory) {
        if(msg.sender != _personaAgentPublicKey)
            revert CINFT__OnlyPersonaAgentCanFullfillRequest();
        if(bytes(_promptIdToPrompt[_promptId]).length == 0)
            revert CINFT__RequestDoesNotExist();

        _promptIdToResponse[_promptId] = _response;

        return _response;
    }

    // Getter Functions

    /**
     * @param tokenId The ID of the token.
     * @return The address of the minter of the specified token.
     */
    function getMinter(uint256 tokenId) public view returns (address) {
        return _tokenMinter[tokenId];
    }

    /** 
     * @param _owner The address of the owner.
     * @return The CID and personality traits associated with the specified owner's address.
     */
    function getMemoryOfAOwner(
        address _owner
    ) public view returns (string memory, PersonalityTraits memory) {
        if(msg.sender != _personaAgentPublicKey && msg.sender != _traitsAgentPublicKey) revert CINFT__NotAuthorized();

        return (_cid[_owner], _ownerToPersonalityTraits[_owner]);
    }

    /**
     * @param _tokenId The ID of the token.
     * @return The image URL associated with the specified token ID.
     */
    function getTokenIdToImageUrl(
        uint256 _tokenId
    ) public view returns (string memory) {
        return _tokenIdToImageUrl[_tokenId];
    }

    /**
     * @return The CID and personality traits associated with the caller's address.
     */
    function getMemory() public view returns (string memory, PersonalityTraits memory) {
        return (_cid[msg.sender], _ownerToPersonalityTraits[msg.sender]);
    }

    /**
     * @param _promptId The ID of the prompt.
     * @return prompt The prompt string.
     * @return response The response string.
     * @return sender The address of the prompt sender.
     * @return owner The address of the token minter (owner).
     * @dev Retrieves the details of a prompt. Only the persona agent or the token minter can access this information.
     */
    function getPromptDetails(bytes32 _promptId) public view returns (string memory prompt, string memory response, address sender, address owner) {
        if(msg.sender != _personaAgentPublicKey && msg.sender != _promptIdToOwner[_promptId]) 
            revert CINFT__NotAuthorized();
        
        prompt = _promptIdToPrompt[_promptId];
        response = _promptIdToResponse[_promptId];
        sender = _promptIdToSender[_promptId];
        owner = _promptIdToOwner[_promptId];
    }

    /**
     * @return An array of prompt IDs submitted by the sender.
     */
    function getPromptsIds() public view returns (bytes32[] memory) {
        if(balanceOf(msg.sender) == 0) revert CINFT__NotNftHolder();
        return _ownerToPromptIds[msg.sender];
    }

    /**
     * @param _requestId The ID of the memory entry request.
     * @return The memory string associated with the specified request ID.
     * @dev Retrieves the memory string for a given request ID. Only the traits agent can access this information.
     */
    function getMemoryStringRequestedToAdd(bytes32 _requestId) public view returns (string memory) {
        if(msg.sender != _traitsAgentPublicKey) revert CINFT__NotAuthorized();
        return _requestIdToMemory[_requestId];
    }

    /**
     * @param _requestId The ID of the memory entry request.
     * @return The address of the token minter (owner) associated with the specified request ID.
     * @dev Retrieves the owner address for a given request ID. Only the traits agent can access this information.
     */
    function getOwnerFromRequestId(bytes32 _requestId) public view returns (address) {
        if(msg.sender != _traitsAgentPublicKey) revert CINFT__NotAuthorized();
        return _requestIdToOwner[_requestId];
    }

    // Visibility rules for TEN chain
    function visibilityRules() external pure override returns (VisibilityConfig memory) {
        EventLogConfig[]  memory eventLogConfigs = new EventLogConfig[](3);

        // the signature of "event EntryRequested(address indexed requester, bytes32 indexed requestId, address indexed traitsAgent);"
        bytes32 entryRequestedEventSig = keccak256("EntryRequested(address,bytes32,address)");
        Field[]  memory relevantTo1 = new Field[](1);
        relevantTo1[0] = Field.TOPIC3; // traits agent
        eventLogConfigs[0] = EventLogConfig(entryRequestedEventSig, relevantTo1);

        // the signature of "event ResponseRequested(bytes32 indexed promptId, address indexed personaAgent);"
        bytes32 responseRequestedEventSig = keccak256("ResponseRequested(bytes32,address)");
        Field[]  memory relevantTo2 = new Field[](1);
        relevantTo2[0] = Field.TOPIC2; // personaAgent
        eventLogConfigs[1] = EventLogConfig(responseRequestedEventSig, relevantTo2);

        // the signature of "event Responded(address indexed requester, string response);"
        bytes32 respondedEventSig = keccak256("Responded(address,string)");
        Field[]  memory relevantTo3 = new Field[](1);
        relevantTo3[0] = Field.TOPIC1; // requester
        eventLogConfigs[2] = EventLogConfig(respondedEventSig, relevantTo3);


        return VisibilityConfig(ContractCfg.PRIVATE, eventLogConfigs);
    }
}