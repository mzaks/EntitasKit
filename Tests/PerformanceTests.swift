//
//  PerformanceTests.swift
//  EntitasKit
//
//  Created by Maxim Zaks on 25.06.17.
//  Copyright © 2017 Maxim Zaks. All rights reserved.
//

import XCTest
import EntitasKit

class PerformanceTests: XCTestCase {
    
    var ctx : Context!
    
    override func setUp() {
        super.setUp()
        ctx = Context()
    }
    
    func testCreatingEntities() {
        measure { [unowned self] in
            self.createTenThausendEntities()
        }
    }
    
    func testCreatingEntitiesAndDestroy() {
        measure { [unowned self] in
            self.createTenThausendEntities()
            for e in self.ctx.entities {
                e.destroy()
            }
        }
    }
    
    func testReCreatingEntities() {
        measure { [unowned self] in
            self.createTenThausendEntities()
            for e in self.ctx.entities {
                e.destroy()
            }
            self.createTenThausendEntities()
        }
    }
    
    func testCreateMoveDestroy() {
        measure { [unowned self] in
            let group = self.ctx.group(Position.matcher)
            self.createTenThausendEntitiesWithPosition()
            for _ in 1...5 {
                for e in group {
                    let pos: Position = e.get()!
                    e.set(Position(x: pos.x + 3, y: pos.y - 1))
                }
            }
            for e in self.ctx.entities {
                e.destroy()
            }
        }
    }
    
    func createTenThausendEntities() {
        for _ in 1...10_000 {
            _ = ctx.createEntity()
        }
    }
    
    func createTenThausendEntitiesWithPosition() {
        for i in 1...10_000 {
            _ = ctx.createEntity().set(Position(x: i+1, y: i+2))
        }
    }
}
