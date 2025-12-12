// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {AggregatorV3Interface} from "lib/chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import {ERC20} from "lib/solmate/src/tokens/ERC20.sol";

/// @title ChainlinkOracle
/// @notice Price oracle that uses Chainlink price feeds to calculate token prices relative to ETH
/// @dev Calculates both token/ETH and token/USD prices using Chainlink aggregators
contract ChainlinkOracle {
    /// @notice The ETH/USD price feed aggregator
    AggregatorV3Interface internal ethUsdPriceFeed;

    /// @notice The number of decimals for the ETH/USD price feed
    uint8 internal ethPriceFeedDecimals;

    /// @notice The maximum age (in seconds) that a price update can be before being considered stale
    uint256 updateThreshold;

    /// @notice Initializes the ChainlinkOracle with an ETH/USD price feed
    /// @param _ethUsdPriceFeed The address of the Chainlink ETH/USD aggregator
    /// @param _updateThreshold Maximum age in seconds for price updates before they're considered stale
    constructor(address _ethUsdPriceFeed, uint256 _updateThreshold) {
        ethUsdPriceFeed = AggregatorV3Interface(_ethUsdPriceFeed);
        ethPriceFeedDecimals = ethUsdPriceFeed.decimals();
        updateThreshold = _updateThreshold;
    }

    /// @notice Error thrown when a price feed update is too stale
    error FeedStale();

    /// @notice Gets the price of a token relative to ETH and in USD
    /// @dev The _data parameter should contain the address of the token/USD Chainlink feed (first 20 bytes)
    /// @param _token The ERC20 token address to get the price for
    /// @param _data Calldata containing the token/USD price feed address (first 20 bytes)
    /// @return price The price of the token relative to ETH, scaled to the token's decimals
    /// @return tokenPriceInUsd The price of the token in USD, scaled to the token's decimals
    /// @custom:reverts FeedStale If either the ETH/USD or token/USD feed is stale (older than updateThreshold)
    function getPrice(address _token, bytes calldata _data) public view returns (uint256, uint256) {
        address feedAddress;
        assembly {
            feedAddress := calldataload(_data.offset)
        }

        uint8 tokenDecimals = ERC20(_token).decimals();

        // get ETH/USD price
        (, int256 ethPrice,, uint256 updatedAtEth,) = ethUsdPriceFeed.latestRoundData();
        AggregatorV3Interface feed = AggregatorV3Interface(feedAddress);
        // get token/USD price
        (, int256 tokenPrice,, uint256 updatedAtToken,) = feed.latestRoundData();

        uint256 threshold = block.timestamp - updateThreshold;

        if (updatedAtEth < threshold || updatedAtToken < threshold) revert FeedStale();

        uint8 tokenFeedDecimals = feed.decimals();

        uint8 scaleDecimals = ethPriceFeedDecimals + tokenDecimals - tokenFeedDecimals;

        // how many of token per 1 eth in tokenDecimals
        int256 price = (ethPrice * int256(10 ** scaleDecimals)) / tokenPrice;

        // Scale tokenPrice to match token decimals
        int256 tokenPriceInUsd = tokenPrice;
        if (tokenDecimals > tokenFeedDecimals) {
            // If token has more decimals than feed, multiply
            tokenPriceInUsd = tokenPrice * int256(10 ** (tokenDecimals - tokenFeedDecimals));
        } else if (tokenDecimals < tokenFeedDecimals) {
            // If token has fewer decimals than feed, divide
            tokenPriceInUsd = tokenPrice / int256(10 ** (tokenFeedDecimals - tokenDecimals));
        }

        return (uint256(price), uint256(tokenPriceInUsd));
    }
}
