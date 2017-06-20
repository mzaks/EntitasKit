//
//  ContextTests.swift
//  Entitas-Swift
//
//  Created by Maxim Zaks on 05.06.17.
//  Copyright © 2017 Maxim Zaks. All rights reserved.
//

import XCTest
@testable import EntitasKit

class ContextTests: XCTestCase {
    
    func testCreateEntityAndIncrementIndex() {
        let ctx = Context()
        let e = ctx.createEntity()
        XCTAssertEqual(e.creationIndex, 1)
        
        let e1 = ctx.createEntity()
        XCTAssertEqual(e1.creationIndex, 2)
        
        let e2 = ctx.createEntity()
        XCTAssertEqual(e2.creationIndex, 3)
        
        let e3 = ctx.createEntity()
        XCTAssertEqual(e3.creationIndex, 4)
        
        XCTAssertEqual(ctx.entities.count, 4)
        XCTAssertEqual([e, e1, e2, e3], ctx.entities.sorted(by: <))
    }
    
    
    func testCreateEntityIncrementIndexWitEntityDestroyAndReuse() {
        let ctx = Context()
        unowned let e = ctx.createEntity()
        XCTAssertEqual(e.creationIndex, 1)
        let e1 = ctx.createEntity()
        XCTAssertEqual(e1.creationIndex, 2)
        
        e.destroy()
        XCTAssertEqual(ctx.entities.count, 1)
        
        let e2 = ctx.createEntity()
        XCTAssertEqual(e2.creationIndex, 3)
        
        let e3 = ctx.createEntity()
        XCTAssertEqual(e3.creationIndex, 4)
        
        XCTAssert(e === e2)
    }
    
    func testCreateEntityIncrementIndexWitEntityDestroyAndWithoutReuse() {
        let ctx = Context()
        let e = ctx.createEntity()
        XCTAssertEqual(e.creationIndex, 1)
        let e1 = ctx.createEntity()
        XCTAssertEqual(e1.creationIndex, 2)
        e.destroy()
        XCTAssertEqual(ctx.entities.count, 1)
        
        let e2 = ctx.createEntity()
        XCTAssertEqual(e2.creationIndex, 3)
        let e3 = ctx.createEntity()
        XCTAssertEqual(e3.creationIndex, 4)
        
        XCTAssert(e !== e2)
    }
    
    func testGetGroup() {
        let ctx = Context()
        let e1 = ctx.createEntity().set(Position(x: 1, y: 2))
        let e2 = ctx.createEntity().set(Position(x: 2, y: 3))
        let e3 = ctx.createEntity().set(Name(value: "Max"))
        
        let group = ctx.getGroup(Position.matcher)
        
        XCTAssertEqual(group.count, 2)
        
        for e in group {
            XCTAssert(e.has(Position.cid))
        }
        XCTAssertEqual([e1, e2], group.sorted())
        
        e3.set(Position(x: 12, y: 14))
        XCTAssertEqual([e1, e2, e3], group.sorted())
        
        e3.remove(Position.cid)
        XCTAssertEqual([e1, e2], group.sorted())
    }
    
    func testGetGroupAll() {
        let ctx = Context()
        let e1 = ctx.createEntity().set(Position(x: 1, y: 2))
        let e2 = ctx.createEntity().set(Position(x: 2, y: 3))
        let e3 = ctx.createEntity().set(Name(value: "Max")).set(Position(x: 5, y: 6))
        let e4 = ctx.createEntity().set(Name(value: "Max0"))
        
        let group1 = ctx.getGroup(Matcher(all: [Position.cid, Name.cid]))
        XCTAssertEqual(group1.sorted(), [e3])
        
        let group2 = ctx.getGroup(Matcher(any: [Position.cid, Name.cid]))
        XCTAssertEqual(group2.sorted(), [e1, e2, e3, e4])
        
        let group3 = ctx.getGroup(Matcher(any: [Position.cid], none: [Name.cid]))
        XCTAssertEqual(group3.sorted(), [e1, e2])
        
        let group4 = ctx.getGroup(Matcher(all: [Name.cid], none: [Position.cid]))
        XCTAssertEqual(group4.sorted(), [e4])
        
        let group5 = ctx.getGroup(Matcher(all: [Position.cid], any:[Name.cid]))
        XCTAssertEqual(group5.sorted(), [e3])
    }
    
    func testUniqueEntity() {
        let ctx = Context()
        ctx.createEntity().set(Position(x: 1, y: 2))
        ctx.createEntity().set(Position(x: 2, y: 3))
        let e3 = ctx.createEntity().set(Name(value: "Max")).set(God())
        
        let e = ctx.getUniqueEntity(Name.matcher)
        
        XCTAssertNotNil(e)
        XCTAssert(e === e3)
    }
    
    func testUniqueComponent() {
        let ctx = Context()
        ctx.createEntity().set(Position(x: 1, y: 2))
        ctx.createEntity().set(Position(x: 2, y: 3))
        let e1 = ctx.createEntity().set(Name(value: "Max1")).set(God())
        let e2 = ctx.createEntity().set(Name(value: "Max2")).set(Person())
        
        do {
            let c : God? = ctx.getUniqueComponent()
            XCTAssertNotNil(c)
            
            let e = ctx.getUniqueEntity(God.matcher)
            XCTAssert(e === e1)
        }
        
        e2.set(God())
        
        do {
            let c : God? = ctx.getUniqueComponent()
            XCTAssertNotNil(c)
            
            let e = ctx.getUniqueEntity(God.matcher)
            XCTAssert(e === e2)
        }
    }
    
    func testUniqueComponentCreation() {
        let ctx = Context()
        
        XCTAssert(ctx.hasUniqueComponent(God.self) == false)
        
        ctx.setUniqueComponent(God())
        
        XCTAssert(ctx.hasUniqueComponent(God.self))
        
        // Replace context
        ctx.setUniqueComponent(God())
        
        XCTAssert(ctx.hasUniqueComponent(God.self))
        
        let e = ctx.getUniqueEntity(God.self)
        XCTAssertNotNil(e)
        XCTAssert(e?.waitingForRebirth == false)
        
        let e2 = ctx.createEntity().set(God())
        
        XCTAssert(e !== e2)
        XCTAssert(ctx.getUniqueEntity(God.self) === e2)
        XCTAssert(e?.waitingForRebirth == true)
    }
}
