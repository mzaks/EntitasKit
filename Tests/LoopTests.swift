//
//  LoopTests.swift
//  Entitas-Swift
//
//  Created by Maxim Zaks on 19.06.17.
//  Copyright © 2017 Maxim Zaks. All rights reserved.
//

import XCTest
@testable import EntitasKit

class LoopTests: XCTestCase {
    
    final class R1: ReactiveSystem, InitSystem, TeardownSystem {
        let name = "R1"
        let ctx: Context
        let collector: Collector
        init(ctx: Context) {
            self.ctx = ctx
            self.collector = Collector(group: self.ctx.group(Position.matcher), type: .addedOrUpdated)
        }
        
        func initialise() {
            ctx.createEntity().set(Position(x: 0, y: 0))
        }
        
        func execute(entities: Set<Entity>) {
            for e in entities {
                let pos: Position = e.get()!
                e.set(Position(x: pos.x + 1, y: pos.y + 1))
            }
        }
        func teardown() {
            for e in ctx.group(Position.matcher) {
                e.destroy()
            }
        }
    }
    
    final class S1: ExecuteSystem, CleanupSystem, TeardownSystem {
        let name = "S1"
        let ctx: Context
        
        init(ctx: Context) {
            self.ctx = ctx
        }
        
        func execute() {
            ctx.createEntity().set(Name(value: "Max"))
        }
        func cleanup() {
            for e in ctx.group(Name.matcher) {
                e.destroy()
            }
        }
        func teardown() {
            
        }
    }
    
    func testLoop() {
        let ctx = Context()
        let logger = Logger()
        let loop = Loop(name: "Main Loop", systems: [
            S1(ctx: ctx),
            R1(ctx: ctx)
        ], logger: logger)
        
        
        loop.initialise()
        loop.execute()
        loop.cleanup()
        loop.execute()
        loop.cleanup()
        
        let g1 = ctx.group(Position.matcher)
        XCTAssertEqual(g1.count, 1)
        XCTAssertEqual(g1.first(where: {_ in true})?.get(Position.self)?.x, 2)
        XCTAssertEqual(g1.first(where: {_ in true})?.get(Position.self)?.y, 2)
        
        let g2 = ctx.group(Name.matcher)
        XCTAssertEqual(g2.count, 0)
        
        loop.teardown()
        
        XCTAssertEqual(g1.count, 0)
        
        XCTAssertEqual(logger.log, [
            "willInitR1",
            "didInitR1",
            "willExecuteS1",
            "didExecuteS1",
            "willExecuteR1",
            "didExecuteR1",
            "willCleanupS1",
            "didCleanupS1",
            "willExecuteS1",
            "didExecuteS1",
            "willExecuteR1",
            "didExecuteR1",
            "willCleanupS1",
            "didCleanupS1",
            "willTeardownS1",
            "didTeardownS1",
            "willTeardownR1",
            "didTeardownR1",
        ])
    }
    
    final class SR1: StrictReactiveSystem {
        let name = "SR1"
        let ctx: Context
        let collector: Collector
        init(ctx: Context) {
            self.ctx = ctx
            self.collector = Collector(group: self.ctx.group(Name.matcher), type: .addedOrUpdated)
        }
        
        var entities: [Entity] = []
        
        func execute(entities: [Entity]) {
            for e in entities {
                self.entities.append(e)
            }
        }
        
    }
    
    func testStricktReactiveSystem() {
        let ctx = Context()
        let system = SR1(ctx: ctx)
        system.execute()
        XCTAssertEqual(system.entities.count, 0)
        
        let e = ctx.createEntity().set(Name(value: "Maxim"))
        
        system.execute()
        XCTAssertEqual(system.entities.count, 1)
        
        e.set(Name(value: "Max"))
        
        system.execute()
        XCTAssertEqual(system.entities.count, 2)
        
        e.set(Name(value: "Maxi"))
        e.destroy()
        
        system.execute()
        XCTAssertEqual(system.entities.count, 2)
    }
    
}
