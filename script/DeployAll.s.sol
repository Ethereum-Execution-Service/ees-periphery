// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;

import "forge-std/src/console2.sol";
import "forge-std/src/Script.sol";

import {BatchSlasher} from "../src/BatchSlasher.sol";
import {Querier} from "../src/Querier.sol";
import {ConfigProvider} from "../src/ConfigProvider.sol";
import {JobRegistry} from "ees-core/src/JobRegistry.sol";
import {Coordinator} from "ees-core/src/Coordinator.sol";

contract DeployAll is Script {
    address jobRegistry = 0x42399DfBE3FB209b51DB8f2FA92297cE3c91eA18;
    address coordinator = 0x9a16DF022F3eB2F7af8eA52d2D81c0f87aF9826d;

    function setUp() public {}

    function run() public returns (BatchSlasher batchSlasher, Querier querier, ConfigProvider configProvider) {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        batchSlasher = new BatchSlasher(coordinator);
        console2.log("BatchSlasher Deployed:", address(batchSlasher));

        querier = new Querier(JobRegistry(jobRegistry), Coordinator(coordinator));
        console2.log("Querier Deployed:", address(querier));

        configProvider = new ConfigProvider(JobRegistry(jobRegistry), Coordinator(coordinator), querier, batchSlasher);
        console2.log("ConfigProvider Deployed:", address(configProvider));

        vm.stopBroadcast();
    }
}
