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
    private var entityPool: [Entity] = []
    private var entityIndex: Int = 0
    lazy private var mainObserver: MainObserver = {
        return MainObserver(ctx: self)
    }()
    private var groups: [Matcher: Group] = [:]
    private var groupsByCID: [CID: Set<Group>] = [:]
    
    public func createEntity() -> Entity {
        entityIndex += 1
        var pooledEntity: Entity? = nil
        for i in 0 ..< entityPool.count {
            unowned let e = entityPool[i]
            if CFGetRetainCount(e) <= 2 {
                pooledEntity = e
                entityPool.remove(at: i)
                break
            }
        }
        let e : Entity
        if let pooledEntity = pooledEntity {
            pooledEntity.creationIndex = entityIndex
            e = pooledEntity
        } else {
            e = Entity(index: entityIndex, mainObserver: mainObserver)
        }
        entities.insert(e)
        return e
    }
    
    public func getGroup(_ matcher: Matcher) -> Group {
        if let group = groups[matcher] {
            return group
        }
        
        let group = Group(matcher: matcher)
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
    
    public func getUniqueEntity(_ matcher: Matcher) -> Entity? {
        let g = getGroup(matcher)
        assert(g.count <= 1, "\(g.count) entites found for matcher \(matcher)")
        return g.first(where: {_ in return true})
    }
    
    public func getUniqueEntity<T: UniqueComponent>(_ type: T.Type) -> Entity? {
        return getUniqueEntity(Matcher(all: [type.cid]))
    }
    
    public func getUniqueComponent<T: UniqueComponent>() -> T? {
        let g = getGroup(Matcher(all: [T.cid]))
        assert(g.count <= 1, "\(g.count) entites found")
        return g.first(where: {_ in return true})?.get()
    }
    
    public func setUniqueComponent<T: UniqueComponent>(_ component: T) {
        if let e = getUniqueEntity(Matcher(all: [component.cid])) {
            e.set(component)
        } else {
            createEntity().set(component)
        }
    }
    
    public func hasUniqueComponent<T: UniqueComponent>(_ type: T.Type) -> Bool {
        return getUniqueEntity(Matcher(all: [type.cid])) != nil
    }
    
    public func getIndex<T: Hashable, C: Component>(paused: Bool = false, keyBuilder: @escaping (C) -> T) -> Index<T, C> {
        return Index(ctx: self, paused: paused, keyBuilder: keyBuilder)
    }
    
    fileprivate func destroyed(entity: Entity) {
        entities.remove(entity)
        entityPool.append(entity)
    }
    
    fileprivate func updated(component oldComponent: Component?, with newComponent: Component, in entity: Entity) {
        if newComponent is UniqueComponent,
            let uniqueEntity = getUniqueEntity(Matcher(all: [newComponent.cid])),
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
