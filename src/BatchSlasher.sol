// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {ICoordinator} from "ees-core/src/interfaces/ICoordinator.sol";
import {IBatchSlasher} from "./interfaces/IBatchSlasher.sol";

/// @author 0xst4ck
contract BatchSlasher is IBatchSlasher {
    ICoordinator public coordinator;

    constructor(address _coordinator) {
        coordinator = ICoordinator(_coordinator);
    }

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
