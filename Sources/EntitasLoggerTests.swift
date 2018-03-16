//
//  EntitasLoggerTests.swift
//  EntitasKitTests
//
//  Created by Maxim Zaks on 04.03.18.
//  Copyright © 2018 Maxim Zaks. All rights reserved.
//

import XCTest
@testable import EntitasKit

class EntitasLoggerTests: XCTestCase {

    var entitasLogger: EntitasLogger!
    var ctx : Context!
    var ctx2 : Context!

    override func setUp() {
        ctx = Context()
        ctx2 = Context()
        entitasLogger = EntitasLogger(contexts: [(ctx, "mainCtx"), (ctx2, "secondaryCtx")])
    }

    func testPushAndPopSystemsCalls() {
        entitasLogger.willInit("S1")
        entitasLogger.didInit("S1")

        XCTAssertEqual(entitasLogger.systemNames, ["S1"])

        entitasLogger.willInit("S2")
        Thread.sleep(until: Date(timeIntervalSinceNow: 0.01))
        entitasLogger.didInit("S2")

        XCTAssertEqual(entitasLogger.systemNames, ["S1", "S2"])
        XCTAssertEqual(entitasLogger.eventTypes, [EventType.willInit, EventType.didInit])
        XCTAssertEqual(entitasLogger.systemNameIds, [1, 1])
    }

    func testHierarchicalSystemCalls() {
        entitasLogger.willInit("S1")
        entitasLogger.willInit("S2")
        entitasLogger.didInit("S2")
        entitasLogger.willInit("S3")
        Thread.sleep(until: Date(timeIntervalSinceNow: 0.01))
        entitasLogger.didInit("S3")
        entitasLogger.willInit("S4")
        entitasLogger.didInit("S4")
        entitasLogger.willInit("S5")
        entitasLogger.willInit("S6")
        Thread.sleep(until: Date(timeIntervalSinceNow: 0.01))
        entitasLogger.didInit("S6")
        entitasLogger.didInit("S5")
        entitasLogger.didInit("S1")

        XCTAssertEqual(entitasLogger.systemNames, ["S1", "S2", "S3", "S4", "S5", "S6"])
        XCTAssertEqual(
            entitasLogger.eventTypes,
            [
                EventType.willInit, // S1
                EventType.willInit, EventType.didInit, // S3
                EventType.willInit, // S5
                EventType.willInit, EventType.didInit, // S6
                EventType.didInit, // S5
                EventType.didInit, // S1
            ]
        )
        XCTAssertEqual(
            entitasLogger.systemNameIds,
            [0, 2, 2, 4, 5, 5, 4, 0]
        )
    }

    func testExecuteSystem() {
        entitasLogger.willExecute("S1")
        Thread.sleep(until: Date(timeIntervalSinceNow: 0.01))
        entitasLogger.didExecute("S1")

        XCTAssertEqual(entitasLogger.systemNames, ["S1"])
        XCTAssertEqual(entitasLogger.eventTypes, [EventType.willExec, EventType.didExec])
        XCTAssertEqual(entitasLogger.systemNameIds, [0, 0])
    }

    func testCleanupSystem() {
        entitasLogger.willCleanup("S1")
        Thread.sleep(until: Date(timeIntervalSinceNow: 0.01))
        entitasLogger.didCleanup("S1")

        XCTAssertEqual(entitasLogger.systemNames, ["S1"])
        XCTAssertEqual(entitasLogger.eventTypes, [EventType.willCleanup, EventType.didCleanup])
        XCTAssertEqual(entitasLogger.systemNameIds, [0, 0])
    }

    func testTeardownSystem() {
        entitasLogger.willTeardown("S1")
        Thread.sleep(until: Date(timeIntervalSinceNow: 0.01))
        entitasLogger.didTeardown("S1")

        XCTAssertEqual(entitasLogger.systemNames, ["S1"])
        XCTAssertEqual(entitasLogger.eventTypes, [EventType.willTeardown, EventType.didTeardown])
        XCTAssertEqual(entitasLogger.systemNameIds, [0, 0])
    }

    func testEntityCreateAndDestroy() {
        let e1 = ctx.createEntity()
        e1.destroy()
        let e2 = ctx.createEntity()
        let e3 = ctx.createEntity()
        e3.destroy()
        e2.destroy()

        XCTAssertEqual(entitasLogger.systemNames, [])
        XCTAssertEqual(
            entitasLogger.eventTypes,
            [
                EventType.created, EventType.destroyed,
                EventType.created,
                EventType.created,
                EventType.destroyed,
                EventType.destroyed
            ]
        )
        XCTAssertEqual(
            entitasLogger.systemNameIds,
            [
                SystemNameId.max, SystemNameId.max,
                SystemNameId.max, SystemNameId.max,
                SystemNameId.max, SystemNameId.max
            ]
        )
        XCTAssertEqual(entitasLogger.entityIds, [1, 1, 2, 3, 3, 2])
    }

    func testEntityCreateAndDestroyMultiplCtx() {
        let e1 = ctx.createEntity()
        let e2 = ctx2.createEntity()
        e2.destroy()
        e1.destroy()

        XCTAssertEqual(entitasLogger.entityIds, [1, 1, 1, 1])
        XCTAssertEqual(entitasLogger.contextIds, [0, 1, 1, 0])
    }

    func testEntityCreateAndDestroyInsideSystems() {
        entitasLogger.willExecute("S1")
        entitasLogger.willExecute("S2")
        let e1 = ctx.createEntity()
        entitasLogger.didExecute("S2")
        entitasLogger.willExecute("S3")
        entitasLogger.didExecute("S3")
        let e2 = ctx2.createEntity()
        e2.destroy()
        entitasLogger.didExecute("S1")
        e1.destroy()


        XCTAssertEqual(
            entitasLogger.eventTypes,
            [
                EventType.willExec,
                .willExec,
                .created,
                .didExec,
                .created,
                .destroyed,
                .didExec,
                .destroyed
            ]
        )

        XCTAssertEqual(entitasLogger.entityIds, [EntityId.max, .max, 1, .max, 1, 1, .max, 1])
        XCTAssertEqual(entitasLogger.contextIds, [ContextId.max, .max, 0, .max, 1, 1, .max, 0])
        XCTAssertEqual(entitasLogger.systemNameIds, [0, 1, 1, 1, 0, 0, 0, .max])
    }

    func testAddUpdateRemoveComponent() {
        let e = ctx.createEntity()
        e += Position(x: 1, y: 2)
        e += Position(x: 2, y: 2)
        e -= Position.cid

        XCTAssertEqual(
            entitasLogger.eventTypes,
            [
                .created,
                .added,
                .replaced,
                .removed
            ]
        )
        XCTAssertEqual(entitasLogger.entityIds, [1, 1, 1, 1])
        XCTAssertEqual(entitasLogger.contextIds, [0, 0, 0, 0])
        XCTAssertEqual(entitasLogger.compNames, ["Position"])
        XCTAssertEqual(entitasLogger.compNameIds, [CompNameId.max, 0, 0, 0])

    }

    func testAddUpdateRemoveComponentInsideSystems() {
        entitasLogger.willExecute("S1")
        let e = ctx.createEntity()
        let e2 = ctx2.createEntity()
        e += Position(x: 1, y: 2)
        e += Position(x: 2, y: 2)
        e -= Position.cid
        e2 += God()
        entitasLogger.didExecute("S1")

        XCTAssertEqual(
            entitasLogger.eventTypes,
            [
                .willExec,
                .created,
                .created,
                .added,
                .replaced,
                .removed,
                .added,
                .didExec
            ]
        )
        XCTAssertEqual(entitasLogger.entityIds, [EntityId.max, 1, 1, 1, 1, 1, 1, .max])
        XCTAssertEqual(entitasLogger.contextIds, [ContextId.max, 0, 1, 0, 0, 0, 1, .max])
        XCTAssertEqual(entitasLogger.compNames, ["Position", "God"])
        XCTAssertEqual(entitasLogger.compNameIds, [CompNameId.max, .max, .max, 0, 0, 0, 1, .max])
        XCTAssertEqual(entitasLogger.systemNames, ["S1"])
        XCTAssertEqual(entitasLogger.systemNameIds, [0, 0, 0, 0, 0, 0, 0, 0])
        XCTAssertEqual(entitasLogger.infos, ["x:1, y:2", "x:2, y:2"])

    }

    func testTickIncrease() {
        entitasLogger.willExecute("S1")
        entitasLogger.didExecute("S1")
        entitasLogger.willExecute("S2")
        entitasLogger.didExecute("S2")
        entitasLogger.willExecute("S3")
        entitasLogger.didExecute("S3")
        entitasLogger.willExecute("S1")
        Thread.sleep(until: Date(timeIntervalSinceNow: 0.01))
        entitasLogger.didExecute("S1")
        entitasLogger.willExecute("S1")
        entitasLogger.didExecute("S1")
        entitasLogger.willExecute("S2")
        Thread.sleep(until: Date(timeIntervalSinceNow: 0.01))
        entitasLogger.didExecute("S2")
        XCTAssertEqual(entitasLogger.systemNames, ["S1", "S2", "S3"])
        XCTAssertEqual(entitasLogger.eventTypes, [EventType.willExec, .didExec, .willExec, .didExec])
        XCTAssertEqual(entitasLogger.systemNameIds, [0, 0, 1, 1])
        XCTAssertEqual(entitasLogger.ticks, [2, 2, 3, 3])
    }

    func testAddInfo() {
        entitasLogger.addInfo("This is an info")
        XCTAssertEqual(entitasLogger.eventTypes, [EventType.info])
        XCTAssertEqual(entitasLogger.infoIds, [0])
        XCTAssertEqual(entitasLogger.infos, ["This is an info"])
    }

    func testAddInfoWithSystems() {
        entitasLogger.willInit("S0")
        entitasLogger.didInit("S0")
        entitasLogger.willExecute("S1")
        entitasLogger.addInfo("Hi")
        entitasLogger.didExecute("S1")
        entitasLogger.addInfo("How are you")

        XCTAssertEqual(entitasLogger.systemNames, ["S0", "S1"])
        XCTAssertEqual(entitasLogger.eventTypes, [EventType.willExec, .info, .didExec, .info])
        XCTAssertEqual(entitasLogger.infos, ["Hi", "How are you"])
        XCTAssertEqual(entitasLogger.infoIds, [.max, 0, .max, 1])
    }
}
