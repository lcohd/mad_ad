// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IDial {
    function dial(address token,address recipient, uint256 amount) external;
    function queryToken(address token) external view returns(uint256);
}