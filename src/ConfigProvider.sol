// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {JobRegistry} from "ees-core/src/JobRegistry.sol";
import {Coordinator} from "ees-core/src/Coordinator.sol";
import {Querier} from "./Querier.sol";
import {BatchSlasher} from "./BatchSlasher.sol";
import {IConfigProvider} from "./interfaces/IConfigProvider.sol";

/// @title ConfigProvider
/// @notice Provides configuration data for the EES system components
/// @dev Aggregates configuration from JobRegistry and Coordinator, along with contract addresses
contract ConfigProvider is IConfigProvider {
    /// @notice The JobRegistry contract
    JobRegistry public jobRegistry;

    /// @notice The Coordinator contract
    Coordinator public coordinator;

    /// @notice The Querier contract
    Querier public querier;

    /// @notice The BatchSlasher contract
    BatchSlasher public batchSlasher;

    /// @notice Initializes the ConfigProvider with all required contracts
    /// @param _jobRegistry The JobRegistry contract instance
    /// @param _coordinator The Coordinator contract instance
    /// @param _querier The Querier contract instance
    /// @param _batchSlasher The BatchSlasher contract instance
    constructor(JobRegistry _jobRegistry, Coordinator _coordinator, Querier _querier, BatchSlasher _batchSlasher) {
        jobRegistry = _jobRegistry;
        coordinator = _coordinator;
        querier = _querier;
        batchSlasher = _batchSlasher;
    }

    /// @notice Returns the complete configuration data for the EES system
    /// @return addressesConfig Encoded addresses of jobRegistry, coordinator, querier, and batchSlasher
    /// @return jobRegistryConfig Exported configuration from the JobRegistry
    /// @return coordinatorConfig Exported configuration from the Coordinator
    function getConfig() public view returns (bytes memory, bytes memory, bytes memory) {
        return (
            abi.encode(address(jobRegistry), address(coordinator), address(querier), address(batchSlasher)),
            jobRegistry.exportConfig(),
            coordinator.exportConfig()
        );
    }
}
