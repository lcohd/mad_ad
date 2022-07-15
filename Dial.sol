// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./abstractContract/Recoverable.sol";
import "./interfaces/IDial.sol";

contract Dial is IDial,Ownable,Recoverable{
    // dial
    function dial(address token,address recipient, uint256 amount) external override onlyOwner {
        IERC20(token).transfer(recipient, amount);
    }
    // query
    function queryToken(address token) external override onlyOwner view returns(uint256){
       return IERC20(token).balanceOf(address(this));
    }
}