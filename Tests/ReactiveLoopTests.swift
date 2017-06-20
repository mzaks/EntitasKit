//
//  ReactiveLoopTests.swift
//  Entitas-Swift
//
//  Created by Maxim Zaks on 20.06.17.
//  Copyright © 2017 Maxim Zaks. All rights reserved.
//

import XCTest
@testable import EntitasKit

class ReactiveLoopTests: XCTestCase {
    
    final class R1: ReactiveSystem {
        let name = "R1"
        let ctx: Context
        let collector: Collector
        let block: ()->()
        init(ctx: Context, block: @escaping ()->()) {
            self.ctx = ctx
            self.block = block
            self.collector = Collector(group: self.ctx.group(Matcher(all:[Position.cid, Size.cid])), type: .addedOrUpdated)
        }
        
        func execute(entities: Set<Entity>) {
            for _ in entities {
                block()
            }
        }
        
    }
    
    final class R2: ReactiveSystem {
        let name = "R2"
        let ctx: Context
        let collector: Collector
        let block: ()->()
        init(ctx: Context, block: @escaping ()->()) {
            self.ctx = ctx
            self.block = block
            self.collector = Collector(group: self.ctx.group(Name.matcher), type: .addedOrUpdated)
        }
        
        func execute(entities: Set<Entity>) {
            for _ in entities {
                block()
            }
        }
        
    }
    
    func testReactiveLoop() {
        let ctx = Context()
        let expect = expectation(description: "system was executed")
        var counter = 0
        let logger = Logger()
        let loop = ReactiveLoop(ctx:ctx, logger: logger, systems:[
            R1(ctx:ctx){
                counter += 1
                expect.fulfill()
            }])
        
        let e = ctx.createEntity().set(Position(x: 1, y: 2)).set(Size(value: 1))
        
        e.destroy()
        
        waitForExpectations(timeout: 1.0) { (_) in
            XCTAssertEqual(counter, 1)
            XCTAssertEqual(logger.log, [
                "willExecuteR1",
                "didExecuteR1"
            ])
        }
        XCTAssertNotNil(loop)
    }
    
    func testReactiveWithReTriggeringLoop() {
        let ctx = Context()
        let expect = expectation(description: "system was executed")
        var counter = 0
        let logger = Logger()
        let r1 = R1(ctx:ctx){
            counter += 1
            ctx.createEntity().set(Name(value: "Maxim"))
        }
        let r2 = R2(ctx:ctx){
            counter += 1
            expect.fulfill()
        }
        let loop = ReactiveLoop(ctx:ctx, logger: logger, systems:[r2, r1])
        
        
        let e = ctx.createEntity().set(Position(x: 1, y: 2)).set(Size(value: 1))
        
        e.destroy()
        
        waitForExpectations(timeout: 1.0) { (_) in
            XCTAssertEqual(counter, 2)
            XCTAssertEqual(logger.log, [
                "willExecuteR2",
                "didExecuteR2",
                "willExecuteR1",
                "didExecuteR1",
                "willExecuteR2",
                "didExecuteR2",
                "willExecuteR1",
                "didExecuteR1"
                ])
        }
        XCTAssertNotNil(loop)
    }
    
    func testReactiveLoopWithDelay() {
        let ctx = Context()
        let expect = expectation(description: "system was executed")
        var counter = 0
        let logger = Logger()
        let time = CFAbsoluteTimeGetCurrent()
        let loop = ReactiveLoop(ctx:ctx, logger: logger, delay: 0.1, systems:[
            R1(ctx:ctx){
                counter += 1
                expect.fulfill()
            }])
        
        let e = ctx.createEntity().set(Position(x: 1, y: 2)).set(Size(value: 1))
        
        e.destroy()
        
        waitForExpectations(timeout: 1.0) { (_) in
            XCTAssertEqual(counter, 1)
            XCTAssertEqual(logger.log, [
                "willExecuteR1",
                "didExecuteR1"
                ])
            XCTAssertGreaterThanOrEqual(CFAbsoluteTimeGetCurrent() - time, 0.1)
        }
        XCTAssertNotNil(loop)
    }
    
}
