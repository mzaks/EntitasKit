//
//  IndexTests.swift
//  Entitas-Swift
//
//  Created by Maxim Zaks on 18.06.17.
//  Copyright © 2017 Maxim Zaks. All rights reserved.
//

import XCTest
@testable import EntitasKit

class IndexTests: XCTestCase {
    
    func testIndex() {
        let ctx = Context()
        
        let e1 = ctx.createEntity().set(Size(value: 1))
        let e2 = ctx.createEntity().set(Size(value: 2))
        let e3 = ctx.createEntity().set(Size(value: 3))
        let e11 = ctx.createEntity().set(Size(value: 1))
        
        let index = ctx.index { (s: Size) -> Int in
            return s.value
        }
        
        XCTAssertEqual(index[2].first, e2)
        XCTAssertEqual(index[3].first, e3)
        XCTAssertEqual(index[1].map{$0}.sorted(), [e1, e11])
        
        e1.set(Size(value: 4))
        
        XCTAssertEqual(index[2].first, e2)
        XCTAssertEqual(index[3].first, e3)
        XCTAssertEqual(index[4].first, e1)
        XCTAssertEqual(index[1].map{$0}.sorted(), [e11])
        
        e1.remove(Size.cid)
        XCTAssertEqual(index[2].first, e2)
        XCTAssertEqual(index[3].first, e3)
        XCTAssertEqual(index[4].first, nil)
        XCTAssertEqual(index[1].map{$0}.sorted(), [e11])
        
        e1.set(Size(value: 1))
        XCTAssertEqual(index[2].first, e2)
        XCTAssertEqual(index[3].first, e3)
        XCTAssertEqual(index[4].first, nil)
        XCTAssertEqual(index[1].map{$0}.sorted(), [e1, e11])
    }
    
    func testIndexPaused() {
        let ctx = Context()
        
        let e1 = ctx.createEntity().set(Size(value: 1))
        let e2 = ctx.createEntity().set(Size(value: 2))
        let e3 = ctx.createEntity().set(Size(value: 3))
        let e11 = ctx.createEntity().set(Size(value: 1))
        
        let index = ctx.index(paused: true) { (s: Size) -> Int in
            return s.value
        }
        
        XCTAssertEqual(index[2].first, nil)
        XCTAssertEqual(index[3].first, nil)
        XCTAssertEqual(index[1].map{$0}.sorted(), [])
        
        index.isPaused = false
        
        XCTAssertEqual(index[2].first, e2)
        XCTAssertEqual(index[3].first, e3)
        XCTAssertEqual(index[1].map{$0}.sorted(), [e1, e11])
        
        index.isPaused = true
        
        XCTAssertEqual(index[2].first, nil)
        XCTAssertEqual(index[3].first, nil)
        XCTAssertEqual(index[1].map{$0}.sorted(), [])
        
        e1.set(Size(value: 4))
        e1.remove(Size.cid)
        
        index.isPaused = false
        
        XCTAssertEqual(index[2].first, e2)
        XCTAssertEqual(index[3].first, e3)
        XCTAssertEqual(index[1].map{$0}.sorted(), [e11])
    }
    
}
