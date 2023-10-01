pragma solidity ^0.8.9;

import "hardhat/console.sol";

contract Bank{

    address payable private bank; 
    uint256 private balance;

    constructor() {
        //TODO set bank address
        balance = 0;
    }

    function payUser(address payable user, uint256 amount) public {
        require(balance >= amount, "Bank is broke lol");
        user.transfer(amount);
    }

    function getBankAddress() public returns(address payable) {
        return bank;
    }

    function getBankBalance() public returns(uint256) {
        return balance;
    }

    // transfer to user
}

contract Marbles {
    Bank bankObj;

    //required marble coin fields
    string public name = "Marbles";
    string public symbol = "MARBLE";
    uint256 public totalMarbles = 100000;

    //initalize accounts
    address public marbleJar;

    mapping(address => uint256) balances;
    mapping(address => Goal[]) userGoals;

    //static uint256/string addresses for marblejar and bank

    // The Transfer event helps off-chain aplications understand
    // what happens within your contract.
    //event Transfer(address indexed _from, address indexed _to, uint256 _value);
    //event TransferToBank(uint8 coinType, uint256 amount);

    /**
     * default constructor that initializes addresses
     */
    constructor() {
        //marbleJar = static marblejar Address;
        balances[msg.sender] = 0;
    }


    //TODO - handling base currency from user???

    //goal object
    struct Goal {
        uint256 hashInt;
        string name;
        string date;
        string description;
        uint256 accountability;
        int256 complete;
    }

    function stringToUint(string memory s) pure internal returns (uint256 result) {
        bytes memory b = bytes(s);
        uint256 i;
        result = 0;
        for (i = 0; i < b.length; i++) {
            uint256 c = uint256(uint8(b[i]));
            if (c >= 48 && c <= 57) {
                result = result * 10 + (c - 48);
            }
        }
    }

    function convertDateToTimestamp(string memory date) public pure returns (uint256) {
        bytes memory b = bytes(date);

        // Extract month, day, year from the string
        string memory monthStr = new string(2);
        bytes memory monthBytes = bytes(monthStr);
        monthBytes[0] = b[0];
        monthBytes[1] = b[1];

        string memory dayStr = new string(2);
        bytes memory dayBytes = bytes(dayStr);
        dayBytes[0] = b[3];
        dayBytes[1] = b[4];

        string memory yearStr = new string(4);
        bytes memory yearBytes = bytes(yearStr);
        for(uint i=0; i<4; i++) {
            yearBytes[i] = b[i + 6];
        }

        uint256 month = stringToUint(monthStr);
        uint256 day = stringToUint(dayStr);
        uint256 year = stringToUint(yearStr);

        // This assumes the provided date is UTC.
        // You might need more logic to handle dates properly, including leap years, different months, etc.
        return (year - 1970) * 31536000 + (month - 1) * 2678400 + (day - 1) * 86400;
    }        /**
     * creates a goal for the user
     * @param h hashstring of goal
     * @param g name of goal
     * @param desc decsription of goal
     * @param d date of goal creation
     * @param a accountability money given for goal
     */
    function createGoal(uint256 h, string memory g, string memory desc, string memory d, uint256 a) public {
        //Goal storage goal = User.goals[id]; //figure out id later (goal ids separate)

        Goal memory newGoal = Goal({
            hashInt: h,
            name: g,
            description: desc,
            date: d,
            accountability: a,
            complete: 0
        });

        // Append the new goal to the user's goals
        userGoals[msg.sender].push(newGoal);
    }

    /**
     * checks if the goal is complete or not
     */
    function checkGoals() public {
        uint256 currentTimestamp = block.timestamp; // Get the current block timestamp

        for (uint256 i = 0; i < userGoals[msg.sender].length; i++) {
            string memory goalDate = userGoals[msg.sender][i].date;

            // Convert the goal date string to a timestamp (date is in mm-dd-yyy format)

            uint256 goalTimestamp = convertDateToTimestamp(goalDate);

            // Check if the goal date has passed (compare timestamps)
            if (goalTimestamp <= currentTimestamp) {
                userGoals[msg.sender][i].complete = -1;
            }
        }
    }

    /**
     * returns the user's goals
     * @return userGoals array of user's goals
     */
    function getGoals() public returns(Goal[] memory) {
        return userGoals[msg.sender];
    }

    function completeGoal (uint256 hashInt) public {
        uint256 amount = 0;
        for (uint256 i = 0; i < userGoals[msg.sender].length; i++) {
            if (hashInt == userGoals[msg.sender][i].hashInt) {
                amount = userGoals[msg.sender][i].accountability;
                userGoals[msg.sender][i].complete = 1;
            }
        }
        //payFromBank(amount);
        bankObj.payUser(payable(msg.sender), amount);
        addMarble();
    }

    /**
     * Sends the money from the user to the bank account
     * @param amount of accountability money sent
    */
    function sentEthToBank(uint256 amount) public {
        //check for sufficient balance
        require(balances[msg.sender] < 0 || balances[msg.sender] >= amount, "Invalid balance");

        //console message on hardhat network
        /*
        console.log(
            "Transferring from %s to %s 0.%s tokens",
            msg.sender,
            Bank.bank,
            amount
        );
        */
        
        //transfer the etherium
        bankObj.getBankAddress().transfer(amount);
    }

    function addMarble() public {
        balances[msg.sender]++;
    }

    
    /**
     * read-only function to check account balance
     * @param account account being checked
     */
    function balanceOf(address account) external view returns (uint256) {
        return balances[account];
    }

}