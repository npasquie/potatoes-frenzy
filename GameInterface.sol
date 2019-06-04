pragma solidity ^0.5.8;

pragma experimental ABIEncoderV2;

import {PotatoesCore} from './PotatoesCore.sol';

contract GameInterface is PotatoesCore {
    event GameCreated(uint indexed gameId, string name, uint256 startTime, uint256 endTime);
    event GameUpdated(uint indexed gameId, string name, uint256 startTime, uint256 endTime, bool indexed canceled);
    event RoundCreated(uint indexed gameId, uint indexed roundId, string name, uint256 startTime, uint256 endTime);
    event RoundUpdated(uint indexed gameId, uint indexed roundId, string name, uint256 startTime, uint256 endTime, bool indexed canceled);
    
    event PlayersAdded(uint indexed gameId, address[] players);
    event PlayersRemoved(uint indexed gameId, address[] players); 
    
    event TargetsUpdated(address indexed tagger, uint indexed gameId, uint indexed roundId, address[] targets);
    
    struct Game {
        string name;
        uint256 startTime;
        uint256 endTime;
        mapping(address => bool) validPlayers;
        address[] players;
        uint8 nextRoundId;
        mapping(uint8=>Round) rounds;
        bool canceled;
    }
    struct Round {
        string name;
        uint256 startTime;
        uint256 endTime;
        mapping(address=>uint8) fries;
        mapping(address=>uint8) votes;
        uint8 nbrPotatoes;
        mapping(uint8=>uint256) potatoes;
        mapping(address=>address[]) targets;
        bool canceled;
    }
    
    mapping(uint=>Game) games;
    uint nextGameId;
    
    mapping(address=>uint8) playerTeam;
    
    
    constructor(string memory _name, string memory _symbol) public PotatoesCore(_name, _symbol) {

    }
    
    function createGame(string calldata name, uint256 startTime, uint256 endTime) external returns (bool success) {
        require(startTime > now && endTime > startTime, "Insert a good timing" );
        Game storage game = games[nextGameId];
        uint gameId = nextGameId;
        
        game.name = name;
        game.startTime = startTime;
        game.endTime = endTime;
        
        nextGameId++;
        
        emit GameCreated(gameId, name, startTime, endTime);
        
        return true;
    }
    function putGame(uint gameId, string calldata name, uint256 startTime, uint256 endTime, bool cancel) external returns (bool success) {
        require (gameId < nextGameId, "The game exist");
        require(startTime > now && endTime > startTime);
        require(!cancel);
         
        Game storage game = games[gameId];
        
        game.name = name;
        game.startTime = startTime;
        game.endTime = endTime;
        game.canceled = cancel;
        
        emit GameUpdated(gameId, name, startTime, endTime, cancel);
        
        return true;
    }

    function getGame(uint gameId) external view returns(string memory name, uint256 startTime,uint256 endTime, uint8 nextRoundId, bool canceled){
        require(gameId < nextGameId, "the game doesn't exists");

        return(games[gameId].name,games[gameId].startTime,games[gameId].endTime,games[gameId].nextRoundId,games[gameId].canceled);
    } // Return a game base info

    function createRound(uint gameId, string calldata name, uint256 startTime, uint256 endTime) external returns (bool success) {
        require (gameId < nextGameId, "The game exist");
        require (games[gameId].startTime > now, "the game already started ");
        require(startTime > now && endTime > startTime, "Insert a good timing" );
        uint8 roundId = games[gameId].nextRoundId;
        Round storage round = games[gameId].rounds[roundId];
        
        round.name = name;
        round.startTime = startTime;
        round.endTime = endTime;
        
        games[gameId].nextRoundId++;
        
        emit RoundCreated(gameId, roundId, name, startTime, endTime);
        
        return true;
        
    }
    function putRound(uint gameId, uint8 roundId, string calldata name, uint256 startTime, uint256 endTime, bool cancel) external returns (bool success) {
        require (gameId < nextGameId, "The game exist");
        require(roundId < games[gameId].nextRoundId);
        require (!cancel,"the Game is cancelled");
        require (startTime > now && startTime > endTime, "Game finished");
        
        Round storage round = games[gameId].rounds[roundId];
        
        round.name = name;
        round.startTime = startTime;
        round.endTime = endTime;
        round.canceled = cancel;
        
        emit RoundUpdated(gameId, roundId, name, startTime, endTime, cancel);
        
        return true;
    }

    function getRound(uint gameId, uint8 roundId) external view returns(string memory name, uint256 startTime, uint256 endTime, uint8 nbrPotatoes, bool canceled){
        require (gameId < nextGameId, "The game doesn't exists");
        require (roundId < games[gameId].nextRoundId, "The round doesn't exists") ;

        return (games[gameId].rounds[roundId].name, games[gameId].rounds[roundId].startTime, games[gameId].rounds[roundId].endTime, games[gameId].rounds[roundId].nbrPotatoes, games[gameId].rounds[roundId].canceled);
    } // Return a game base inf

    function addPlayers(uint gameId, address[] calldata players ,uint8[] calldata teams) external returns(bool success){
        require (teams.length != players.length, "array of players ot team problem");
        require (teams.length <30, "Too much players , too much gaz");
        require (players.length <30, "Too much players");

        for(uint i=0; i<=30; i++)
        {

            // players[i] =teams[i];
            games[gameId].players.push(players[i]);
            games[gameId].validPlayers[players[i]]=true;
            playerTeam[players[i]] = teams[i];

        }
        return true;

    } // Should add address in Game array and put true in the mapping


    function removePlayers(uint gameId, address[] calldata players) external returns(bool success){
        for(uint i=0; i<=30; i++)
        {
            games[gameId].validPlayers[players[i]]=false;
        }
        require (players.length > 1, "removePlayers doesn't work");
        return true;
    } // Should put false in the mapping

    function getPlayers(uint gameId) view external returns(address[] memory) // Go through the array and happen if mapping is true
    {
        require (gameId < nextGameId, "The game exist");


        Game storage game = games[gameId];
        address[] memory players= new address[](game.players.length);
        uint j = 0;
        for (uint i=0;i<game.players.length;i++)
        {
            if(game.validPlayers[game.players[i]])
            {
                players[j] = game.players[i];
                j++;
            }

        }
        return players;

    }

    function getPlayerStatus(uint gameId, uint8 roundId, address player)
    view external returns(bool validPlayer, uint8 team, address[] memory targets,
        uint8 fries, uint8 votes, uint256 potatoes) { //prototype has been modified

        require (gameId < nextGameId, "the game doesn't exists");
        require (roundId < games[gameId].nextRoundId, "The round doesn't exists");

        team = playerTeam[player];
        targets = games[gameId].rounds[roundId].targets[player];
        fries = games[gameId].rounds[roundId].fries[player];
        votes = games[gameId].rounds[roundId].votes[player];
        potatoes = games[gameId].rounds[roundId].potatoes[playerTeam[player]]; // incorrect : donne les patates de la team

        if (!games[gameId].validPlayers[player])
            return(false, team, targets, fries, votes, potatoes);
        return(true, team, targets, fries, votes, potatoes);
    } // Go through game & round to get base info then through potatoes to check if he owns some

    function assignTargets(uint gameId, uint8 roundId, address player, address[] memory targets) //prototype has been modified
    public returns(bool success) { // Assign targets for a player. the randomness will be done offchain

        require (gameId < nextGameId, "the game doesn't exists");
        require (roundId < games[gameId].nextRoundId, "The round doesn't exists");
        require (games[gameId].validPlayers[player], "the player doesn't exists in this game");
        require (targets.length >= 3, "number of random target addresses must be at least 3");

        bool areFromOtherTeams = true;
        for(uint j = 0; j<3; j++){
            if(playerTeam[targets[j]] == playerTeam[player])
                areFromOtherTeams = false;
        }

        require(areFromOtherTeams,"random target adresses must be from another team than player's one");

        for(uint i = 0; i<3; i++){
            games[gameId].rounds[roundId].targets[player][i] = targets[i];
        }

        return true;
    }
    function scanTarget(uint gameId, uint8 roundId, address target, bytes32 secret, bytes calldata signature) external returns(bool success){ // test secret against hash then if ok transfer potatoes and win 1 frie. target has to be in player array
        require (gameId < nextGameId, "The game exist");
        require(roundId < games[gameId].nextRoundId);
        require (playerTeam[target] == playerTeam[msg.sender]);

        require(keccak256(abi.encodePacked(target, secret)).toEthSignedMessageHash().recover(signature) == target);
        games[gameId].rounds[roundId].fries[msg.sender]++;
        return success ;
    }

    function voteAgainst(uint gameId, uint8 roundId, address candidate) external returns(bool success){ // Use fries to vote against one of your teammate.
        require (gameId < nextGameId, "The game exist");
        require(roundId < games[gameId].nextRoundId);
        //require (fries > 0, "you need fries");
        require (playerTeam[candidate] == playerTeam[msg.sender]);

        games[gameId].rounds[roundId].votes[candidate]++;
        games[gameId].rounds[roundId].fries[msg.sender]--;
        return success;
    }
}