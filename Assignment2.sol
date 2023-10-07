// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Game {
    address public player1;
    address public player2;
    uint256 public minimumBet = 0.0001 ether;
    uint256 public revealTimeout = 60; // seconds
    uint256 public revealStartTime;
    bytes32 public encryptedMove1;
    bytes32 public encryptedMove2;
    string public clearMove1;
    string public clearMove2;
    bool public rewardSent;
    
    modifier onlyRegisteredPlayers() {
        require(msg.sender == player1 || msg.sender == player2, "Only registered players can call this function");
        _;
    }
    
    modifier bothPlayersPlayed() {
        require(encryptedMove1 != bytes32(0) && encryptedMove2 != bytes32(0), "Both players must play first");
        _;
    }
    
    modifier bothPlayersRevealed1() {
        require(keccak256(abi.encodePacked((clearMove1))) != keccak256(abi.encodePacked((""))) && keccak256(abi.encodePacked((clearMove2))) != keccak256(abi.encodePacked((""))), "Both players must reveal their moves first");
        _;
    }
    
    function register() external payable {
        require(msg.value >= minimumBet, "Insufficient bet amount");
        
        if (player1 == address(0)) {
            player1 = msg.sender;
        } else if (player2 == address(0)) {
            player2 = msg.sender;
        } else {
            revert("Game is already full");
        }
    }

    function bothPlayersRevealed() internal view returns (bool){
        return keccak256(abi.encodePacked((clearMove1))) != keccak256(abi.encodePacked((""))) && keccak256(abi.encodePacked((clearMove2))) == keccak256(abi.encodePacked(("")));
    }
    
    function play(bytes32 encrMove) external onlyRegisteredPlayers {
        if (msg.sender == player1) {
            encryptedMove1 = encrMove;
        } else {
            encryptedMove2 = encrMove;
        }
    }
    
    function reveal(string memory clearMove) external onlyRegisteredPlayers {
        require(encryptedMove1 != bytes32(0) && encryptedMove2 != bytes32(0), "Both players must play first");
        require(revealStartTime != 0, "Reveal phase has not started yet");
        require(block.timestamp <= revealStartTime + revealTimeout, "Reveal phase has ended");
        
        if (msg.sender == player1) {
            clearMove1 = clearMove;
        } else {
            clearMove2 = clearMove;
        }
    }
    
    function getOutcome() external onlyRegisteredPlayers bothPlayersRevealed1 {
        require(!rewardSent, "Reward has already been sent");
        
        if (keccak256(abi.encodePacked(clearMove1)) == keccak256(abi.encodePacked(clearMove2))) {
            // Draw
            payable(player1).transfer(address(this).balance / 2);
            payable(player2).transfer(address(this).balance);
        } else if (
            (keccak256(abi.encodePacked(clearMove1)) == keccak256(abi.encodePacked("rock")) && keccak256(abi.encodePacked(clearMove2)) == keccak256(abi.encodePacked("scissors"))) ||
            (keccak256(abi.encodePacked(clearMove1)) == keccak256(abi.encodePacked("paper")) && keccak256(abi.encodePacked(clearMove2)) == keccak256(abi.encodePacked("rock"))) ||
            (keccak256(abi.encodePacked(clearMove1)) == keccak256(abi.encodePacked("scissors")) && keccak256(abi.encodePacked(clearMove2)) == keccak256(abi.encodePacked("paper")))
        ) {
            // Player 1 wins
            payable(player1).transfer(address(this).balance);
        } else {
            // Player 2 wins
            payable(player2).transfer(address(this).balance);
        }
        
        rewardSent = true;
    }
    
    function startRevealPhase() external onlyRegisteredPlayers bothPlayersPlayed {
        require(revealStartTime == 0, "Reveal phase has already started");
        
        revealStartTime = block.timestamp;
    }
    
    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }
    
    function whoAmI() external view returns (uint256) {
        if (msg.sender == player1) {
            return 1;
        } else if (msg.sender == player2) {
            return 2;
        } else {
            return 0;
        }
    }
    
    function bothPlayed() external view returns (bool) {
        return encryptedMove1 != bytes32(0) && encryptedMove2 != bytes32(0);
    }
    
    function bothRevealed() external view returns (bool) {
        return bothPlayersRevealed();
    }
    
    function revealTimeLeft() external view returns (uint256) {
        if (revealStartTime == 0) {
            return revealTimeout;
        } else {
            uint256 elapsedTime = block.timestamp - revealStartTime;
            if (elapsedTime >= revealTimeout) {
                return 0;
            } else {
                return revealTimeout - elapsedTime;
            }
        }
    }
}
