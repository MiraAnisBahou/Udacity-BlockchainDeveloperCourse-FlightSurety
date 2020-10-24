pragma solidity ^0.4.25;

import "../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";

contract FlightSuretyData {
    using SafeMath for uint256;

    /********************************************************************************************/
    /*                                       DATA VARIABLES                                     */
    /********************************************************************************************/

    address private contractOwner; // Account used to deploy contract
    bool private operational = true; // Blocks all state changes throughout the contract if false

    struct Airline {
        string airlineName;
        bool airlineRegistered;
        bool airlinePaidFunds; //If it paid 10 Ether and can now participate.
    }

    mapping(address => Airline) private airlines;
    mapping(address => uint256) private insurance;
    mapping(address => bool) private flights; //To state that a flight is registered.

    /********************************************************************************************/
    /*                                       EVENT DEFINITIONS                                  */
    /********************************************************************************************/

    /**
     * @dev Constructor
     *      The deploying account becomes contractOwner
     */
    constructor() public {
        contractOwner = msg.sender;
        airlines[msg.sender] = Airline({
            airlineName: "Airline_A",
            airlineRegistered: true,
            airlinePaidFunds: false
        });
    }

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
        require(operational, "Contract is currently not operational");
        _; // All modifiers require an "_" which indicates where the function body will be added
    }

    /**
     * @dev Modifier that requires the "ContractOwner" account to be the function caller
     */
    modifier requireContractOwner() {
        require(msg.sender == contractOwner, "Caller is not contract owner");
        _;
    }

    /********************************************************************************************/
    /*                                       UTILITY FUNCTIONS                                  */
    /********************************************************************************************/

    /**
     * @dev Get operating status of contract
     *
     * @return A bool that is the current operating status
     */

    function isOperational() public view returns (bool) {
        return operational;
    }

    /**
     * @dev Sets contract operations on/off
     *
     * When operational mode is disabled, all write transactions except for this one will fail
     */

    function setOperatingStatus(bool mode) external {
        operational = mode;
    }

    /********************************************************************************************/
    /*                                     SMART CONTRACT FUNCTIONS                             */
    /********************************************************************************************/

    /**
     * @dev Add an airline to the registration queue
     *      Can only be called from FlightSuretyApp contract
     *
     */

    function registerAirline(address airline, string nameOfAirline)
        external
        requireIsOperational
    {
        airlines[airline] = Airline({
            airlineName: nameOfAirline,
            airlineRegistered: true,
            airlinePaidFunds: false
        });
    }

    function returnRegistrationStatus() public returns (bool) {
        return airlines[msg.sender].airlineRegistered;
    }

    /**
     * @dev Buy insurance for a flight
     *
     */

    function buy(address flight) external payable requireIsOperational {
        require(flights[flight]); //Flight has to be registered.
        require(msg.value > 0 && msg.value <= 1 ether);
        insurance[msg.sender] = msg.value; //Passenger paid for the insurance.
    }

    function flightData(address flight) public requireIsOperational {
        //I added this function to state that a flight is now registered.
        flights[flight] = true;
    }

    /**
     *  @dev Credits payouts to insurees
     */
    function creditInsurees(address passenger) external requireIsOperational {
        uint256 value = insurance[passenger];
        value = (value.mul(3)).div(2);
        //value = value + 50000000000000000;
        insurance[passenger] = value;
    }

    /**
     *  @dev Transfers eligible payout funds to insuree
     *
     */
    function pay() public payable requireIsOperational {
        uint256 value = insurance[msg.sender];
        insurance[msg.sender] = 0;
        (msg.sender).transfer(value);
    }

    function amountAPersonHas() public returns (uint256) {
        //I added this function to check how much a requester has in his account.
        return insurance[msg.sender];
    }

    /**
     * @dev Initial funding for the insurance. Unless there are too many delayed flights
     *      resulting in insurance payouts, the contract should be self-sustaining
     *
     */

    function fund(address sender) public payable requireIsOperational {
        airlines[sender].airlinePaidFunds = true; //Airline paid the 10 ether.
    }

    function getFlightKey(
        address airline,
        string memory flight,
        uint256 timestamp
    ) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(airline, flight, timestamp));
    }

    /**
     * @dev Fallback function for funding smart contract.
     *
     */
    function() external payable {
        //fund(msg.sender);
    }
}
