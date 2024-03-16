// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
// import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

//import "./IERC20.sol";


contract DEX5000 is ERC20{

    IERC20 public token0;
    IERC20 public token1;
    uint256 public conversionRate = 5000 * (10**4) ;
    mapping(address => uint) public token0Balances;
    mapping(address => uint) public token1Balances;
    mapping(address => uint) public balances;
    
    /* 
    "balances" is based on token0
        ex. token1: 10000, token0: 20000, conversionRate: 5000(0.5) --> balance = 10000*0.5 + 20000
    */

    constructor(address _token0, address _token1) ERC20("DEX5000", "DEX5000") {
        token0 = IERC20(_token0);
        token1 = IERC20(_token1);
    }

    function trade(address tokenFrom, uint256 fromAmount) public {
        if(tokenFrom == address(token0)){
            uint256 amountToken1 = fromAmount * 10**8 / conversionRate ;
            if(token1Balances[address(this)] < amountToken1) revert("not enough token1"); // Revert when pool is not enough

            // Transfer token
            token0.transferFrom(msg.sender, address(this), fromAmount);
            token0Balances[address(this)] += fromAmount;
            token1.transfer(msg.sender, amountToken1);
            token1Balances[address(this)] -= amountToken1;
        }

        else if(tokenFrom == address(token1)){
            uint256 amountToken0 = fromAmount * conversionRate / 10**8 ;
            if(token0Balances[address(this)] < amountToken0) revert("not enough token0"); // Revert when pool is not enough

            // Transfer token
            token1.transferFrom(msg.sender, address(this), fromAmount);
            token1Balances[address(this)] += fromAmount;
            token0.transfer(msg.sender, amountToken0);
            token0Balances[address(this)] -= amountToken0;
        }
        else revert("not allowed token");
    }

    function provideLiquidity(uint256 token0Amount, uint256 token1Amount) public {

        // Initial state with no restriction
        if(token0Balances[address(this)] == 0 && token1Balances[address(this)] == 0){
            token0.transferFrom(msg.sender, address(this), token0Amount);
            token1.transferFrom(msg.sender, address(this), token1Amount);

            token0Balances[msg.sender] += token0Amount;
            token1Balances[msg.sender] += token1Amount;
            token0Balances[address(this)] += token0Amount;
            token1Balances[address(this)] += token1Amount;
            balances[msg.sender] += token0Amount + token1Amount * conversionRate / 10**8 ;
            balances[address(this)] += token0Amount + token1Amount * conversionRate / 10**8 ;

        }
        
        // Only transfer token1
        else if(token0Balances[address(this)] == 0){
            token1.transferFrom(msg.sender, address(this), token1Amount);
            token1Balances[msg.sender] += token1Amount;
            token1Balances[address(this)] += token1Amount;
            balances[msg.sender] += token1Amount * conversionRate / 10**8 ;
            balances[address(this)] += token1Amount * conversionRate / 10**8 ;

        }
        
        // Only transfer token0
        else if(token1Balances[address(this)] == 0){
            token0.transferFrom(msg.sender, address(this), token0Amount);
            token0Balances[msg.sender] += token0Amount;
            token0Balances[address(this)] += token0Amount;
            balances[msg.sender] += token0Amount;
            balances[address(this)] += token0Amount;

        }
        
        // Transfer with current ratio
        else{
            uint256 ratio = token1Balances[address(this)] * 10**5 / token0Balances[address(this)]; // Use 5 decimal
            if(token1Amount >= token0Amount * ratio / 10**5){
                token0.transferFrom(msg.sender, address(this), token0Amount);
                token1.transferFrom(msg.sender, address(this), token0Amount * ratio / 10**5);

                token0Balances[msg.sender] += token0Amount;
                token1Balances[msg.sender] += token0Amount * ratio / 10**5;
                token0Balances[address(this)] += token0Amount;
                token1Balances[address(this)] += token0Amount * ratio / 10**5;
                balances[msg.sender] += token0Amount + token0Amount * ratio * conversionRate / 10**13 ;
                balances[address(this)] += token0Amount + token0Amount * ratio * conversionRate / 10**13 ;
            }else{
                token0.transferFrom(msg.sender, address(this), token1Amount * 10**5 / ratio);
                token1.transferFrom(msg.sender, address(this), token1Amount);

                token0Balances[msg.sender] += token1Amount * 10**5 / ratio;
                token1Balances[msg.sender] += token1Amount;
                token0Balances[address(this)] += token1Amount * 10**5 / ratio;
                token1Balances[address(this)] += token1Amount;
                balances[msg.sender] += token1Amount * 10**5 / ratio + token1Amount * conversionRate / 10**8 ;
                balances[address(this)] += token1Amount * 10**5 / ratio + token1Amount * conversionRate / 10**8 ;
            }
        }
    }

    function withdrawLiquidity() public payable{
        uint amountToken0 = balances[msg.sender] * token0Balances[address(this)] / balances[address(this)];
        uint amountToken1 = (balances[msg.sender] * token1Balances[address(this)] * conversionRate / balances[address(this)]) / 10**8;
        

        // Transfer amount cannot be zero
        if(amountToken0 != 0) token0.transfer(msg.sender, amountToken0);
        if(amountToken1 != 0) token1.transfer(msg.sender, amountToken1);
        
        token0Balances[msg.sender] = 0;
        token1Balances[msg.sender] = 0;
        balances[msg.sender] = 0;

        token0Balances[address(this)] -= amountToken0;
        token1Balances[address(this)] -= amountToken1;
        balances[address(this)] -= (amountToken0 + amountToken1 * conversionRate / 10**8 );
    }
} 