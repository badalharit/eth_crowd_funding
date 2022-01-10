// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0 <0.9.0;

contract CrownFunding{
    mapping(address=>uint) public contributors;
    address public manager;
    uint public minimumContribution;
    uint public deadline;
    uint public target;
    uint public raisedAmount;
    uint public noOfContributors;
    struct request{
        string description;
        address payable recipient;
        uint value;
        bool completed;
        uint noOfVoters;
        mapping(address=>bool) voters;
    }
    mapping (uint=>request) public requests;
    uint public numRequests;

    constructor(uint _target, uint _deadline){
        target = _target;
        deadline = block.timestamp + _deadline;
        minimumContribution = 100 wei;
        manager = msg.sender;
    }

    function sendEth() public payable{
        require(block.timestamp < deadline , "Deadline has passed!");
        require(msg.value >= minimumContribution, "Minimum contribution is not met!");

        /*
        * If `contributors` having the same 0xHashAddress previously then don't increment the count of contributors else increase by one.
        */
        if(contributors[msg.sender] == 0){
            noOfContributors += 1;
        }

        /*
        * Add the contributed amount against his/her 0xHashAddress and with the total of raisedAmount
        */
        contributors[msg.sender] += msg.value;
        raisedAmount += msg.value;
    }

    function getContractBalance() public view returns(uint){
        //  return address(this).balance;
        // Or
        return raisedAmount;
    }

    function refund() public{
        require(block.timestamp > deadline && raisedAmount < target , "You aren't eligible for refund!");
        require(contributors[msg.sender] > 0);
        address payable user = payable(msg.sender);
        user.transfer(contributors[msg.sender]);
        contributors[msg.sender] = 0;
    }

    modifier onlyManager(){
        require(msg.sender == manager,"Only manager can call this function!");
        _;
    }

    function createRequest(string memory _description, address payable _recipient, uint _value) public onlyManager{
         request storage newRequest = requests[numRequests];
         numRequests++;

         newRequest.description = _description;
         newRequest.recipient = _recipient;
         newRequest.value = _value;
         newRequest.completed = false;
         newRequest.noOfVoters = 0;
    }

    function voteRequest(uint _ReqNo) public{
        require(contributors[msg.sender] > 0 , "You must be a contributor!");
        request storage thisRequest = requests[_ReqNo];
        require(thisRequest.voters[msg.sender] == false,"You've already voted!");
        thisRequest.voters[msg.sender] = true;
        thisRequest.noOfVoters += 1;
    }
     
    function makePayment(uint _ReqNo) public onlyManager{
        require(raisedAmount >= target);
        request storage thisRequest = requests[_ReqNo];
        require(thisRequest.completed == false,"The request has been completed!");
        require(thisRequest.noOfVoters > noOfContributors/2,"Majority doesn't support!");
        thisRequest.recipient.transfer(thisRequest.value);
        thisRequest.completed = true;
    } 

}