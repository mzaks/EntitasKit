//
//  Group.swift
//  Entitas-Swift
//
//  Created by Maxim Zaks on 05.06.17.
//  Copyright © 2017 Maxim Zaks. All rights reserved.
//

import Foundation

public final class Group: Hashable {
    fileprivate var entities: Set<Entity> = []
    private var observers : Set<ObserverBox> = []
    let matcher: Matcher
    var presorted: [Entity]?
    
    init(matcher: Matcher) {
        self.matcher = matcher
    }
    
    func add(_ e: Entity) {
        entities.insert(e)
        presorted = nil
    }
    
    public func observer(add observer:GroupObserver) {
        observers.update(with: ObserverBox(observer))
    }
    
    public func observer(remove observer: GroupObserver) {
        observers.remove(ObserverBox(observer))
    }
    
    func checkOnUpdate(oldComponent: Component?, newComponent: Component, entity: Entity) {
        if matcher.matches(entity) {
            let (added, _) = entities.insert(entity)
            if added {
                notify(groupEvent: .added, oldComponent: oldComponent, newComponent: newComponent, entity: entity)
            } else {
                notify(groupEvent: .updated, oldComponent: oldComponent, newComponent: newComponent, entity: entity)
            }
        } else {
            if entities.remove(entity) != nil {
                notify(groupEvent: .removed, oldComponent: oldComponent, newComponent: newComponent, entity: entity)
            }
        }
    }
    
    func checkOnRemove(oldComponent: Component?, entity: Entity) {
        if matcher.matches(entity) {
            let (added, _) = entities.insert(entity)
            if added {
                notify(groupEvent: .added, oldComponent: oldComponent, newComponent: nil, entity: entity)
            } else {
                notify(groupEvent: .updated, oldComponent: oldComponent, newComponent: nil, entity: entity)
            }
        } else {
            if entities.remove(entity) != nil {
                notify(groupEvent: .removed, oldComponent: oldComponent, newComponent: nil, entity: entity)
            }
        }
    }
    
    private func notify(groupEvent: GroupEvent, oldComponent: Component?, newComponent: Component?, entity: Entity) {
        
        presorted = nil
        
        for observer in observers {
            guard let observer = observer.ref as? GroupObserver else {
                continue
            }
            switch groupEvent {
            case .added:
                observer.added(entity: entity, oldComponent: oldComponent, newComponent: newComponent, in: self)
            case .updated:
                observer.updated(entity: entity, oldComponent: oldComponent, newComponent: newComponent, in: self)
            case .removed:
                observer.removed(entity: entity, oldComponent: oldComponent, newComponent: newComponent, in: self)
            }
        }
    }
    
    public var count: Int {
        return entities.count
    }
    
    public var hashValue: Int {
        return matcher.hashValue
    }
    public static func ==(a: Group, b: Group) -> Bool {
        return a.matcher == b.matcher
    }
}

extension Group : Sequence {
    public func makeIterator() -> SetIterator<Entity> {
        return entities.makeIterator()
    }
    
    func sorted() -> [Entity] {
        if presorted == nil {
            presorted = entities.sorted()
        }
        
        return presorted ?? []
    }
}

public enum GroupEvent {
    case added, updated, removed
}

public protocol GroupObserver : Observer {
    func added(entity: Entity, oldComponent: Component?, newComponent: Component?, in group: Group)
    func updated(entity: Entity, oldComponent: Component?, newComponent: Component?, in group: Group)
    func removed(entity: Entity, oldComponent: Component?, newComponent: Component?, in group: Group)
}
