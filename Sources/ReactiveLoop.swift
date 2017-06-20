//
//  ReactiveLoop.swift
//  Entitas-Swift
//
//  Created by Maxim Zaks on 19.06.17.
//  Copyright © 2017 Maxim Zaks. All rights reserved.
//

import Foundation

public final class ReactiveLoop: GroupObserver {
    private let systems: [ReactiveSystem]
    private let group: Group
    private let queue: DispatchQueue
    private weak var logger: SystemExecuteLogger?
    private let delay: DispatchTime?
    private var triggered = false
    public init(ctx: Context, logger: SystemExecuteLogger? = nil, queue: DispatchQueue = DispatchQueue.main, delay: Double? = nil, systems: [ReactiveSystem]) {
        self.systems = systems
        self.queue = queue
        self.logger = logger
        if let delay = delay {
            let time = DispatchTime.now() + Double(Int64(delay * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
            self.delay = time
        } else {
            self.delay = nil
        }
        var cids : Set<CID> = []
        for system in systems {
            cids.formUnion(system.collector.matcher.allOf)
            cids.formUnion(system.collector.matcher.anyOf)
            cids.formUnion(system.collector.matcher.noneOf)
        }
        group = ctx.group(Matcher(any:cids))
        group.observer(add: self)
    }
    
    private func execute() {
        triggered = false
        for system in systems {
            logger?.willExecute(system.name)
            system.execute()
            logger?.didExecute(system.name)
        }
    }
    
    private func trigger() {
        if triggered == false {
            triggered = true
            if let delay = delay {
                queue.asyncAfter(deadline: delay, execute: {[weak self] in
                    self?.execute()
                })
            } else {
                queue.async { [weak self] in
                    self?.execute()
                }
            }
        }
    }
    
    public func added(entity: Entity, oldComponent: Component?, newComponent: Component?, in group: Group) {
        trigger()
    }
    public func updated(entity: Entity, oldComponent: Component?, newComponent: Component?, in group: Group) {
        trigger()
    }
    public func removed(entity: Entity, oldComponent: Component?, newComponent: Component?, in group: Group) {
        trigger()
    }
}
