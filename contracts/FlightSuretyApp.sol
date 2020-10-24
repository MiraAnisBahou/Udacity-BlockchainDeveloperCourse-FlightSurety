pragma solidity ^0.4.25;

// It's important to avoid vulnerabilities due to numeric overflow bugs
// OpenZeppelin's SafeMath library, when used correctly, protects agains such bugs
// More info: https://www.nccgroup.trust/us/about-us/newsroom-and-events/blog/2018/november/smart-contract-insecurity-bad-arithmetic/

import "../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";

/************************************************** */
/* FlightSurety Smart Contract                      */
/************************************************** */
contract FlightSuretyApp {
    using SafeMath for uint256; // Allow SafeMath functions to be called for all uint256 types (similar to "prototype" in Javascript)

    /********************************************************************************************/
    /*                                       DATA VARIABLES                                     */
    /********************************************************************************************/

    FlightSuretyData flightSuretyData;
    uint256 private airlinesPresent = 1; //To count the first 4 registered airlines (1 since first airline is registered in the constructor).
    address[] multipleCalls = new address[](0); //For multi-party consensus.
    uint256 public constant AIRLINE_FEE = 10 ether; //10 ether required to be paid by each registered airline.
    mapping(address => uint256) airlineRegistered; //If 1 means that airline is registered, if 0 airline is not registered.
    mapping(address => uint256) airlinePaidFunds; //If 1 means that airline has paid 10 ether, if 0 airline didn't pay yet. (If it paid it means that is now authorized to participate in the contract.)
    mapping(address => uint256) flightRegistered; //If 1 means that flight is registered, if 0 flight is not registered.
    // Flight status codees
    uint8 private constant STATUS_CODE_UNKNOWN = 0;
    uint8 private constant STATUS_CODE_ON_TIME = 10;
    uint8 private constant STATUS_CODE_LATE_AIRLINE = 20;
    uint8 private constant STATUS_CODE_LATE_WEATHER = 30;
    uint8 private constant STATUS_CODE_LATE_TECHNICAL = 40;
    uint8 private constant STATUS_CODE_LATE_OTHER = 50;

    address private contractOwner; // Account used to deploy contract

    struct Flight {
        bool isRegistered;
        uint8 statusCode;
        uint256 updatedTimestamp;
        address airline;
    }

    mapping(bytes32 => Flight) private flights;
    mapping(bytes32 => address) private addressOfRequester; //To get the address of the person that requests the flight's status.

    /********************************************************************************************/
    /*                                       FUNCTION MODIFIERS                                 */
    /********************************************************************************************/

    // Modifiers help avoid duplication of code. They are typically used to validate something
    // before a function is allowed to be executed.

    /**
     * @dev Modifier that requires the "operational" boolean variable to be "true"
     *      This is used on all state changing functions to pause the contract in
     *      the event there is an issue that needs to be fixed
     */
    modifier requireIsOperational() {
        // Modify to call data contract's status
        require(true, "Contract is currently not operational");
        _; // All modifiers require an "_" which indicates where the function body will be added
    }

    /**
     * @dev Modifier that requires the "ContractOwner" account to be the function caller
     */
    modifier requireContractOwner() {
        require(msg.sender == contractOwner, "Caller is not contract owner");
        _;
    }

    modifier requireAirlineRegistered() {
        //I added this modifier to make sure that the airline is registerd.
        require(
            airlineRegistered[msg.sender] == 1,
            "Airline is not registered!"
        );
        _;
    }

    modifier requireAirlinePaidFunds() {
        //I added this modifier to make sure that the airline paid the 10 ether and is now authorized to participate in the contract.
        require(
            airlinePaidFunds[msg.sender] == 1,
            "Airline didn't pay the 10 ether!"
        );
        _;
    }

    modifier paidEnough() {
        //I added this modifier to make sure that the airline is sending at least 10 ether.
        require(msg.value >= AIRLINE_FEE, "Airline didn't send enough funds!");
        _;
    }

    modifier returnExtraFunds() {
        //I added this modifier to make sure that if airline sent more than 10 ether, extra paid ether will be paid back to it.
        uint256 amountToSendBack = msg.value - AIRLINE_FEE;
        if (amountToSendBack > 0) {
            (msg.sender).transfer(amountToSendBack);
        }
        _;
    }

    /********************************************************************************************/
    /*                                       CONSTRUCTOR                                        */
    /********************************************************************************************/

    /**
     * @dev Contract constructor
     *
     */
    constructor(address dataCont) public {
        contractOwner = msg.sender;
        flightSuretyData = FlightSuretyData(dataCont);
        // flightSuretyData.registerAirline(msg.sender, "Airline_A");
        airlineRegistered[msg.sender] = 1; //Airline is now registered.
        //airlinesPresent = airlinesPresent + 1; //Since the airlines now increased.
    }

    /********************************************************************************************/
    /*                                       UTILITY FUNCTIONS                                  */
    /********************************************************************************************/

    function isOperational() public returns (bool) {
        return flightSuretyData.isOperational(); // Modify to call data contract's status
    }

    /********************************************************************************************/
    /*                                     SMART CONTRACT FUNCTIONS                             */
    /********************************************************************************************/

    /**
     * @dev Add an airline to the registration queue
     *
     */

    function registerAirline(address airline, string nameOfAirline)
        external
        requireIsOperational //Make sure that the app contract is operational.
        requireAirlineRegistered ////Make sure that the airline is registered.
        requireAirlinePaidFunds //Make sure that the airline paid the 10 ether.
    //returns (bool success, uint256 votes)
    {
        require(isOperational()); //Make sure that Data contract is operational.
        if (airlinesPresent <= 3) {
            airlinesPresent = airlinesPresent + 1;
            airlineRegistered[airline] = 1;
            flightSuretyData.registerAirline(airline, nameOfAirline);
            // success = true;
            // votes = 0; //Since there was no voting here.
            //return (success, votes);
        } else {
            bool duplication = false;
            for (uint256 m = 0; m < multipleCalls.length; m++) {
                if (multipleCalls[m] == msg.sender) {
                    // If the current caller is already in the array, then set duplication to true
                    duplication = true;
                    break;
                }
            }
            require(!duplication, "Airline already voted!"); // If there is a duplicate to not complete execution as this would cost money for nothing
            multipleCalls.push(msg.sender);
            if (airlinesPresent % 2 == 0) {
                //Even number of airlines registered.
                if (multipleCalls.length >= airlinesPresent / 2) {
                    airlinesPresent = airlinesPresent + 1;
                    airlineRegistered[airline] = 1;
                    flightSuretyData.registerAirline(airline, nameOfAirline);
                    // success = true;
                    // votes = multipleCalls.length;
                    multipleCalls = new address[](0);
                    //return (success, votes);
                }
            } else if (airlinesPresent % 2 != 0) {
                //Odd number of airlines registered.
                if (multipleCalls.length >= (airlinesPresent / 2) + 1) {
                    airlinesPresent = airlinesPresent + 1;
                    airlineRegistered[airline] = 1;
                    flightSuretyData.registerAirline(airline, nameOfAirline);
                    // success = true;
                    // votes = multipleCalls.length;
                    multipleCalls = new address[](0);
                    //return (success, votes);
                }
            }
        }

        //return (success, 0);
    }

    function fund(address airline)
        public
        payable
        requireIsOperational //Make sure that the app contract is operational.
        requireAirlineRegistered //Make sure that the airline is registered.
        paidEnough //Make sure that the airline sent at least 10 ether.
        returnExtraFunds //Make sure the airline is given back the extra money that it sent (if it sent more than 10 ether).
    {
        require(isOperational()); //Make sure that Data contract is operational.
        flightSuretyData.fund.value(AIRLINE_FEE)(airline);
        airlinePaidFunds[airline] = 1; //Airline paid the 10 ether.
    }

    /**
     * @dev Register a future flight for insuring.
     *
     */

    function registerFlight(
        address airlineAd,
        string flight,
        uint256 timestamp
    )
        external
        requireIsOperational //Make sure that the app contract is operational.
    {
        flightRegistered[msg.sender] = 0;
        require(
            airlineRegistered[airlineAd] == 1,
            "Airline is not registered!"
        );
        bytes32 key = getFlightKey(airlineAd, flight, timestamp);
        flights[key] = Flight({
            isRegistered: true,
            statusCode: 0,
            updatedTimestamp: timestamp,
            airline: airlineAd
        });
        flightRegistered[msg.sender] = 1;
        flightSuretyData.flightData(msg.sender);
    }

    function retrieveRegisteredFlight() public returns (uint256) {
        return flightRegistered[msg.sender];
    }

    /**
     * @dev Called after oracle has updated flight status
     *
     */

    function processFlightStatus(
        address airline,
        string memory flight,
        uint256 timestamp,
        uint8 statusCode
    ) internal {
        bytes32 key = getFlightKey(airline, flight, timestamp);
        require(airlineRegistered[airline] == 1);
        if (
            statusCode == STATUS_CODE_LATE_AIRLINE ||
            statusCode == STATUS_CODE_LATE_TECHNICAL
        ) {
            flightSuretyData.creditInsurees(addressOfRequester[key]);
        }
        flights[key].statusCode = statusCode;
        delete addressOfRequester[key];
    }

    // Generate a request for oracles to fetch flight information
    function fetchFlightStatus(
        address airline,
        string flight,
        uint256 timestamp
    ) external {
        uint8 index = getRandomIndex(msg.sender);

        // Generate a unique key for storing the request
        bytes32 key = keccak256(
            abi.encodePacked(index, airline, flight, timestamp)
        );
        oracleResponses[key] = ResponseInfo({
            requester: msg.sender,
            isOpen: true
        });
        bytes32 key2 = getFlightKey(airline, flight, timestamp);
        addressOfRequester[key2] = msg.sender;

        emit OracleRequest(index, airline, flight, timestamp);
    }

    // region ORACLE MANAGEMENT

    // Incremented to add pseudo-randomness at various points
    uint8 private nonce = 0;

    // Fee to be paid when registering oracle
    uint256 public constant REGISTRATION_FEE = 1 ether;

    // Number of oracles that must respond for valid status
    uint256 private constant MIN_RESPONSES = 3;

    struct Oracle {
        bool isRegistered;
        uint8[3] indexes;
    }

    // Track all registered oracles
    mapping(address => Oracle) private oracles;

    // Model for responses from oracles
    struct ResponseInfo {
        address requester; // Account that requested status
        bool isOpen; // If open, oracle responses are accepted
        mapping(uint8 => address[]) responses; // Mapping key is the status code reported
        // This lets us group responses and identify
        // the response that majority of the oracles
    }

    // Track all oracle responses
    // Key = hash(index, flight, timestamp)
    mapping(bytes32 => ResponseInfo) private oracleResponses;

    // Event fired each time an oracle submits a response
    event FlightStatusInfo(
        address airline,
        string flight,
        uint256 timestamp,
        uint8 status
    );

    event OracleReport(
        address airline,
        string flight,
        uint256 timestamp,
        uint8 status
    );

    // Event fired when flight status request is submitted
    // Oracles track this and if they have a matching index
    // they fetch data and submit a response
    event OracleRequest(
        uint8 index,
        address airline,
        string flight,
        uint256 timestamp
    );

    // Register an oracle with the contract
    function registerOracle()
        external
        payable
        requireIsOperational //Make sure that the app contract is operational.
    {
        // Require registration fee
        require(msg.value >= REGISTRATION_FEE, "Registration fee is required");

        uint8[3] memory indexes = generateIndexes(msg.sender);

        oracles[msg.sender] = Oracle({isRegistered: true, indexes: indexes});
    }

    function getMyIndexes() external view returns (uint8[3] memory) {
        require(
            oracles[msg.sender].isRegistered,
            "Not registered as an oracle"
        );

        return oracles[msg.sender].indexes;
    }

    // Called by oracle when a response is available to an outstanding request
    // For the response to be accepted, there must be a pending request that is open
    // and matches one of the three Indexes randomly assigned to the oracle at the
    // time of registration (i.e. uninvited oracles are not welcome)
    function submitOracleResponse(
        uint8 index,
        address airline,
        string flight,
        uint256 timestamp,
        uint8 statusCode
    )
        external
        requireIsOperational //Make sure that the app contract is operational.
    {
        require(
            (oracles[msg.sender].indexes[0] == index) ||
                (oracles[msg.sender].indexes[1] == index) ||
                (oracles[msg.sender].indexes[2] == index),
            "Index does not match oracle request"
        );

        bytes32 key = keccak256(
            abi.encodePacked(index, airline, flight, timestamp)
        );
        require(
            oracleResponses[key].isOpen,
            "Flight or timestamp do not match oracle request"
        );

        oracleResponses[key].responses[statusCode].push(msg.sender);

        // Information isn't considered verified until at least MIN_RESPONSES
        // oracles respond with the *** same *** information
        emit OracleReport(airline, flight, timestamp, statusCode);
        if (
            oracleResponses[key].responses[statusCode].length >= MIN_RESPONSES
        ) {
            emit FlightStatusInfo(airline, flight, timestamp, statusCode);

            // Handle flight status as appropriate
            processFlightStatus(airline, flight, timestamp, statusCode);
        }
    }

    function getFlightKey(
        address airline,
        string flight,
        uint256 timestamp
    ) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(airline, flight, timestamp));
    }

    // Returns array of three non-duplicating integers from 0-9
    function generateIndexes(address account)
        internal
        requireIsOperational //Make sure that the app contract is operational.
        returns (uint8[3])
    {
        uint8[3] memory indexes;
        indexes[0] = getRandomIndex(account);

        indexes[1] = indexes[0];
        while (indexes[1] == indexes[0]) {
            indexes[1] = getRandomIndex(account);
        }

        indexes[2] = indexes[1];
        while ((indexes[2] == indexes[0]) || (indexes[2] == indexes[1])) {
            indexes[2] = getRandomIndex(account);
        }

        return indexes;
    }

    // Returns array of three non-duplicating integers from 0-9
    function getRandomIndex(address account) internal returns (uint8) {
        uint8 maxValue = 10;

        // Pseudo random number...the incrementing nonce adds variation
        uint8 random = uint8(
            uint256(
                keccak256(
                    abi.encodePacked(blockhash(block.number - nonce++), account)
                )
            ) % maxValue
        );

        if (nonce > 250) {
            nonce = 0; // Can only fetch blockhashes for last 256 blocks so we adapt
        }

        return random;
    }

    // endregion
}

contract FlightSuretyData {
    function isOperational() public view returns (bool);

    function fund(address sender) public payable;

    function registerAirline(address airline, string nameOfAirline) external;

    function creditInsurees(address passenger) external;

    function flightData(address flight) public;
}
