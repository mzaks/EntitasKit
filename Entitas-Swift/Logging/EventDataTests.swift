//
//  EventDataTests.swift
//  EntitasKitTests
//
//  Created by Maxim Zaks on 11.03.18.
//  Copyright © 2018 Maxim Zaks. All rights reserved.
//

import XCTest
@testable import EntitasKit

class EventDataTests: XCTestCase {

    var entitasLogger: EntitasLogger!
    var ctx : Context!
    var ctx2 : Context!

    override func setUp() {
        ctx = Context()
        ctx2 = Context()
        entitasLogger = EntitasLogger(contexts: [(ctx, "mainCtx"), (ctx2, "secondaryCtx")])
    }

    func testEntityAndComponentEventsInSystem() {
        entitasLogger.willExecute("S1")
        let e = ctx.createEntity()
        entitasLogger.didExecute("S1")
        entitasLogger.willExecute("S1")
        e += God()
        e += Position(x: 1, y: 2)
        entitasLogger.didExecute("S1")
        entitasLogger.willCleanup("S2")
        entitasLogger.didCleanup("S2")
        entitasLogger.willExecute("S1")
        e -= God.cid
        e += Position(x: 3, y: 3)
        entitasLogger.didExecute("S1")
        entitasLogger.willCleanup("S2")
        e.destroy()
        entitasLogger.didCleanup("S2")

        do {
            switch entitasLogger.eventData(eventId: 0)! {
            case let .systemEvent(eventTtype, tick, timestampInMs, systemName):
                XCTAssertEqual(eventTtype, .willExec)
                XCTAssertEqual(tick, 1)
                XCTAssert(timestampInMs > 0)
                XCTAssertEqual(systemName, "S1")
            default:
                XCTFail("expected system event")
            }
        }

        do {
            switch entitasLogger.eventData(eventId: 1)! {
            case let .entityEvent(eventTtype, tick, timestampInMs, entityId, contextName, systemName):
                XCTAssertEqual(eventTtype, .created)
                XCTAssertEqual(tick, 1)
                XCTAssert(timestampInMs > 0)
                XCTAssertEqual(entityId, 1)
                XCTAssertEqual(contextName, "mainCtx")
                XCTAssertEqual(systemName, "S1")
            default:
                XCTFail("expected system event")
            }
        }

        do {
            switch entitasLogger.eventData(eventId: 2)! {
            case let .systemEvent(eventTtype, tick, timestampInMs, systemName):
                XCTAssertEqual(eventTtype, .didExec)
                XCTAssertEqual(tick, 1)
                XCTAssert(timestampInMs > 0)
                XCTAssertEqual(systemName, "S1")
            default:
                XCTFail("expected system event")
            }
        }

        do {
            switch entitasLogger.eventData(eventId: 3)! {
            case let .systemEvent(eventTtype, tick, timestampInMs, systemName):
                XCTAssertEqual(eventTtype, .willExec)
                XCTAssertEqual(tick, 2)
                XCTAssert(timestampInMs > 0)
                XCTAssertEqual(systemName, "S1")
            default:
                XCTFail("expected system event")
            }
        }

        do {
            switch entitasLogger.eventData(eventId: 4)! {
            case let .componentEvent(eventTtype, tick, timestampInMs, entityId, contextName, componentName, info, systemName):
                XCTAssertEqual(eventTtype, .added)
                XCTAssertEqual(tick, 2)
                XCTAssert(timestampInMs > 0)
                XCTAssertEqual(entityId, 1)
                XCTAssertEqual(contextName, "mainCtx")
                XCTAssertEqual(componentName, "God")
                XCTAssertNil(info)
                XCTAssertEqual(systemName, "S1")
            default:
                XCTFail("expected system event")
            }
        }

        do {
            switch entitasLogger.eventData(eventId: 5)! {
            case let .componentEvent(eventTtype, tick, timestampInMs, entityId, contextName, componentName, info, systemName):
                XCTAssertEqual(eventTtype, .added)
                XCTAssertEqual(tick, 2)
                XCTAssert(timestampInMs > 0)
                XCTAssertEqual(entityId, 1)
                XCTAssertEqual(contextName, "mainCtx")
                XCTAssertEqual(componentName, "Position")
                XCTAssertEqual(info, "x:1, y:2")
                XCTAssertEqual(systemName, "S1")
            default:
                XCTFail("expected system event")
            }
        }

        do {
            switch entitasLogger.eventData(eventId: 6)! {
            case let .systemEvent(eventTtype, tick, timestampInMs, systemName):
                XCTAssertEqual(eventTtype, .didExec)
                XCTAssertEqual(tick, 2)
                XCTAssert(timestampInMs > 0)
                XCTAssertEqual(systemName, "S1")
            default:
                XCTFail("expected system event")
            }
        }

        do {
            switch entitasLogger.eventData(eventId: 7)! {
            case let .systemEvent(eventTtype, tick, timestampInMs, systemName):
                XCTAssertEqual(eventTtype, .willExec)
                XCTAssertEqual(tick, 3)
                XCTAssert(timestampInMs > 0)
                XCTAssertEqual(systemName, "S1")
            default:
                XCTFail("expected system event")
            }
        }

        do {
            switch entitasLogger.eventData(eventId: 8)! {
            case let .componentEvent(eventTtype, tick, timestampInMs, entityId, contextName, componentName, info, systemName):
                XCTAssertEqual(eventTtype, .removed)
                XCTAssertEqual(tick, 3)
                XCTAssert(timestampInMs > 0)
                XCTAssertEqual(entityId, 1)
                XCTAssertEqual(contextName, "mainCtx")
                XCTAssertEqual(componentName, "God")
                XCTAssertNil(info)
                XCTAssertEqual(systemName, "S1")
            default:
                XCTFail("expected system event")
            }
        }

        do {
            switch entitasLogger.eventData(eventId: 9)! {
            case let .componentEvent(eventTtype, tick, timestampInMs, entityId, contextName, componentName, info, systemName):
                XCTAssertEqual(eventTtype, .replaced)
                XCTAssertEqual(tick, 3)
                XCTAssert(timestampInMs > 0)
                XCTAssertEqual(entityId, 1)
                XCTAssertEqual(contextName, "mainCtx")
                XCTAssertEqual(componentName, "Position")
                XCTAssertEqual(info, "x:3, y:3")
                XCTAssertEqual(systemName, "S1")
            default:
                XCTFail("expected system event")
            }
        }

        do {
            switch entitasLogger.eventData(eventId: 10)! {
            case let .systemEvent(eventTtype, tick, timestampInMs, systemName):
                XCTAssertEqual(eventTtype, .didExec)
                XCTAssertEqual(tick, 3)
                XCTAssert(timestampInMs > 0)
                XCTAssertEqual(systemName, "S1")
            default:
                XCTFail("expected system event")
            }
        }

        do {
            switch entitasLogger.eventData(eventId: 11)! {
            case let .systemEvent(eventTtype, tick, timestampInMs, systemName):
                XCTAssertEqual(eventTtype, .willCleanup)
                XCTAssertEqual(tick, 3)
                XCTAssert(timestampInMs > 0)
                XCTAssertEqual(systemName, "S2")
            default:
                XCTFail("expected system event")
            }
        }

        do {
            switch entitasLogger.eventData(eventId: 12)! {
            case let .componentEvent(eventTtype, tick, timestampInMs, entityId, contextName, componentName, info, systemName):
                XCTAssertEqual(eventTtype, .removed)
                XCTAssertEqual(tick, 3)
                XCTAssert(timestampInMs > 0)
                XCTAssertEqual(entityId, 1)
                XCTAssertEqual(contextName, "mainCtx")
                XCTAssertEqual(componentName, "Position")
                XCTAssertNil(info)
                XCTAssertEqual(systemName, "S2")
            default:
                XCTFail("expected system event")
            }
        }

        do {
            switch entitasLogger.eventData(eventId: 13)! {
            case let .entityEvent(eventTtype, tick, timestampInMs, entityId, contextName, systemName):
                XCTAssertEqual(eventTtype, .destroyed)
                XCTAssertEqual(tick, 3)
                XCTAssert(timestampInMs > 0)
                XCTAssertEqual(entityId, 1)
                XCTAssertEqual(contextName, "mainCtx")
                XCTAssertEqual(systemName, "S2")
            default:
                XCTFail("expected system event")
            }
        }

        do {
            switch entitasLogger.eventData(eventId: 14)! {
            case let .systemEvent(eventTtype, tick, timestampInMs, systemName):
                XCTAssertEqual(eventTtype, .didCleanup)
                XCTAssertEqual(tick, 3)
                XCTAssert(timestampInMs > 0)
                XCTAssertEqual(systemName, "S2")
            default:
                XCTFail("expected system event")
            }
        }
    }

    func testInfoInSystemAndOutside() {
        entitasLogger.willInit("S1")
        entitasLogger.willInit("S2")
        entitasLogger.addInfo("Bla")
        entitasLogger.didInit("S2")
        entitasLogger.addError("Foo")
        entitasLogger.didInit("S1")
        entitasLogger.addInfo("Bla 22")
        entitasLogger.addError("Foo 22")

        do {
            switch entitasLogger.eventData(eventId: 0)! {
            case let .systemEvent(eventTtype, tick, timestampInMs, systemName):
                XCTAssertEqual(eventTtype, .willInit)
                XCTAssertEqual(tick, 0)
                XCTAssert(timestampInMs > 0)
                XCTAssertEqual(systemName, "S1")
            default:
                XCTFail("expected system event")
            }
        }

        do {
            switch entitasLogger.eventData(eventId: 1)! {
            case let .systemEvent(eventTtype, tick, timestampInMs, systemName):
                XCTAssertEqual(eventTtype, .willInit)
                XCTAssertEqual(tick, 0)
                XCTAssert(timestampInMs > 0)
                XCTAssertEqual(systemName, "S2")
            default:
                XCTFail("expected system event")
            }
        }

        do {
            switch entitasLogger.eventData(eventId: 2)! {
            case let .infoEvent(eventTtype, tick, timestampInMs, systemName, info):
                XCTAssertEqual(eventTtype, .info)
                XCTAssertEqual(tick, 0)
                XCTAssert(timestampInMs > 0)
                XCTAssertEqual(systemName, "S2")
                XCTAssertEqual(info, "Bla")
            default:
                XCTFail("expected system event")
            }
        }

        do {
            switch entitasLogger.eventData(eventId: 3)! {
            case let .systemEvent(eventTtype, tick, timestampInMs, systemName):
                XCTAssertEqual(eventTtype, .didInit)
                XCTAssertEqual(tick, 0)
                XCTAssert(timestampInMs > 0)
                XCTAssertEqual(systemName, "S2")
            default:
                XCTFail("expected system event")
            }
        }

        do {
            switch entitasLogger.eventData(eventId: 4)! {
            case let .infoEvent(eventTtype, tick, timestampInMs, systemName, info):
                XCTAssertEqual(eventTtype, .error)
                XCTAssertEqual(tick, 0)
                XCTAssert(timestampInMs > 0)
                XCTAssertEqual(systemName, "S1")
                XCTAssertEqual(info, "Foo")
            default:
                XCTFail("expected system event")
            }
        }

        do {
            switch entitasLogger.eventData(eventId: 5)! {
            case let .systemEvent(eventTtype, tick, timestampInMs, systemName):
                XCTAssertEqual(eventTtype, .didInit)
                XCTAssertEqual(tick, 0)
                XCTAssert(timestampInMs > 0)
                XCTAssertEqual(systemName, "S1")
            default:
                XCTFail("expected system event")
            }
        }

        do {
            switch entitasLogger.eventData(eventId: 6)! {
            case let .infoEvent(eventTtype, tick, timestampInMs, systemName, info):
                XCTAssertEqual(eventTtype, .info)
                XCTAssertEqual(tick, 0)
                XCTAssert(timestampInMs > 0)
                XCTAssertEqual(systemName, nil)
                XCTAssertEqual(info, "Bla 22")
            default:
                XCTFail("expected system event")
            }
        }

        do {
            switch entitasLogger.eventData(eventId: 7)! {
            case let .infoEvent(eventTtype, tick, timestampInMs, systemName, info):
                XCTAssertEqual(eventTtype, .error)
                XCTAssertEqual(tick, 0)
                XCTAssert(timestampInMs > 0)
                XCTAssertEqual(systemName, nil)
                XCTAssertEqual(info, "Foo 22")
            default:
                XCTFail("expected system event")
            }
        }
    }

    func testEntitAndComponentEventsNotInSystem() {
        let e = ctx.createEntity()
        e += God()
        e.destroy()
        let e1 = ctx2.createEntity()
        e1 += Position(x: 1, y: 1)
        e1 += Position(x: 2, y: 2)

        do {
            switch entitasLogger.eventData(eventId: 0)! {
            case let .entityEvent(eventTtype, tick, timestampInMs, entityId, contextName, systemName):
                XCTAssertEqual(eventTtype, .created)
                XCTAssertEqual(tick, 0)
                XCTAssert(timestampInMs > 0)
                XCTAssertEqual(entityId, 1)
                XCTAssertEqual(contextName, "mainCtx")
                XCTAssertEqual(systemName, nil)
            default:
                XCTFail("expected system event")
            }
        }

        do {
            switch entitasLogger.eventData(eventId: 1)! {
            case let .componentEvent(eventTtype, tick, timestampInMs, entityId, contextName, componentName, info, systemName):
                XCTAssertEqual(eventTtype, .added)
                XCTAssertEqual(tick, 0)
                XCTAssert(timestampInMs > 0)
                XCTAssertEqual(entityId, 1)
                XCTAssertEqual(contextName, "mainCtx")
                XCTAssertEqual(componentName, "God")
                XCTAssertNil(info)
                XCTAssertEqual(systemName, nil)
            default:
                XCTFail("expected system event")
            }
        }

        do {
            switch entitasLogger.eventData(eventId: 2)! {
            case let .componentEvent(eventTtype, tick, timestampInMs, entityId, contextName, componentName, info, systemName):
                XCTAssertEqual(eventTtype, .removed)
                XCTAssertEqual(tick, 0)
                XCTAssert(timestampInMs > 0)
                XCTAssertEqual(entityId, 1)
                XCTAssertEqual(contextName, "mainCtx")
                XCTAssertEqual(componentName, "God")
                XCTAssertNil(info)
                XCTAssertEqual(systemName, nil)
            default:
                XCTFail("expected system event")
            }
        }

        do {
            switch entitasLogger.eventData(eventId: 3)! {
            case let .entityEvent(eventTtype, tick, timestampInMs, entityId, contextName, systemName):
                XCTAssertEqual(eventTtype, .destroyed)
                XCTAssertEqual(tick, 0)
                XCTAssert(timestampInMs > 0)
                XCTAssertEqual(entityId, 1)
                XCTAssertEqual(contextName, "mainCtx")
                XCTAssertEqual(systemName, nil)
            default:
                XCTFail("expected system event")
            }
        }

        do {
            switch entitasLogger.eventData(eventId: 4)! {
            case let .entityEvent(eventTtype, tick, timestampInMs, entityId, contextName, systemName):
                XCTAssertEqual(eventTtype, .created)
                XCTAssertEqual(tick, 0)
                XCTAssert(timestampInMs > 0)
                XCTAssertEqual(entityId, 1)
                XCTAssertEqual(contextName, "secondaryCtx")
                XCTAssertEqual(systemName, nil)
            default:
                XCTFail("expected system event")
            }
        }

        do {
            switch entitasLogger.eventData(eventId: 5)! {
            case let .componentEvent(eventTtype, tick, timestampInMs, entityId, contextName, componentName, info, systemName):
                XCTAssertEqual(eventTtype, .added)
                XCTAssertEqual(tick, 0)
                XCTAssert(timestampInMs > 0)
                XCTAssertEqual(entityId, 1)
                XCTAssertEqual(contextName, "secondaryCtx")
                XCTAssertEqual(componentName, "Position")
                XCTAssertEqual(info, "x:1, y:1")
                XCTAssertEqual(systemName, nil)
            default:
                XCTFail("expected system event")
            }
        }

        do {
            switch entitasLogger.eventData(eventId: 6)! {
            case let .componentEvent(eventTtype, tick, timestampInMs, entityId, contextName, componentName, info, systemName):
                XCTAssertEqual(eventTtype, .replaced)
                XCTAssertEqual(tick, 0)
                XCTAssert(timestampInMs > 0)
                XCTAssertEqual(entityId, 1)
                XCTAssertEqual(contextName, "secondaryCtx")
                XCTAssertEqual(componentName, "Position")
                XCTAssertEqual(info, "x:2, y:2")
                XCTAssertEqual(systemName, nil)
            default:
                XCTFail("expected system event")
            }
        }
    }
}
