// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.0 <0.9.0;
pragma abicoder v2;

import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";
import "@uniswap/v3-periphery/contracts/interfaces/IQuoterV2.sol";

contract MultihopV3 {
    ISwapRouter public immutable swapRouter;
    IQuoterV2 public immutable quoter;
    address public immutable owner;

    constructor(ISwapRouter _swapRouter) {
        swapRouter = _swapRouter;
        quoter = IQuoterV2(0xb27308f9F90D607463bb33eA1BeBb41C27CE5AB6);
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    /// @notice swapExactInputMultihop swaps a fixed amount of inputToken for a maximum possible amount of outputToken through an intermediary pool.
    /// @dev The calling address must approve this contract to spend at least `amountIn` worth of its inputToken for this function to succeed.
    /// @param amountIn The amount of inputToken to be swapped.
    /// @param path An array of token addresses and pool fees that define the pools used in the swaps.
    /// @return amountOut The amount of outputToken received after the swap.
    function swapExactInputMultihop(
        uint256 amountIn,
        address[] memory path,
        uint24[] memory fees
    ) external onlyOwner returns (uint256 amountOut) {
        require(path.length > 1, "Path must have at least two tokens");
        require(
            path.length == fees.length + 1,
            "Path length must match fees length + 1"
        );

        // Transfer `amountIn` of inputToken to this contract.
        TransferHelper.safeTransferFrom(
            path[0],
            msg.sender,
            address(this),
            amountIn
        );

        // Approve the router to spend inputToken.
        TransferHelper.safeApprove(path[0], address(swapRouter), amountIn);

        // Construct the swap path dynamically.
        bytes memory swapPath = abi.encodePacked(
            path[0],
            fees[0],
            path[1],
            fees[1],
            path[2]
        );

        ISwapRouter.ExactInputParams memory params = ISwapRouter
            .ExactInputParams({
                path: swapPath,
                recipient: msg.sender,
                deadline: block.timestamp,
                amountIn: amountIn,
                amountOutMinimum: 0
            });

        // Executes the swap.
        amountOut = swapRouter.exactInput(params);
    }
}