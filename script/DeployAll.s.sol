// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.27;

import "forge-std/src/console2.sol";
import "forge-std/src/Script.sol";

import {BatchSlasher} from "../src/BatchSlasher.sol";
import {Querier} from "../src/Querier.sol";
import {ConfigProvider} from "../src/ConfigProvider.sol";
import {JobRegistry} from "ees-core/src/JobRegistry.sol";
import {Coordinator} from "ees-core/src/Coordinator.sol";

contract DeployAll is Script {
    address jobRegistry = 0x33F0B69235B1fFB7ad97aCc313C35E554281Ce00;
    address coordinator = 0xe4C1b552ca7e09ef79e0F77C6F319Cca11F002b7;

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
