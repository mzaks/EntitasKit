//
//  Index.swift
//  Entitas-Swift
//
//  Created by Maxim Zaks on 18.06.17.
//  Copyright © 2017 Maxim Zaks. All rights reserved.
//

import Foundation

public final class Index<T : Hashable, C: Component> {
    
    fileprivate var entities: [T: Set<Entity>]
    fileprivate weak var group: Group?
    fileprivate let keyBuilder: (C) -> T
    
    init(ctx: Context, paused: Bool = false, keyBuilder: @escaping (C) -> T) {
        self.group = ctx.group(C.matcher)
        self.entities = [:]
        self.keyBuilder = keyBuilder
        self.isPaused = paused
        if isPaused == false {
            refillIndex()
        }
        group?.observer(add: self)
    }
    
    public subscript(key: T) -> Set<Entity> {
        return entities[key] ?? []
    }
    
    public var isPaused : Bool {
        didSet {
            if isPaused {
                entities.removeAll()
            } else {
                refillIndex()
            }
        }
    }
    
    private func refillIndex() {
        if let group = group {
            for e in group {
                if let c: C = e.get() {
                    insert(c, e)
                }
            }
        }
    }
    
    fileprivate func insert(_ c: C, _ entity: Entity) {
        let key = keyBuilder(c)
        var set: Set<Entity> = entities[key] ?? []
        set.insert(entity)
        entities[key] = set
    }
    
    fileprivate func remove(_ prevC: C, _ entity: Entity) {
        let prevKey = keyBuilder(prevC)
        var prevSet: Set<Entity> = entities[prevKey] ?? []
        prevSet.remove(entity)
        entities[prevKey] = prevSet
    }
}

extension Index: GroupObserver {
    public func added(entity: Entity, oldComponent: Component?, newComponent: Component?, in group: Group) {
        guard let c = newComponent as? C else {
            return
        }
        guard isPaused == false else {
            return
        }
        insert(c, entity)
    }
    public func updated(entity: Entity, oldComponent: Component?, newComponent: Component?, in group: Group) {
        guard let c = newComponent as? C,
            let prevC = oldComponent as? C else {
            return
        }
        guard isPaused == false else {
            return
        }
        
        remove(prevC, entity)
        insert(c, entity)
    }
    public func removed(entity: Entity, oldComponent: Component?, newComponent: Component?, in group: Group) {
        guard let prevC = oldComponent as? C else {
            return
        }
        guard isPaused == false else {
            return
        }
        
        remove(prevC, entity)
    }
}
