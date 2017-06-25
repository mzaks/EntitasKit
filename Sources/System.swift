//
//  System.swift
//  Entitas-Swift
//
//  Created by Maxim Zaks on 18.06.17.
//  Copyright © 2017 Maxim Zaks. All rights reserved.
//

import Foundation

public protocol SystemExecuteLogger: class {
    func willExecute(_ name: String)
    func didExecute(_ name: String)
    func willInit(_ name: String)
    func didInit(_ name: String)
    func willCleanup(_ name: String)
    func didCleanup(_ name: String)
    func willTeardown(_ name: String)
    func didTeardown(_ name: String)
}

public protocol System: class {
    var name: String {get}
}

public protocol ExecuteSystem: System {
    func execute()
}

public protocol ReactiveSystem: ExecuteSystem {
    var collector: Collector {get}
    func execute(entities: Set<Entity>)
}

extension ReactiveSystem {
    public func execute() {
        if collector.isEmpty == false {
            self.execute(entities: collector.collected)
        }
    }
}

public protocol StrictReactiveSystem: ExecuteSystem {
    var collector: Collector {get}
    func execute(entities: [Entity])
}

extension StrictReactiveSystem {
    func execute() {
        if collector.isEmpty == false {
            self.execute(entities: collector.collectedAndMatching)
        }
    }
}


public protocol InitSystem: System {
    func initialise()
}

public protocol CleanupSystem: System {
    func cleanup()
}

public protocol TeardownSystem: System {
    func teardown()
}
