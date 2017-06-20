//
//  Stubs.swift
//  Entitas-Swift
//
//  Created by Maxim Zaks on 04.06.17.
//  Copyright © 2017 Maxim Zaks. All rights reserved.
//

import Foundation
import EntitasKit

class EntityObserverStub: EntityObserver{
    func updated(component oldComponent: Component?, with newComponent: Component, in entity: Entity){}
    func removed(component: Component, from entity: Entity){}
    func destroyed(entity: Entity){}
}

final class Logger: SystemExecuteLogger {
    var log: [String] = []
    func didCleanup(_ name: String) {
        log.append("didCleanup\(name)")
    }
    func didExecute(_ name: String) {
        log.append("didExecute\(name)")
    }
    func didInit(_ name: String) {
        log.append("didInit\(name)")
    }
    func didTeardown(_ name: String) {
        log.append("didTeardown\(name)")
    }
    func willCleanup(_ name: String) {
        log.append("willCleanup\(name)")
    }
    func willExecute(_ name: String) {
        log.append("willExecute\(name)")
    }
    func willInit(_ name: String) {
        log.append("willInit\(name)")
    }
    func willTeardown(_ name: String) {
        log.append("willTeardown\(name)")
    }
}
