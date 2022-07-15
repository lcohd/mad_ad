// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";


contract MAD is IERC20, Ownable {
	using SafeMath for uint256;
    using Address for address;

    address _liquiditySellFee1Addr = 0xF9b74e1d13D03CbF53c6F2D701C954AD8EDEE83e;
    address _liquiditySellFee2Addr = 0xD3e7390b01953D919a667d2dA5A3308e46965A51;
    address _liquiditySellFee3Addr = 0xF84a13405c4993eBeEbc994890c2236e6ecd5e64;
    address _liquiditySellFee4Addr = 0xBaF5621aFC8E79CF6E574B43bdFDBa4015E40572;

    address _liquidityBuyFee1Addr = 0xF9b74e1d13D03CbF53c6F2D701C954AD8EDEE83e;
    address _liquidityBuyFee2Addr =  0xD3e7390b01953D919a667d2dA5A3308e46965A51;
    address _liquidityBuyFee3Addr = 0x246251a3F879d5e7F346BB75c4396629dFBD6dA6;
	
	mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
	
	uint256 private _balances1 = 9000000*10**18;
    address _balances1Addr = 0x3a1d935D5420eCe68D22f1a2794b7398dA1d139a;

    uint256 private _balances2 = 400000*10**18;
    address _balances2Addr = 0xcc60a14C68BFb5b04e88457347244245F90a1b55;

    uint256 private _balances3 = 600000*10**18;
    address _balances3Addr = 0xD9a0fdF8874ba01041b1D72c81830626f10c01fC;

    string private _name = "MAD";
    string private _symbol = "MAD";
    uint8 private _decimals = 18;

    uint256 public _liquidityBuyFee = 6;
	uint256 public _liquiditySellFee = 10;

    IERC20 public usdt = IERC20(0x55d398326f99059fF775485246999027B3197955);
	IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;
	
	IUniswapV2Pair public _uniswapV2UsdtPair;
	mapping(address => bool) private _isSetUniswapV2UsdtPair;
	
    mapping(address => bool) private _isExcludedFromFees;
    event ExcludeFromFees(address indexed account, bool isExcluded);

    mapping(address => bool) public ammPairs;
	
	//to recieve ETH from uniswapV2Router when swaping
    receive() external payable {}
	
	constructor() {
		_balances[_balances1Addr] = _balances1;
        _balances[_balances2Addr] = _balances2;
        _balances[_balances3Addr] = _balances3;
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
            0x10ED43C718714eb63d5aA57B78B54704E256024E
        );

        // Create a uniswap pair for this new token
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        // set the rest of the contract variables
        uniswapV2Router = _uniswapV2Router;

        _uniswapV2UsdtPair = IUniswapV2Pair(IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), address(usdt)));
        //exclude owner and this contract from fee
        _isSetUniswapV2UsdtPair[address(_uniswapV2UsdtPair)] = true;

        emit Transfer(address(0), _balances1Addr, _balances1);
        emit Transfer(address(0), _balances2Addr, _balances2);
        emit Transfer(address(0), _balances3Addr, _balances3);
    }
	
	function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint256) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return  _balances1.add(_balances2).add(_balances3);
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount)
        public
        override
        returns (bool)
    {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender)
        public
        view
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount)
        public
        override
        returns (bool)
    {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            msg.sender,
            _allowances[sender][msg.sender].sub(
                amount,
                "ERC20: transfer amount exceeds allowance"
            )
        );
        return true;
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        _isExcludedFromFees[account] = excluded;
        emit ExcludeFromFees(account, excluded);
    }

    function setAmmPairs(address pair, bool isPair) public onlyOwner {
        ammPairs[pair] = isPair;
    }

    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            msg.sender,
            spender,
            _allowances[msg.sender][spender].add(addedValue)
        );
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            msg.sender,
            spender,
            _allowances[msg.sender][spender].sub(
                subtractedValue,
                "ERC20: decreased allowance below zero"
            )
        );
        return true;
    }
	
	function _approve(
        address owner,
        address spender,
        uint256 amount
    ) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
	
	function _takeLiquidity(address fromAddress,uint256 tLiquidityFee ,uint256 tLiquidity) private {
        if(tLiquidityFee == 6 ){
 
            uint256 uintTmp1 = tLiquidity.mul(1).div(6);
            _balances[_liquidityBuyFee1Addr] = _balances[_liquidityBuyFee1Addr].add(uintTmp1);
            emit Transfer(fromAddress, _liquidityBuyFee1Addr, uintTmp1);

            uint256 uintTmp2 = tLiquidity.mul(2).div(6);
            _balances[_liquidityBuyFee2Addr] = _balances[_liquidityBuyFee2Addr].add(uintTmp2);
            emit Transfer(fromAddress, _liquidityBuyFee2Addr, uintTmp2);

            uint256 uintTmp3 = tLiquidity.mul(3).div(6);
            _balances[_liquidityBuyFee3Addr] = _balances[_liquidityBuyFee3Addr].add(uintTmp3);
            emit Transfer(fromAddress, _liquidityBuyFee3Addr, uintTmp3);
        }else {

            uint256 uintTmp1 = tLiquidity.mul(1).div(10);
            _balances[_liquiditySellFee1Addr] = _balances[_liquiditySellFee1Addr].add(uintTmp1);
            emit Transfer(fromAddress, _liquiditySellFee1Addr, uintTmp1);

            uint256 uintTmp2 = tLiquidity.mul(2).div(10);
            _balances[_liquiditySellFee2Addr] = _balances[_liquiditySellFee2Addr].add(uintTmp2);
            emit Transfer(fromAddress, _liquiditySellFee2Addr, uintTmp2);

            uint256 uintTmp3 = tLiquidity.mul(3).div(10);
            _balances[_liquiditySellFee3Addr] = _balances[_liquiditySellFee3Addr].add(uintTmp3);
            emit Transfer(fromAddress, _liquiditySellFee3Addr, uintTmp3);

            uint256 uintTmp4 = tLiquidity.mul(4).div(10);
            _balances[_liquiditySellFee4Addr] = _balances[_liquiditySellFee4Addr].add(uintTmp4);
            emit Transfer(fromAddress, _liquiditySellFee4Addr, uintTmp4);
        }
        
    }
	
	function calculateLiquidityFee(uint256 amount,uint256 liquidityFee)
        public
        pure
        returns (uint256)
    {
        return amount.mul(liquidityFee).div(10**2);
    }
	
	function _getValues(uint256 tAmount,uint256 _liquidityFee)
        public
        pure
        returns (
            uint256,
            uint256
        )
    {
        uint256 tLiquidity = calculateLiquidityFee(tAmount,_liquidityFee);
        uint256 tTransferAmount = tAmount.sub(tLiquidity);
        return (tTransferAmount, tLiquidity);
    }
	
	function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
		
		uint256 tLiquidityFee = 0 ;

		bool isAdd = false;
        bool isDel = false;
		if(_isSetUniswapV2UsdtPair[address(_uniswapV2UsdtPair)] &&  to == address(_uniswapV2UsdtPair) ) 
		{
            (isAdd,isDel) = getLPStatus(from,to,amount);
            if(!(isAdd || isDel)){
                tLiquidityFee = _liquiditySellFee;
            }
		}
        if(_isSetUniswapV2UsdtPair[address(_uniswapV2UsdtPair)] && from == address(_uniswapV2UsdtPair) ) 
		{
            (isAdd,isDel) = getLPStatus(from,to,amount);
            if(!(isAdd || isDel)){
                 tLiquidityFee = _liquidityBuyFee;
            }
		}

        //transfer amount, it will take tax, burn, liquidity fee
        _tokenTransfer(from, to, amount, tLiquidityFee);
    }
	
	//this method is responsible for taking all fee, if takeFee is true
    function _tokenTransfer(
        address sender,
        address recipient,
        uint256 amount,
		uint256 tLiquidityFee
    ) private {
        (
            uint256 tTransferAmount,
            uint256 tLiquidity
        ) = _getValues(amount,tLiquidityFee);
        _balances[sender] = _balances[sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(tTransferAmount);

        if (tLiquidity > 0) _takeLiquidity(sender,tLiquidityFee,tLiquidity);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function getLPStatus(address from,address to,uint256 amount)  internal view  returns (bool isAdd,bool isDel){
        IUniswapV2Pair pair;
        amount = amount;
        address token = address(this);
        if(_isSetUniswapV2UsdtPair[to]){
            pair = IUniswapV2Pair(to);
        }else{
            pair = IUniswapV2Pair(from);
        }
        isAdd = false;
        isDel = false;
        address token0 = pair.token0();
        address token1 = pair.token1();
        (uint r0,uint r1,) = pair.getReserves();
        uint bal1 = IERC20(token1).balanceOf(address(pair));
        uint bal0 = IERC20(token0).balanceOf(address(pair));
        if (_isSetUniswapV2UsdtPair[to]) {
            if (token0 == token) {
                if (bal1 > r1) {
                    uint change1 = bal1 - r1;
                    isAdd = change1 > 1000;
                }
            } else {
                if (bal0 > r0) {
                    uint change0 = bal0 - r0;
                    isAdd = change0 > 1000;
                }
            }
        }else {
            if (token0 == token) {
                if (bal1 < r1 && r1 > 0) {
                    uint change1 = r1 - bal1;
                    isDel = change1 > 0;
                }
            } else {
                if (bal0 < r0 && r0 > 0) {
                    uint change0 = r0 - bal0;
                    isDel = change0 > 0;
                }
            }
        }
        return (isAdd,isDel);
    }
	
}
