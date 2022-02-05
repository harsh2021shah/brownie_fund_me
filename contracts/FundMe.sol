// SPDX-License-Identifier: MIT

pragma solidity ^0.6.6;

import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";
// Check for overflows only while using solidity versions less tha 0.8
import "@chainlink/contracts/src/v0.6/vendor/SafeMathChainlink.sol";

contract FundMe {
    using SafeMathChainlink for uint256;

    // mapping - to track the funds funded to this contract and increment it to the below variable
    mapping(address => uint256) public addressToAmountFunded;
    address[] public funders;
    address public owner;

    AggregatorV3Interface public priceFeed;

    constructor(address _priceFeed) public {
        priceFeed = AggregatorV3Interface(_priceFeed);
        owner = msg.sender; // Whoever that deploys this contract
    }

    function fund() public payable returns (uint256) {
        // Using this single line we can fund this smart contract, 1. Deploy, 2. Put value and call this function
        // The transactions gets completed only if this function Executes completely, including any require statements
        uint256 minimumUsd = 50 * 10**18; // for 18 decimals
        // Below line check if the given condition is satisfied, if not it stops the funciton execution
        require(
            getConversionRate(msg.value) >= minimumUsd,
            "You need to spend more ETH!"
        ); // OR // if (msg.value < minimumUsd) {revert?};
        addressToAmountFunded[msg.sender] += msg.value;
        funders.push(msg.sender);
    }

    function getVersion() public view returns (uint256) {
        // https://github.com/smartcontractkit/chainlink/blob/develop/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol
        // use this to find the Price Feed Addresses - https://docs.chain.link/docs/ethereum-addresses/
        // Here we will define the variable for working with other contracts same as the way we define variable using structs
        // Below line says.. the functions defined in the interface are located on this address

        // NO LONGER NEED BELOW LINE COZ WE CREATED A CONSTRUCTOR VARIABLE FOR THE SAME
        // AggregatorV3Interface priceFeed = AggregatorV3Interface(
        //     0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        // );

        // then we can call the below method / function which gives the "Aggregators" version
        return priceFeed.version();
    }

    function getPrice() public view returns (uint256) {
        // AggregatorV3Interface priceFeed = AggregatorV3Interface(
        //     0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        // );
        // Get the price data from interface
        (, int256 answer, , , ) = priceFeed.latestRoundData();
        return uint256(answer * 1000000000); //261604000000000000000
    }

    function getConversionRate(uint256 ethAmount)
        public
        view
        returns (uint256)
    {
        uint256 ethPrice = getPrice();
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 100000000000000000;
        return ethAmountInUsd;
    }

    function getEntranceFee() public view returns (uint256) {
        // minimumUSD
        uint256 minimumUSD = 50 * 10**18;
        uint256 price = getPrice();
        uint256 precision = 1 * 10**18;
        return (minimumUSD * precision) / price;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the Owner can Withdraw");
        _;
    }

    // Withdraw function to send ethereum
    function withdraw() public payable onlyOwner {
        // Below makes the funds withdrawable by only the owner of the contract
        // require(msg.sender == owner); // Instead of this here, we got the modifier "onlyOwner"
        // Below says, whoever calls this functions gets all the funds
        msg.sender.transfer(address(this).balance); // here "this" means this contract & address(this) means address of this contract
        // msg.sender.transfer(0xCe3a5D90c50D315B28fd44CD0aD773d6cc785a74.balance);

        // Below will loop into the funders array and will reset the amount of that address to 0, when that address withdraws
        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex++
        ) {
            address funder = funders[funderIndex];
            addressToAmountFunded[funder] = 0;
        }
        funders = new address[](0);
    }

    function sendEth() public payable {
        //  SUCCESSSSSSSS... eth sent to RUSHIKESH
        payable(address(0x6d4C75f968b2D5512567de557aC41cA5120E8D99)).transfer(
            msg.value
        );
    }
}
