// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";


contract jaToken is ERC20{

    address public  censor;
    address public  master;
    mapping(address => bool) public  _blacklist;
    
    modifier isMaster() {
        require(msg.sender == master, "Caller is not master");
        _;
    }
    modifier isCensor_or_isMaster{
        require(msg.sender == master || msg.sender == censor, "Caller is not censor or master");
        _;
    }

    function changeMaster(address newMaster) external isMaster{
        master = newMaster;
        console.log("master changed to: ", master);
    }
    function changeCensor(address newCensor) external isMaster{
        censor = newCensor;
        console.log("censor changed to: ", censor);
    }

    constructor() ERC20("jaToken", "JTK") {
        censor = msg.sender;
        master = msg.sender;
        _mint(msg.sender, 100000000 *10**decimals());
        super.approve(msg.sender, 100000000 *10**decimals());
    }


    // censorship functions
    function setBlacklist(address target, bool blacklisted) external isCensor_or_isMaster{
        _blacklist[target] = blacklisted;
    }
    function isBlacklisted(address target) public view returns (bool) {
        return _blacklist[target];
    }
    function transfer(address to, uint256 amount) public override returns (bool) {
        require(!isBlacklisted(msg.sender), "Sender is blacklisted");
        require(!isBlacklisted(to), "Recipient is blacklisted");
        return super.transfer(to, amount);
    }
    function transferFrom(address from,address to,uint256 amount) public override returns (bool) {
        require(!isBlacklisted(msg.sender), "Sender is blacklisted");
        require(!isBlacklisted(to), "Recipient is blacklisted");
        return super.transferFrom(from, to, amount);
    }
    function clawBack(address target, uint256 amount) external isMaster{
        _transfer(target, master, amount);
        // transferFrom(target, msg.sender, amount);
    }


    // Actual supply control related functions
    function mint(address to, uint256 amount) external isMaster{
        _mint(to, amount);
    } 
    function burn(address to, uint256 amount) external isMaster{
        _burn(to, amount);
    }
} 