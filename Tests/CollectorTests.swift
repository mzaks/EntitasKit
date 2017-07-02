//
//  CollectorTests.swift
//  Entitas-Swift
//
//  Created by Maxim Zaks on 18.06.17.
//  Copyright © 2017 Maxim Zaks. All rights reserved.
//

import XCTest
@testable import EntitasKit

class CollectorTests: XCTestCase {
    
    func testCreateCollectorForAdded() {
        let ctx = Context()
        let g = ctx.group(Position.matcher)
        let collector = Collector(group: g, type: .added)
        
        XCTAssertNil(collector.first)
        
        ctx.createEntity().set(Position(x: 1, y: 4))
        
        do {
            let e = collector.first
            XCTAssertEqual(e?.get(Position.self)?.x, 1)
            XCTAssertEqual(e?.get(Position.self)?.y, 4)
            
            e?.set(Position(x:2, y: 2))
            XCTAssertNil(collector.first)
        }
        
        ctx.createEntity().set(Position(x: 2, y: 4))
        ctx.createEntity().set(Position(x: 3, y: 4))
        ctx.createEntity().set(Position(x: 4, y: 4))
        
        XCTAssertEqual(collector.collected.count, 3)
        XCTAssertEqual(collector.collected.count, 0)
    }
    
    func testCreateCollectorForAddedOrUpdated() {
        let ctx = Context()
        let g = ctx.group(Position.matcher)
        let collector = Collector(group: g, type: .addedOrUpdated)
        
        XCTAssertNil(collector.first)
        
        ctx.createEntity().set(Position(x: 1, y: 4))
        
        do {
            let e = collector.first
            XCTAssertEqual(e?.get(Position.self)?.x, 1)
            XCTAssertEqual(e?.get(Position.self)?.y, 4)
            
            e?.set(Position(x:2, y: 2))
            let e1 = collector.first
            XCTAssertEqual(e1?.get(Position.self)?.x, 2)
            XCTAssertEqual(e1?.get(Position.self)?.y, 2)
        }
    }
    
    func testCreateCollectorForRemoved(){
        let ctx = Context()
        let g = ctx.group(Position.matcher)
        let collector = Collector(group: g, type: .removed)
        
        XCTAssertNil(collector.first)
        
        let e = ctx.createEntity().set(Position(x: 1, y: 4))
        
        XCTAssertNil(collector.first)
            
        e.set(Position(x:2, y: 2))
        XCTAssertNil(collector.first)
            
        e.destroy()
        XCTAssert(e === collector.first)
    }
    
    func testDrainAndPause() {
        let ctx = Context()
        let g = ctx.group(Position.matcher)
        let collector = Collector(group: g, type: .addedUpdatedOrRemoved)
        
        XCTAssertNil(collector.first)
        
        let e = ctx.createEntity().set(Position(x: 1, y: 4))
        
        XCTAssert(collector.first === e)
        
        e.set(Position(x: 2, y: 2))
        
        XCTAssert(collector.drainAndPause().first === e)
        
        e.set(Position(x: 3, y: 3))
        
        ctx.createEntity().set(Position(x: 5, y: 5))
        
        e.destroy()
        
        XCTAssertNil(collector.first)
    }
    
    func testCollectedAndMatching() {
        let ctx = Context()
        let g = ctx.group(Position.matcher)
        let collector = Collector(group: g, type: .added)
        
        let e = ctx.createEntity().set(Position(x: 1, y: 4))
        e.destroy()
        
        XCTAssertEqual(collector.collectedAndMatching.count, 0)
    }
    
    func testCollectorIsEmpty() {
        let ctx = Context()
        let g = ctx.group(Position.matcher)
        let collector = Collector(group: g, type: .added)
        
        XCTAssert(collector.isEmpty)
        
        ctx.createEntity().set(Position(x: 1, y: 4))
        
        XCTAssert(collector.isEmpty == false)
    }
    
}
