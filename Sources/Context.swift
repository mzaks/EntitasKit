//
//  Context.swift
//  Entitas-Swift
//
//  Created by Maxim Zaks on 05.06.17.
//  Copyright © 2017 Maxim Zaks. All rights reserved.
//

import Foundation

public final class Context {
    public private(set) var entities: Set<Entity> = []
    private var entityIndex: Int = 0
    lazy private var mainObserver: MainObserver = {
        return MainObserver(ctx: self)
    }()
    private var groups: [Matcher: Group] = [:]
    private var groupsByCID: [CID: Set<Group>] = [:]
    private var observers : Set<ObserverBox> = []
    
    public init() {}
    
    deinit {
        for e in entities {
            e.destroy()
        }
        entities.removeAll()
        groups.removeAll()
        groupsByCID.removeAll()
        observers.removeAll()
    }
    
    public func createEntity() -> Entity {
        entityIndex += 1
        let e = Entity(index: entityIndex, mainObserver: mainObserver)
        entities.insert(e)
        for o in observers where o.ref is ContextObserver {
            (o.ref as! ContextObserver).created(entity: e, in: self)
        }
        return e
    }
    
    public func group(_ matcher: Matcher) -> Group {
        if let group = groups[matcher] {
            return group
        }
        
        let group = Group(matcher: matcher)
        for o in observers where o.ref is ContextObserver {
            (o.ref as! ContextObserver).created(group: group, withMatcher: matcher, in: self)
        }
        for e in entities {
            if matcher.matches(e) {
                group.add(e)
            }
        }
        
        groups[matcher] = group
        for cid in matcher.allOf {
            var set = groupsByCID[cid] ?? []
            set.insert(group)
            groupsByCID[cid] = set
        }
        for cid in matcher.anyOf {
            var set = groupsByCID[cid] ?? []
            set.insert(group)
            groupsByCID[cid] = set
        }
        for cid in matcher.noneOf {
            var set = groupsByCID[cid] ?? []
            set.insert(group)
            groupsByCID[cid] = set
        }
        return group
    }
    
    public func uniqueEntity(_ matcher: Matcher) -> Entity? {
        let g = group(matcher)
        assert(g.count <= 1, "\(g.count) entites found for matcher \(matcher)")
        return g.first(where: {_ in return true})
    }
    
    public func uniqueEntity<T: UniqueComponent>(_ type: T.Type) -> Entity? {
        return uniqueEntity(Matcher(all: [type.cid]))
    }
    
    public func uniqueComponent<T: UniqueComponent>(_ type: T.Type) -> T? {
        let g = group(Matcher(all: [T.cid]))
        assert(g.count <= 1, "\(g.count) entites found")
        return g.first(where: {_ in return true})?.get()    }
    
    public func uniqueComponent<T: UniqueComponent>() -> T? {
        return uniqueComponent(T.self)
    }
    
    public func setUniqueComponent<T: UniqueComponent>(_ component: T) {
        if let e = uniqueEntity(Matcher(all: [component.cid])) {
            e.set(component)
        } else {
            createEntity().set(component)
        }
    }
    
    public func hasUniqueComponent<T: UniqueComponent>(_ type: T.Type) -> Bool {
        return uniqueEntity(Matcher(all: [type.cid])) != nil
    }
    
    public func index<T: Hashable, C: Component>(paused: Bool = false, keyBuilder: @escaping (C) -> T) -> Index<T, C> {
        let index = Index(ctx: self, paused: paused, keyBuilder: keyBuilder)
        for o in observers where o.ref is ContextObserver {
            (o.ref as! ContextObserver).created(index: index, in: self)
        }
        return index
    }
    
    public func observer(add o: ContextObserver){
        observers.update(with: ObserverBox(o))
    }
    
    public func observer(remove o: ContextObserver){
        observers.remove(ObserverBox(o))
    }
    
    fileprivate func destroyed(entity: Entity) {
        entities.remove(entity)
    }
    
    fileprivate func updated(component oldComponent: Component?, with newComponent: Component, in entity: Entity) {
        if newComponent is UniqueComponent,
            let uniqueEntity = uniqueEntity(Matcher(all: [newComponent.cid])),
            uniqueEntity != entity {
            uniqueEntity.remove(newComponent.cid)
            if uniqueEntity.isEmpty {
                uniqueEntity.destroy()
            }
        }
        for group in groupsByCID[newComponent.cid] ?? [] {
            group.checkOnUpdate(oldComponent: oldComponent, newComponent: newComponent, entity: entity)
        }
    }
    
    fileprivate func removed(component: Component, from entity: Entity) {
        for group in groupsByCID[component.cid] ?? [] {
            group.checkOnRemove(oldComponent: component, entity: entity)
        }
    }
}

public protocol ContextObserver : Observer {
    func created(entity: Entity, in context: Context)
    func created(group: Group, withMatcher matcher: Matcher, in context: Context)
    func created<T, C>(index: Index<T, C>, in context: Context)
}

private final class MainObserver: EntityObserver {
    weak var ctx: Context?
    init(ctx: Context) {
        self.ctx = ctx
    }
    public func updated(component oldComponent: Component?, with newComponent: Component, in entity: Entity) {
        ctx?.updated(component: oldComponent, with: newComponent, in: entity)
    }
    public func removed(component: Component, from entity: Entity) {
        ctx?.removed(component: component, from: entity)
    }
    public func destroyed(entity: Entity) {
        ctx?.destroyed(entity: entity)
    }
}

extension Context {
    public func collector(for matcher: Matcher, type: Collector.ChangeOptions = .added, paused: Bool = false) -> Collector {
        return Collector(group: self.group(matcher), type: type, paused: paused)
    }
    public func all(_ cids: Set<CID>, any: Set<CID> = [], none: Set<CID> = []) -> Group {
        return self.group(Matcher(all: cids, any: any, none: none))
    }
    public func any(_ cids: Set<CID>, none: Set<CID> = []) -> Group {
        return self.group(Matcher(any: cids, none: none))
    }
}
