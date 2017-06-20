//
//  EntityTests.swift
//  Entitas-Swift
//
//  Created by Maxim Zaks on 04.06.17.
//  Copyright © 2017 Maxim Zaks. All rights reserved.
//

import Foundation

import XCTest
@testable import EntitasKit

class EntityTests: XCTestCase {
    
    let observerStub = EntityObserverStub()
    
    func testCreateEntityGetNilForPsotioncomponent() {
        let e = Entity(index: 0, mainObserver: observerStub)
        let p : Position? = e.get()
        
        XCTAssertNil(p)
    }
    
    func testCreateEntitySetAndGetPosition() {
        let e = Entity(index: 0, mainObserver: observerStub)
        e.set(Position(x: 1, y: 3))
        let p : Position! = e.get()
        
        XCTAssertEqual(p.x, 1)
        XCTAssertEqual(p.y, 3)
    }
    
    func testUpdatePosition() {
        let e = Entity(index: 0, mainObserver: observerStub)
        e.set(Position(x: 1, y: 3))
        e.set(Position(x: 5, y: 8))
        let p : Position! = e.get()
        
        XCTAssertEqual(p.x, 5)
        XCTAssertEqual(p.y, 8)
    }
    
    func testRemovePosition() {
        let e = Entity(index: 0, mainObserver: observerStub)
        e.set(Position(x: 1, y: 3))
        e.remove(Position.cid)
        let p : Position? = e.get()
        
        XCTAssertNil(p)
    }
    
    func testHasPosition() {
        let e = Entity(index: 0, mainObserver: observerStub)
        e.set(Position(x: 1, y: 3))
        
        XCTAssertTrue(e.has(Position.cid))
    }
    
    func testDestroyEntity() {
        let e = Entity(index: 0, mainObserver: observerStub)
        e.set(Position(x: 1, y: 3))
        XCTAssertTrue(e.has(Position.cid))
        e.destroy()
        XCTAssertFalse(e.has(Position.cid))
    }
    
    func testGetPositionByType() {
        let e = Entity(index: 0, mainObserver: observerStub)
        e.set(Position(x: 1, y: 3))
        
        let position = e.get(Position.self)!
        XCTAssertEqual(position.x, 1)
        XCTAssertEqual(position.y, 3)
    }
}
