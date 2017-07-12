//
//  Loop.swift
//  Entitas-Swift
//
//  Created by Maxim Zaks on 19.06.17.
//  Copyright © 2017 Maxim Zaks. All rights reserved.
//

import Foundation

public final class Loop: InitSystem, ExecuteSystem, CleanupSystem, TeardownSystem {
    public let name: String
    private var initSystems: [InitSystem] = []
    private var executeSystems: [ExecuteSystem] = []
    private var cleanupSystems: [CleanupSystem] = []
    private var teardownSystems: [TeardownSystem] = []
    private weak var logger: SystemExecuteLogger?
    
    public init(name: String, systems: [System], logger: SystemExecuteLogger? = nil) {
        self.name = name
        self.logger = logger
        for system in systems {
            if let initSystem = system as? InitSystem {
                initSystems.append(initSystem)
            }
            if let execute = system as? ExecuteSystem {
                executeSystems.append(execute)
            }
            if let cleanup = system as? CleanupSystem {
                cleanupSystems.append(cleanup)
            }
            if let teardown = system as? TeardownSystem {
                teardownSystems.append(teardown)
            }
        }
    }
    
    public func initialise() {
        for system in initSystems {
            logger?.willInit(system.name)
            system.initialise()
            logger?.didInit(system.name)
        }
    }
    
    public func execute() {
        for system in executeSystems {
            logger?.willExecute(system.name)
            system.execute()
            logger?.didExecute(system.name)
        }
    }
    
    public func cleanup() {
        for system in cleanupSystems {
            logger?.willCleanup(system.name)
            system.cleanup()
            logger?.didCleanup(system.name)
        }
    }
    
    public func teardown() {
        for system in teardownSystems {
            logger?.willTeardown(system.name)
            system.teardown()
            logger?.didTeardown(system.name)
        }
    }
}
