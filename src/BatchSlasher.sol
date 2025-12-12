// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {ICoordinator} from "ees-core/src/interfaces/ICoordinator.sol";
import {IBatchSlasher} from "./interfaces/IBatchSlasher.sol";

/// @title BatchSlasher
/// @notice Contract for batch slashing of executors in the EES system
/// @dev Allows slashing multiple inactive executors and committer executors in a single transaction
contract BatchSlasher is IBatchSlasher {
    /// @notice The coordinator contract that handles slashing operations
    ICoordinator public coordinator;

    /// @notice Initializes the BatchSlasher with a coordinator address
    /// @param _coordinator The address of the coordinator contract
    constructor(address _coordinator) {
        coordinator = ICoordinator(_coordinator);
    }

    /// @notice Batch slashes inactive executors and committer executors
    /// @dev Slashes are attempted for each executor, but failures are silently caught to allow partial success
    /// @param _committerExecutors Array of executor addresses that committed violations
    /// @param _inactiveExecutors Array of executor addresses that were inactive
    /// @param _rounds Array of round numbers corresponding to inactive executors (must match length of _inactiveExecutors)
    /// @param _recipient Address that will receive the slashed funds
    function batchSlash(
        address[] calldata _committerExecutors,
        address[] calldata _inactiveExecutors,
        uint8[] calldata _rounds,
        address _recipient
    ) external {
        for (uint256 i = 0; i < _inactiveExecutors.length; i++) {
            try coordinator.slashInactiveExecutor(_inactiveExecutors[i], _rounds[i], _recipient) {} catch {}
        }

        for (uint256 i = 0; i < _committerExecutors.length; i++) {
            try coordinator.slashCommitter(_committerExecutors[i], _recipient) {} catch {}
        }
    }
}
