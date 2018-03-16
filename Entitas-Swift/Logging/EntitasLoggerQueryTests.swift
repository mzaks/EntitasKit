//
//  EntitasLoggerQueryTests.swift
//  EntitasKit
//
//  Created by Maxim Zaks on 07.03.18.
//  Copyright © 2018 Maxim Zaks. All rights reserved.
//

import XCTest
@testable import EntitasKit

class EntitasLoggerQueryTests: XCTestCase {

    var entitasLogger: EntitasLogger!
    var ctx : Context!
    var ctx2 : Context!

    override func setUp() {
        ctx = Context()
        ctx2 = Context()
        entitasLogger = EntitasLogger(contexts: [(ctx, "mainCtx"), (ctx2, "secondaryCtx")])
        entitasLogger.willExecute("S1")
        entitasLogger.willExecute("S2")
        _ = ctx.createEntity()
        entitasLogger.didExecute("S2")
        entitasLogger.didExecute("S1")
        entitasLogger.willExecute("S3")
        entitasLogger.didExecute("S3")
    }

    func testSystemsWithoutMatcher() {
        let result = entitasLogger.systems(matcher: nil)
        XCTAssertEqual(result, ["S1", "S2", "S3"])
    }

    func testSystemsWithWillExecEventType() {
        let matcher = EventTypeMatcher(logger: entitasLogger, type: .willExec)
        let result = entitasLogger.systems(matcher: GroupMatcher(all: [matcher], any: [], none: []))
        XCTAssertEqual(result, ["S1", "S2"])
    }

    func testSystemsWithWillExecEventTypeAndNotS2() {
        let matcher = EventTypeMatcher(logger: entitasLogger, type: .willExec)
        let matcher2 = SystemNameIdMatcher(logger: entitasLogger, sysId: 1)
        do {
            let result = entitasLogger.systems(matcher: GroupMatcher(all: [matcher, matcher2], any: [], none: []))
            XCTAssertEqual(result, ["S2"])
        }
        do {
            let result = entitasLogger.systems(matcher: GroupMatcher(all: [matcher], any: [matcher2], none: []))
            XCTAssertEqual(result, ["S2"])
        }
        do {
            let result = entitasLogger.systems(matcher: GroupMatcher(all: [], any: [matcher, matcher2], none: []))
            XCTAssertEqual(result, ["S1", "S2"])
        }
        do {
            let result = entitasLogger.systems(matcher: GroupMatcher(all: [matcher], any: [], none: [matcher2]))
            XCTAssertEqual(result, ["S1"])
        }
    }

    func testSystemsWithEntityId() {
        entitasLogger.willExecute("S3")
        _ = ctx.createEntity()
        entitasLogger.didExecute("S3")
        do {
            let matcher = EntityIdMatcher(logger: entitasLogger, entityId: 1)
            let result = entitasLogger.systems(matcher: GroupMatcher(all: [matcher], any: [], none: []))
            XCTAssertEqual(result, ["S2"])
        }
        do {
            let matcher = EntityIdMatcher(logger: entitasLogger, entityId: .max)
            let result = entitasLogger.systems(matcher: GroupMatcher(all: [matcher], any: [], none: []))
            XCTAssertEqual(result, ["S1", "S2", "S3"])
        }
    }

    func testComponents() {
        let e = ctx.createEntity()
        e += God()
        XCTAssertEqual(entitasLogger.components(matcher: nil), ["God"])
    }

    func testComponentsWithMatcher() {
        let e = ctx.createEntity()
        e += God()
        e.destroy()
        let matcher = EntityIdMatcher(logger: entitasLogger, entityId: .max)

        XCTAssertEqual(entitasLogger.components(matcher: GroupMatcher(all: [matcher], any: [], none: [])), [])

        XCTAssertEqual(entitasLogger.components(matcher: GroupMatcher(all: [], any: [], none: [matcher])), ["God"])
    }

    func testEvents() {
        let e = ctx.createEntity()
        e += God()
        e.destroy()
        let matcher = EntityIdMatcher(logger: entitasLogger, entityId: .max)

        XCTAssertEqual(entitasLogger.events(matcher: GroupMatcher(all: [matcher], any: [], none: [])), [0, 1, 3, 4])

        XCTAssertEqual(entitasLogger.events(matcher: GroupMatcher(all: [], any: [], none: [matcher])), [2, 5, 6, 7, 8])
    }

    func testSimpleSystemQuery() throws {
        let result = try entitasLogger.query(" systems ")
        XCTAssertEqual(result, QueryResult.names(["S1", "S2", "S3"]))
    }

    func testSystemQuery() throws {
        XCTAssertEqual(
            try entitasLogger.query("systems where all(system:S1)"),
            QueryResult.names(["S1"])
        )
        XCTAssertEqual(
            try entitasLogger.query("systems where all(system:S2)"),
            QueryResult.names(["S2"])
        )
        XCTAssertEqual(
            try entitasLogger.query("systems where all(system:S1 system:S2)"),
            QueryResult.names([])
        )
        XCTAssertEqual(
            try entitasLogger.query("systems where any(system:S1 system:S2)"),
            QueryResult.names(["S1", "S2"])
        )
        XCTAssertEqual(
            try entitasLogger.query("systems where any(system:S1 system:S2) none(system:S1)"),
            QueryResult.names(["S2"])
        )
        XCTAssertEqual(
            try entitasLogger.query("systems where all(component:-)"),
            QueryResult.names(["S1", "S2"])
        )
        XCTAssertThrowsError(try entitasLogger.query("systems where all(system:S4)"))
    }

    func testSystemEventType() {
        entitasLogger.willInit("S1")
        let e1 = ctx.createEntity()
        entitasLogger.didInit("S1")
        entitasLogger.willCleanup("S2")
        let e2 = ctx2.createEntity()
        entitasLogger.didCleanup("S2")
        entitasLogger.willTeardown("S5")
        e1.destroy()
        e2.destroy()
        entitasLogger.addInfo("Done")
        entitasLogger.didTeardown("S5")
        entitasLogger.addError("Boom")

        XCTAssertEqual(
            try entitasLogger.query("systems where all(willExec)"),
            QueryResult.names(["S1", "S2"])
        )
        XCTAssertEqual(
            try entitasLogger.query("systems where all(didExec)"),
            QueryResult.names(["S1", "S2"])
        )
        XCTAssertEqual(
            try entitasLogger.query("systems where all(willInit)"),
            QueryResult.names(["S1"])
        )
        XCTAssertEqual(
            try entitasLogger.query("systems where all(didInit)"),
            QueryResult.names(["S1"])
        )
        XCTAssertEqual(
            try entitasLogger.query("systems where all(willCleanup)"),
            QueryResult.names(["S2"])
        )
        XCTAssertEqual(
            try entitasLogger.query("systems where all(didCleanup)"),
            QueryResult.names(["S2"])
        )
        XCTAssertEqual(
            try entitasLogger.query("systems where all(willTeardown)"),
            QueryResult.names(["S5"])
        )
        XCTAssertEqual(
            try entitasLogger.query("systems where all(didTeardown)"),
            QueryResult.names(["S5"])
        )
        XCTAssertEqual(
            try entitasLogger.query("systems where all(destroyed)"),
            QueryResult.names(["S5"])
        )
        XCTAssertEqual(
            try entitasLogger.query("systems where all(created)"),
            QueryResult.names(["S1", "S2"])
        )
        XCTAssertEqual(
            try entitasLogger.query("systems where all(infoLog)"),
            QueryResult.names(["S5"])
        )
    }

    func testSimpleComponentsQuery() throws {
        let e = ctx.createEntity()
        e += God()
        e += Position(x: 2, y: 4)
        e.destroy()
        let result = try entitasLogger.query(" components ")
        XCTAssertEqual(result, QueryResult.names(["God", "Position"]))
    }

    func testComponentQuery() throws {
        let e = ctx.createEntity()
        e += God()
        entitasLogger.willExecute("S1")
        e += Position(x: 2, y: 4)
        e += Position(x: 2, y: 2)
        entitasLogger.didExecute("S1")
        entitasLogger.willExecute("S2")
        e.destroy()
        entitasLogger.didExecute("S2")
        XCTAssertEqual(
            try entitasLogger.query("components where all(system:S1)"),
            QueryResult.names(["Position"])
        )
        XCTAssertEqual(
            try entitasLogger.query("components where all(system:-)"),
            QueryResult.names(["God"])
        )
        XCTAssertEqual(
            try entitasLogger.query("components where all(component:God)"),
            QueryResult.names(["God"])
        )
        XCTAssertEqual(
            try entitasLogger.query("components where none(system:S1 system:S2)"),
            QueryResult.names(["God"])
        )
        XCTAssertEqual(
            try entitasLogger.query("components where all(component:-)"),
            QueryResult.names([])
        )
        XCTAssertEqual(
            try entitasLogger.query("components where all(context:mainCtx)"),
            QueryResult.names(["God", "Position"])
        )
        XCTAssertEqual(
            try entitasLogger.query("components where all(context:secondaryCtx)"),
            QueryResult.names([])
        )
        XCTAssertEqual(
            try entitasLogger.query("components where all(removed)"),
            QueryResult.names(["God", "Position"])
        )
        XCTAssertEqual(
            try entitasLogger.query("components where all(added)"),
            QueryResult.names(["God", "Position"])
        )
        XCTAssertEqual(
            try entitasLogger.query("components where all(replaced)"),
            QueryResult.names(["Position"])
        )
        XCTAssertEqual(
            try entitasLogger.query("components where all(info: \"x:2\" )"),
            QueryResult.names(["Position"])
        )
        XCTAssertEqual(
            try entitasLogger.query("components where all(info: \"x:3\" )"),
            QueryResult.names([])
        )
    }

    func testEntityMatcher() {
        entitasLogger.willExecute("S1")
        _ = ctx.createEntity()
        entitasLogger.didExecute("S1")
        entitasLogger.willExecute("S2")
        _ = ctx.createEntity()
        entitasLogger.didExecute("S2")
        entitasLogger.willExecute("S3")
        _ = ctx2.createEntity()
        entitasLogger.didExecute("S3")

        XCTAssertEqual(
            try entitasLogger.query("systems where all(entity:1)"),
            QueryResult.names(["S2", "S3"])
        )
        XCTAssertEqual(
            try entitasLogger.query("systems where all(entity:1 context:mainCtx)"),
            QueryResult.names(["S2"])
        )
        XCTAssertEqual(
            try entitasLogger.query("systems where all(entity:1 context:secondaryCtx)"),
            QueryResult.names(["S3"])
        )
        XCTAssertEqual(
            try entitasLogger.query("systems where all(entity:2)"),
            QueryResult.names(["S1"])
        )
        XCTAssertEqual(
            try entitasLogger.query("systems where all(entity:3)"),
            QueryResult.names(["S2"])
        )
        XCTAssertEqual(
            try entitasLogger.query("systems where all(entity:4)"),
            QueryResult.names([])
        )
    }

    func testEventIndexMatcher() {
        XCTAssertEqual(
            try entitasLogger.query("systems where all(willExec event:1)"),
            QueryResult.names(["S2"])
        )
        XCTAssertEqual(
            try entitasLogger.query("systems where all(willExec event:1..)"),
            QueryResult.names(["S2"])
        )
        XCTAssertEqual(
            try entitasLogger.query("systems where all(event:1.. willExec)"),
            QueryResult.names(["S2"])
        )
        XCTAssertEqual(
            try entitasLogger.query("systems where all(willExec event:..25)"),
            QueryResult.names(["S1", "S2"])
        )
        XCTAssertEqual(
            try entitasLogger.query("systems where all(didExec event:3..25)"),
            QueryResult.names(["S1", "S2"])
        )
    }

    func testTickMatcher() {
        entitasLogger.willExecute("S1")
        _ = ctx.createEntity()
        entitasLogger.didExecute("S1")

        XCTAssertEqual(
            try entitasLogger.query("systems where all(willExec tick:1)"),
            QueryResult.names(["S1", "S2"])
        )
        XCTAssertEqual(
            try entitasLogger.query("systems where all(willExec tick:..10)"),
            QueryResult.names(["S1", "S2"])
        )
        XCTAssertEqual(
            try entitasLogger.query("systems where all(willExec tick:0)"),
            QueryResult.names([])
        )
        XCTAssertEqual(
            try entitasLogger.query("systems where all(willExec tick:0..)"),
            QueryResult.names(["S1", "S2"])
        )
        XCTAssertEqual(
            try entitasLogger.query("systems where all(willExec tick:2)"),
            QueryResult.names(["S1"])
        )
        XCTAssertEqual(
            try entitasLogger.query("systems where all(willExec tick:3..12)"),
            QueryResult.names([])
        )
    }

    func testEventsQuery() {
        XCTAssertEqual(
            try entitasLogger.query("events"),
            QueryResult.eventIds([0, 1, 2, 3, 4])
        )
        XCTAssertEqual(
            try entitasLogger.query("events where all(willExec)"),
            QueryResult.eventIds([0, 1])
        )
        XCTAssertEqual(
            try entitasLogger.query("events where any(willExec didExec)"),
            QueryResult.eventIds([0, 1, 3, 4])
        )
        XCTAssertEqual(
            try entitasLogger.query("events where any(system:S1)"),
            QueryResult.eventIds([0, 4])
        )
        XCTAssertEqual(
            try entitasLogger.query("events where any(system:S2)"),
            QueryResult.eventIds([1, 2, 3])
        )
        XCTAssertEqual(
            try entitasLogger.query("events where any(system:-)"),
            QueryResult.eventIds([])
        )
    }

    func testDurations() throws {
        do {
            let result = try entitasLogger.query("durations")
            switch result {
            case let .durations(durations):
                XCTAssertEqual(durations.count, 2)
                let willEvents = durations.map{$0.1}
                let didEvents = durations.map{$0.2}
                XCTAssertEqual(willEvents,[EventId(1), EventId(0)])
                XCTAssertEqual(didEvents, [EventId(3), EventId(4)])
            default:
                XCTFail("Expected a duration")
            }
        }
        do {
            let result = try entitasLogger.query("durations where all(system:S1)")
            switch result {
            case let .durations(durations):
                XCTAssertEqual(durations.count, 1)
                let willEvents = durations.map{$0.1}
                let didEvents = durations.map{$0.2}
                XCTAssertEqual(willEvents,[EventId(0)])
                XCTAssertEqual(didEvents, [EventId(4)])
            default:
                XCTFail("Expected a duration")
            }
        }
    }

    func testEntitiesQuery() throws {
        let e1 = ctx.createEntity()
        let e2 = ctx2.createEntity()
        e1.destroy()
        e2 += God()

        switch try entitasLogger.query("entities") {
        case .entities(let results):
            XCTAssertEqual(results.count, 3)
            XCTAssertEqual(results.map{$0.entityId}, [EntityId(1), 2, 1])
            XCTAssertEqual(results.map{$0.contextId}, [ContextId(0), 0, 1])
            XCTAssertEqual(results.map{$0.eventsCount}, [1, 2, 2])
            XCTAssertEqual(results.map{$0.lifeSpan.0}, [0.25, 0.625, 0.75])
            XCTAssertEqual(results.map{$0.lifeSpan.1}, [1.0, 0.875, 1.0])
        default:
            XCTFail()
        }

        switch try entitasLogger.query("entities where all(system:S1)") {
        case .entities(let results):
            XCTAssertEqual(results.count, 0)
        default:
            XCTFail()
        }

        switch try entitasLogger.query("entities where all(system:S2)") {
        case .entities(let results):
            XCTAssertEqual(results.count, 1)
            XCTAssertEqual(results.map{$0.entityId}, [EntityId(1)])
            XCTAssertEqual(results.map{$0.contextId}, [ContextId(0)])
            XCTAssertEqual(results.map{$0.eventsCount}, [1])
            XCTAssertEqual(results.map{$0.lifeSpan.0}, [0.25])
            XCTAssertEqual(results.map{$0.lifeSpan.1}, [1.0])
        default:
            XCTFail()
        }

        switch try entitasLogger.query("entities where all(destroyed)") {
        case .entities(let results):
            XCTAssertEqual(results.count, 1)
            XCTAssertEqual(results.map{$0.entityId}, [EntityId(2)])
            XCTAssertEqual(results.map{$0.contextId}, [ContextId(0)])
            XCTAssertEqual(results.map{$0.eventsCount}, [1])
            XCTAssertEqual(results.map{$0.lifeSpan.0}, [0.625])
            XCTAssertEqual(results.map{$0.lifeSpan.1}, [0.875])
        default:
            XCTFail()
        }

        switch try entitasLogger.query("entities where all(added)") {
        case .entities(let results):
            XCTAssertEqual(results.count, 1)
            XCTAssertEqual(results.map{$0.entityId}, [EntityId(1)])
            XCTAssertEqual(results.map{$0.contextId}, [ContextId(1)])
            XCTAssertEqual(results.map{$0.eventsCount}, [1])
            XCTAssertEqual(results.map{$0.lifeSpan.0}, [0.75])
            XCTAssertEqual(results.map{$0.lifeSpan.1}, [1.0])
        default:
            XCTFail()
        }

        switch try entitasLogger.query("entities where all(component:God)") {
        case .entities(let results):
            XCTAssertEqual(results.count, 1)
            XCTAssertEqual(results.map{$0.entityId}, [EntityId(1)])
            XCTAssertEqual(results.map{$0.contextId}, [ContextId(1)])
            XCTAssertEqual(results.map{$0.eventsCount}, [1])
            XCTAssertEqual(results.map{$0.lifeSpan.0}, [0.75])
            XCTAssertEqual(results.map{$0.lifeSpan.1}, [1.0])
        default:
            XCTFail()
        }

//        XCTAssertEqual(
//            try entitasLogger.query("entities"),
//            QueryResult.entities([_e0, _e1, _e2])
//        )
//        XCTAssertEqual(
//            try entitasLogger.query("entities where all(system:S1)"),
//            QueryResult.entities([
//            ])
//        )
//        XCTAssertEqual(
//            try entitasLogger.query("entities where all(system:S2)"),
//            QueryResult.entities([(EntityId(1), ContextId(0))])
//        )
//
//        XCTAssertEqual(
//            try entitasLogger.query("entities where all(destroyed)"),
//            QueryResult.entities([_e1])
//        )
//        XCTAssertEqual(
//            try entitasLogger.query("entities where all(added)"),
//            QueryResult.entities([_e2])
//        )
//        XCTAssertEqual(
//            try entitasLogger.query("entities where all(component:God)"),
//            QueryResult.entities([_e2])
//        )
    }

    func testInfoAndErrorEvents() throws {
        entitasLogger.addInfo("Bla")
        entitasLogger.addError("Bla")
        XCTAssertEqual(
            try entitasLogger.query("events"),
            QueryResult.eventIds([0, 1, 2, 3, 4, 5, 6])
        )
        XCTAssertEqual(
            try entitasLogger.query("events where all(infoLog)"),
            QueryResult.eventIds([5])
        )
        XCTAssertEqual(
            try entitasLogger.query("events where all(errorLog)"),
            QueryResult.eventIds([6])
        )

        XCTAssertEqual(
            try entitasLogger.query("events where any(infoLog errorLog)"),
            QueryResult.eventIds([5, 6])
        )
    }

    func testContextName() {
        XCTAssertEqual(entitasLogger.contextName(id: 0), "mainCtx")
        XCTAssertEqual(entitasLogger.contextName(id: 1), "secondaryCtx")
    }

    func testBadQuery() throws {
        XCTAssertThrowsError(try entitasLogger.query(" compo "))
    }
}
