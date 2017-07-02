//
//  Collector.swift
//  Entitas-Swift
//
//  Created by Maxim Zaks on 18.06.17.
//  Copyright © 2017 Maxim Zaks. All rights reserved.
//

import Foundation

public final class Collector {
    public struct ChangeOptions : OptionSet {
        public let rawValue: UInt8
        public static let added = ChangeOptions(rawValue:1 << 0)
        public static let updated = ChangeOptions(rawValue:1 << 1)
        public static let removed = ChangeOptions(rawValue:1 << 2)
        public static let addedOrUpdated : ChangeOptions = [.added, .updated]
        public static let addedUpdatedOrRemoved : ChangeOptions = [.added, .updated, .removed]
        
        public init(rawValue : UInt8) {
            self.rawValue = rawValue
        }
    }
    
    fileprivate var entities: Set<Entity> = []
    public let matcher: Matcher
    fileprivate let type: ChangeOptions
    
    public var isPaused: Bool
    
    public init(group: Group, type: ChangeOptions, paused: Bool = false) {
        self.type = type
        self.matcher = group.matcher
        self.isPaused = paused
        group.observer(add: self)
    }
    
    public var collected : Set<Entity> {
        let result = entities
        entities = []
        return result
    }
    
    public var collectedAndMatching : [Entity] {
        let result = entities
        entities = []
        let matcher = self.matcher
        return result.filter {
            return matcher.matches($0)
        }
    }
    
    public var first : Entity? {
        return entities.popFirst()
    }
    
    @discardableResult
    public func drainAndPause() -> Set<Entity> {
        isPaused = true
        return collected
    }
    
    public var isEmpty: Bool {
        return entities.isEmpty
    }
}

extension Collector: GroupObserver {
    public func added(entity: Entity, oldComponent: Component?, newComponent: Component?, in group: Group) {
        guard self.type.contains(.added) else {
            return
        }
        guard isPaused == false else {
            return
        }
        entities.insert(entity)
    }
    public func updated(entity: Entity, oldComponent: Component?, newComponent: Component?, in group: Group) {
        guard self.type.contains(.updated) else {
            return
        }
        guard isPaused == false else {
            return
        }
        entities.insert(entity)
    }
    public func removed(entity: Entity, oldComponent: Component?, newComponent: Component?, in group: Group) {
        guard self.type.contains(.removed) else {
            return
        }
        guard isPaused == false else {
            return
        }
        entities.insert(entity)
    }
}
