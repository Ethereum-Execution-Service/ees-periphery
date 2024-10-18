// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IBatchSlasher {
    function batchSlash(
        address[] calldata _committerExecutors,
        address[] calldata _inactiveExecutors,
        uint8[] calldata _rounds,
        address _recipient
    ) external;
}
