// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {IQuerier} from "./interfaces/IQuerier.sol";
import {JobRegistry} from "ees-core/src/JobRegistry.sol";
import {IJobRegistry} from "ees-core/src/interfaces/IJobRegistry.sol";
import {IExecutionModule} from "ees-core/src/interfaces/IExecutionModule.sol";
import {IFeeModule} from "ees-core/src/interfaces/IFeeModule.sol";
import {IApplication} from "ees-core/src/interfaces/IApplication.sol";
import {Coordinator} from "ees-core/src/Coordinator.sol";
import {ICoordinator} from "ees-core/src/interfaces/ICoordinator.sol";

contract Querier is IQuerier {
    JobRegistry jobRegistry;
    Coordinator coordinator;

    constructor(JobRegistry _jobRegistry, Coordinator _coordinator) {
        jobRegistry = _jobRegistry;
        coordinator = _coordinator;
    }
    // HAVE TO BREAK UP INTO TWO STRUCTS TO AVOID STACK TOO DEEP ERROR

    struct JobBasicInfo {
        uint256 index;
        address owner;
        bool active;
        bool ignoreAppRevert;
        bool sponsorFallbackToOwner;
        bool sponsorCanUpdateFeeModule;
        bytes1 executionModule;
        bytes1 feeModule;
        uint24 executionWindow;
        uint24 zeroFeeWindow;
    }

    struct JobExtendedInfo {
        address sponsor;
        uint48 executionCounter;
        uint48 maxExecutions;
        IApplication application;
        uint96 creationTime;
    }

    function getJobs(uint256[] calldata _indices) public view override returns (JobData[] memory) {
        JobData[] memory jobsData = new JobData[](_indices.length);
        for (uint256 i; i < _indices.length;) {
            uint256 index = _indices[i];
            (
                address owner,
                bool active,
                bool ignoreAppRevert,
                bool sponsorFallbackToOwner,
                bool sponsorCanUpdateFeeModule,
                bytes1 executionModule,
                bytes1 feeModule,
                uint24 executionWindow,
                uint24 zeroFeeWindow,
                address sponsor,
                uint48 executionCounter,
                uint48 maxExecutions,
                IApplication application,
                uint96 creationTime
            ) = jobRegistry.jobs(index);

            JobBasicInfo memory basicInfo = JobBasicInfo({
                index: index,
                owner: owner,
                active: active,
                ignoreAppRevert: ignoreAppRevert,
                sponsorFallbackToOwner: sponsorFallbackToOwner,
                sponsorCanUpdateFeeModule: sponsorCanUpdateFeeModule,
                executionModule: executionModule,
                feeModule: feeModule,
                executionWindow: executionWindow,
                zeroFeeWindow: zeroFeeWindow
            });

            JobExtendedInfo memory extendedInfo = JobExtendedInfo({
                sponsor: sponsor,
                executionCounter: executionCounter,
                maxExecutions: maxExecutions,
                application: application,
                creationTime: creationTime
            });

            (address executionModuleAddress,) = coordinator.modules(uint8(basicInfo.executionModule));
            IExecutionModule executionModuleContract = IExecutionModule(executionModuleAddress);
            (address feeModuleAddress,) = coordinator.modules(uint8(basicInfo.feeModule));
            IFeeModule feeModuleContract = IFeeModule(feeModuleAddress);

            jobsData[i] = JobData({
                index: basicInfo.index,
                owner: basicInfo.owner,
                active: basicInfo.active,
                ignoreAppRevert: basicInfo.ignoreAppRevert,
                sponsorFallbackToOwner: basicInfo.sponsorFallbackToOwner,
                sponsorCanUpdateFeeModule: basicInfo.sponsorCanUpdateFeeModule,
                executionModule: basicInfo.executionModule,
                feeModule: basicInfo.feeModule,
                executionWindow: basicInfo.executionWindow,
                zeroFeeWindow: basicInfo.zeroFeeWindow,
                sponsor: extendedInfo.sponsor,
                executionCounter: extendedInfo.executionCounter,
                maxExecutions: extendedInfo.maxExecutions,
                application: extendedInfo.application,
                creationTime: extendedInfo.creationTime,
                executionModuleData: executionModuleContract.getEncodedData(index),
                feeModuleData: feeModuleContract.getEncodedData(index),
                jobIsExpired: executionModuleContract.jobIsExpired(index, basicInfo.executionWindow),
                jobInExecutionWindow: executionModuleContract.jobIsInExecutionMode(index, basicInfo.executionWindow)
            });

            unchecked {
                ++i;
            }
        }
        return jobsData;
    }

    function getExecutors(address[] calldata _executors)
        public
        view
        override
        returns (ICoordinator.Executor[] memory)
    {
        ICoordinator.Executor[] memory executors = new ICoordinator.Executor[](_executors.length);
        for (uint256 i; i < _executors.length;) {
            (
                uint256 balance,
                bool active,
                bool initialized,
                uint32 arrayIndex,
                uint8 roundsCheckedInEpoch,
                uint8 lastCheckinRound,
                uint96 lastCheckinEpoch,
                uint96 executionsInRoundsInEpoch,
                uint256 lastRegistrationTimestamp,
                uint256 registeredModules
            ) = coordinator.executorInfo(_executors[i]);
            ICoordinator.Executor memory executor = ICoordinator.Executor({
                balance: balance,
                active: active,
                initialized: initialized,
                arrayIndex: arrayIndex,
                roundsCheckedInEpoch: roundsCheckedInEpoch,
                lastCheckinRound: lastCheckinRound,
                lastCheckinEpoch: lastCheckinEpoch,
                executionsInRoundsInEpoch: executionsInRoundsInEpoch,
                lastRegistrationTimestamp: lastRegistrationTimestamp,
                registeredModules: registeredModules
            });
            executors[i] = executor;
            unchecked {
                ++i;
            }
        }
        return executors;
    }

    function getCommitData(address[] calldata _executors)
        public
        view
        override
        returns (ICoordinator.CommitData[] memory)
    {
        ICoordinator.CommitData[] memory commitData = new ICoordinator.CommitData[](_executors.length);
        for (uint256 i; i < _executors.length;) {
            (bytes32 commitment, uint192 epoch, bool revealed) = coordinator.commitmentMap(_executors[i]);
            ICoordinator.CommitData memory data =
                ICoordinator.CommitData({commitment: commitment, epoch: epoch, revealed: revealed});
            commitData[i] = data;
            unchecked {
                ++i;
            }
        }
        return commitData;
    }

    function getCurrentEpochInfo()
        public
        view
        override
        returns (uint192, uint256, bytes32, uint40, address[] memory, uint256, uint256)
    {
        uint192 epoch = coordinator.epoch();
        uint40 numberOfActiveExecutors = coordinator.numberOfActiveExecutors();
        bytes32 seed = coordinator.seed();
        uint256 poolBalance = coordinator.epochPoolBalance();
        uint256 nextEpochPoolBalance = coordinator.nextEpochPoolBalance();

        bytes memory config = coordinator.exportConfig();
        // Decode the config to get roundsPerEpoch
        (
            ,
            ,
            ,
            ,
            ,
            , // Skip the first 6 parameters
            uint8 roundsPerEpoch,
            ,
            ,
            ,
            ,
            ,
            ,
            ,
            , // Skip the remaining parameters
        ) = abi.decode(
            config,
            (
                address,
                uint256,
                uint256,
                uint256,
                uint256,
                uint256,
                uint8,
                uint8,
                uint8,
                uint8,
                uint8,
                uint8,
                uint256,
                uint256,
                uint256,
                uint256
            )
        );
        address[] memory designatedExecutors = new address[](roundsPerEpoch);
        for (uint256 i; i < roundsPerEpoch;) {
            uint256 executorIndex = uint256(keccak256(abi.encodePacked(seed, i))) % uint256(numberOfActiveExecutors);
            designatedExecutors[i] = coordinator.activeExecutors(executorIndex);
            unchecked {
                ++i;
            }
        }
        return (
            epoch,
            coordinator.epochEndTime(),
            seed,
            numberOfActiveExecutors,
            designatedExecutors,
            poolBalance,
            nextEpochPoolBalance
        );
    }
}
