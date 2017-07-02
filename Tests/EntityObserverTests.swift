//
//  EntityObserverTests.swift
//  Entitas-Swift
//
//  Created by Maxim Zaks on 04.06.17.
//  Copyright © 2017 Maxim Zaks. All rights reserved.
//

import Foundation

import XCTest
@testable import EntitasKit

class EntityObserverTests: XCTestCase {
    
    class Observer: EntityObserver {
        var updatedData: [(Component?, Component, Entity)] = []
        func updated(component oldComponent: Component?, with newComponent: Component, in entity: Entity){
            updatedData.append((oldComponent, newComponent, entity))
        }
        var removedData: [(Component, Entity)] = []
        func removed(component: Component, from entity: Entity){
            removedData.append((component, entity))
        }
        var destroyedData: [Entity] = []
        func destroyed(entity: Entity){
            destroyedData.append(entity)
        }
    }
    
    func testAddComponent() {
        let observer = Observer()
        let e = Entity(index: 0, mainObserver: observer)
        e.set(Position(x: 1, y: 2))
        e.set(Position(x: 3, y: 4))
        
        XCTAssertEqual(observer.updatedData.count, 2)
        
        let first = observer.updatedData[0]
        XCTAssertNil(first.0)
        let pos1 = first.1 as! Position
        XCTAssertEqual(pos1.x, 1)
        XCTAssertEqual(pos1.y, 2)
        XCTAssert(first.2 === e)
        
        let second = observer.updatedData[1]
        let pos20 = second.0 as! Position
        XCTAssertEqual(pos20.x, 1)
        XCTAssertEqual(pos20.y, 2)
        let pos21 = second.1 as! Position
        XCTAssertEqual(pos21.x, 3)
        XCTAssertEqual(pos21.y, 4)
        XCTAssert(second.2 === e)
    }
    
    func testRemoveComponent() {
        let observer = Observer()
        let e = Entity(index: 0, mainObserver: observer)
        e.set(Position(x: 1, y: 2))
        
        e.remove(Position.cid)
        e.remove(Position.cid)
        
        XCTAssertEqual(observer.removedData.count, 1)
        
        let p = observer.removedData[0].0 as! Position
        XCTAssertEqual(p.x, 1)
        XCTAssertEqual(p.y, 2)
        
        XCTAssert(observer.removedData[0].1 === e)
    }
    
    func testDestroyEntity() {
        let observer = Observer()
        let observer2 = Observer()
        let e = Entity(index: 0, mainObserver: observer)
        e.observer(add: observer2)
        e.set(Position(x: 1, y: 2))
        
        e.destroy()
        
        XCTAssertEqual(observer.removedData.count, 1)
        XCTAssertEqual(observer2.removedData.count, 1)
        
        let p = observer.removedData[0].0 as! Position
        XCTAssertEqual(p.x, 1)
        XCTAssertEqual(p.y, 2)
        
        let p2 = observer2.removedData[0].0 as! Position
        XCTAssertEqual(p2.x, 1)
        XCTAssertEqual(p2.y, 2)
        
        XCTAssert(observer.removedData[0].1 === e)
        XCTAssert(observer2.removedData[0].1 === e)
        
        XCTAssertEqual(observer.destroyedData.count, 1)
        XCTAssertEqual(observer2.destroyedData.count, 1)
        XCTAssert(observer.destroyedData[0] === e)
        XCTAssert(observer2.destroyedData[0] === e)
    }
    
    func testAddComponentMultipleObservers() {
        let observer0 = Observer()
        let observer1 = Observer()
        let observer2 = Observer()
        let e = Entity(index: 0, mainObserver: observer0)
        e.observer(add: observer1)
        e.observer(add: observer2)
        e.set(Position(x: 1, y: 2))
        
        for observer in [observer0, observer1, observer2] {
            XCTAssertEqual(observer.updatedData.count, 1)
            
            let first = observer.updatedData[0]
            XCTAssertNil(first.0)
            let pos1 = first.1 as! Position
            XCTAssertEqual(pos1.x, 1)
            XCTAssertEqual(pos1.y, 2)
            XCTAssert(first.2 === e)
        }
        
    }
    
    func testAddComponentMultipleObserversWithObserverRemoval() {
        let observer0 = Observer()
        let observer1 = Observer()
        let observer2 = Observer()
        let e = Entity(index: 0, mainObserver: observer0)
        e.observer(add: observer1)
        e.observer(add: observer2)
        e.set(Position(x: 1, y: 2))
        
        e.observer(remove: observer1)
        
        e.set(Size(value:13))
        
        for observer in [observer0, observer2] {
            XCTAssertEqual(observer.updatedData.count, 2)
            
            let first = observer.updatedData[0]
            XCTAssertNil(first.0)
            let pos1 = first.1 as! Position
            XCTAssertEqual(pos1.x, 1)
            XCTAssertEqual(pos1.y, 2)
            XCTAssert(first.2 === e)
            
            let second = observer.updatedData[1]
            XCTAssertNil(second.0)
            let size = second.1 as! Size
            XCTAssertEqual(size.value, 13)
            XCTAssert(second.2 === e)
        }
        
        XCTAssertEqual(observer1.updatedData.count, 1)
        
        let first = observer1.updatedData[0]
        XCTAssertNil(first.0)
        let pos1 = first.1 as! Position
        XCTAssertEqual(pos1.x, 1)
        XCTAssertEqual(pos1.y, 2)
        XCTAssert(first.2 === e)
        
    }
}
