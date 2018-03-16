//
//  RelevantEntityEventsTests.swift
//  EntitasKitTests
//
//  Created by Maxim Zaks on 16.03.18.
//  Copyright © 2018 Maxim Zaks. All rights reserved.
//

import XCTest
@testable import EntitasKit

class RelevantEntityEventsTests: XCTestCase {

    var entitasLogger: EntitasLogger!
    var ctx : Context!
    var ctx2 : Context!

    override func setUp() {
        ctx = Context()
        ctx2 = Context()
        entitasLogger = EntitasLogger(contexts: [(ctx, "mainCtx"), (ctx2, "secondaryCtx")])
    }

    func testCreateEntityAndAddComponents() {
        let e = ctx.createEntity()
        e += Position(x: 1, y: 2)
        e += God()

        XCTAssertEqual(entitasLogger.relevantEntityEvents(entityId: 1, contextId: 0), [0, 1, 2])
    }

    func testCreateEntityAndAddComponentsAndDestroyEntity() {
        let e = ctx.createEntity()
        e += Position(x: 1, y: 2)
        e += God()
        e.destroy()

        XCTAssertEqual(entitasLogger.relevantEntityEvents(entityId: 1, contextId: 0), [0, 5])
    }

    func testCreateEntityAddComponentsAndReplace() {
        let e = ctx.createEntity()
        e += Position(x: 1, y: 2)
        e += God()
        e += Position(x: 2, y: 2)

        XCTAssertEqual(entitasLogger.relevantEntityEvents(entityId: 1, contextId: 0), [0, 2, 3])
    }

    func testCreateEntityAddComponentsReplaceAndRemove() {
        let e = ctx.createEntity()
        e += Position(x: 1, y: 2)
        e += God()
        e += Position(x: 2, y: 2)
        e -= God.cid

        XCTAssertEqual(entitasLogger.relevantEntityEvents(entityId: 1, contextId: 0), [0, 3])
    }

    func testCreateEntityAddComponentsAndIgnore() {
        let e = ctx.createEntity()
        e += Position(x: 1, y: 2)
        entitasLogger.willExecute("S1")
        e += God()
        entitasLogger.didExecute("S1")


        XCTAssertEqual(entitasLogger.relevantEntityEvents(entityId: 1, contextId: 0), [0, 1, 3])
    }
}
