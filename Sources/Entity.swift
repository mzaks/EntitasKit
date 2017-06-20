//
//  Entity.swift
//  Entitas-Swift
//
//  Created by Maxim Zaks on 04.06.17.
//  Copyright © 2017 Maxim Zaks. All rights reserved.
//

import Foundation


public final class Entity {
    internal var creationIndex: Int {
        didSet {
            waitingForRebirth = false
        }
    }
    private var components: [CID: Component] = [:]
    fileprivate let mainObserver: EntityObserver
    
    private var observers : Set<ObserverBox> = []
    private(set) var waitingForRebirth = false {
        didSet {
            if waitingForRebirth {
                observers.removeAll()
            }
        }
    }
    
    init(index: Int, mainObserver: EntityObserver) {
        creationIndex = index
        self.mainObserver = mainObserver
    }
    
    public func get<T : Component>() -> T? {
        return components[T.cid] as? T
    }
    
    public func get<T : Component>(_ type: T.Type) -> T? {
        return components[type.cid] as? T
    }
    
    @discardableResult
    public func set<T : Component>(_ comp: T) -> Entity {
        guard waitingForRebirth == false else {
            assertionFailure("Adding components to dead entity")
            return self
        }
        let c = components.updateValue(comp, forKey: T.cid)
        updated(component: c, with: comp)
        return self
    }
    
    @discardableResult
    public func remove(_ cid: CID) -> Entity {
        if let c = components.removeValue(forKey: cid) {
            removed(component: c)
        }
        return self
    }
    
    @discardableResult
    public func has(_ cid: CID) -> Bool {
        return components[cid] != nil
    }
    
    public func destroy() {
        for cid in components.keys {
            remove(cid)
        }
        destroyed()
        waitingForRebirth = true
    }
    
    public var isEmpty: Bool {
        return components.isEmpty
    }
    
    public func observer(add o: EntityObserver){
        observers.update(with: ObserverBox(o))
    }
    
    public func observer(remove o: EntityObserver){
        observers.remove(ObserverBox(o))
    }
    
    private func updated(component oldComponent: Component?, with newComponent: Component) {
        mainObserver.updated(component: oldComponent, with: newComponent, in: self)
        for box in observers {
            (box.ref as? EntityObserver)?.updated(component: oldComponent, with: newComponent, in: self)
        }
    }
    
    private func removed(component: Component) {
        mainObserver.removed(component: component, from: self)
        for box in observers {
            (box.ref as? EntityObserver)?.removed(component: component, from: self)
        }
    }
    
    private func destroyed() {
        mainObserver.destroyed(entity: self)
        for box in observers {
            (box.ref as? EntityObserver)?.destroyed(entity: self)
        }
    }
}

public protocol EntityObserver : Observer {
    func updated(component oldComponent: Component?, with newComponent: Component, in entity: Entity)
    func removed(component: Component, from entity: Entity)
    func destroyed(entity: Entity)
}

extension Entity: Hashable {
    public var hashValue: Int {
        return creationIndex
    }
    public static func ==(a: Entity, b: Entity) -> Bool {
        return a.creationIndex == b.creationIndex && a.mainObserver === b.mainObserver
    }
}

extension Entity: Comparable {
    public static func <(lhs: Entity, rhs: Entity) -> Bool {
        return lhs.creationIndex < rhs.creationIndex
    }
}
