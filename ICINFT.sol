// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

interface ICINFT {
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

    // Public function to mint a new token
    function mint(string memory _imageUrl) external;

    function mint(address _to, string memory _imageUrl) external;

    // functions to enter a memory
    function registerEntry(string memory _memory) external returns (bytes32 requestId);

    function fullfillEntry(
        bytes32 _requestId,
        string memory _newCid,
        RequestFullfillmentConfig memory _fullfilmentConfig
    ) external;

    // Functions to handle prompts and responses
    function submitPrompt(uint256 _tokenId, string memory _prompt) external returns (bytes32 promptId);

    function respond(bytes32 _promptId, string memory _response) external returns (string memory);

    // Getter Functions
    function getMinter(uint256 tokenId) external view returns (address);

    function getMemoryOfAOwner(
        address _owner
    ) external view returns (string memory, PersonalityTraits memory);

    function getTokenIdToImageUrl(
        uint256 _tokenId
    ) external view returns (string memory);

    function getMemory() external view returns (string memory, PersonalityTraits memory);

    function getPromptDetails(bytes32 _promptId) external view returns (string memory prompt, string memory response, address sender, address owner);

    function getPromptsIds() external view returns (bytes32[] memory);

    function getMemoryStringRequestedToAdd(bytes32 _requestId) external view returns (string memory);

    function getOwnerFromRequestId(bytes32 _requestId) external view returns (address);

}