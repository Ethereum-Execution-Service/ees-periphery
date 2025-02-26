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
    address jobRegistry = 0xabbe353a343173201a60a0b831A7Ba577234d111;
    address coordinator = 0x8eF1D68ddd32ada92736873Fec7320f5363d6E71;

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
