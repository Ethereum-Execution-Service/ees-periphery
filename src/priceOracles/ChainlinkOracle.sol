// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {AggregatorV3Interface} from "lib/chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import {ERC20} from "lib/solmate/src/tokens/ERC20.sol";

/// @author 0xst4ck
contract ChainlinkOracle {
    AggregatorV3Interface internal ethUsdPriceFeed;
    uint8 internal ethPriceFeedDecimals;
    uint256 updateThreshold;

    constructor(address _ethUsdPriceFeed, uint256 _updateThreshold) {
        ethUsdPriceFeed = AggregatorV3Interface(_ethUsdPriceFeed);
        ethPriceFeedDecimals = ethUsdPriceFeed.decimals();
        updateThreshold = _updateThreshold;
    }

    error FeedStale();

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
