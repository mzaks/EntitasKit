//
//  LoggerMatcher.swift
//  EntitasKit
//
//  Created by Maxim Zaks on 06.03.18.
//  Copyright © 2018 Maxim Zaks. All rights reserved.
//

import Foundation

protocol LoggerMatcher {
    func match(index: Int) -> Bool
}

struct TickMatcher: LoggerMatcher {
    let logger: EntitasLogger
    let min: Tick
    let max: Tick

    func match(index: Int) -> Bool {
        let tick = logger.ticks[index]
        return tick >= min && tick <= max
    }
}

struct EventTypeMatcher: LoggerMatcher {
    let logger: EntitasLogger
    let type: EventType

    func match(index: Int) -> Bool {
        return logger.eventTypes[index] == type
    }
}

struct EventIndexMatcher: LoggerMatcher {
    let logger: EntitasLogger
    let min: Int
    let max: Int

    func match(index: Int) -> Bool {
        return index <= max && index >= min
    }
}

struct ContextNameMatcher: LoggerMatcher {
    let logger: EntitasLogger
    let contextId: ContextId

    func match(index: Int) -> Bool {
        return logger.contextIds[index] == contextId
    }
}

struct EntityIdMatcher: LoggerMatcher {
    let logger: EntitasLogger
    let entityId: EntityId

    func match(index: Int) -> Bool {
        return logger.entityIds[index] == entityId
    }
}

struct ComponentNameIdMatcher: LoggerMatcher {
    let logger: EntitasLogger
    let compId: CompNameId

    func match(index: Int) -> Bool {
        return logger.compNameIds[index] == compId
    }
}

struct SystemNameIdMatcher: LoggerMatcher {
    let logger: EntitasLogger
    let sysId: SystemNameId

    func match(index: Int) -> Bool {
        return logger.systemNameIds[index] == sysId
    }
}

struct InfoMatcher: LoggerMatcher {
    let logger: EntitasLogger
    let info: String

    func match(index: Int) -> Bool {
        let id = Int(logger.infoIds[index])
        guard logger.infos.count > id else { return false }
        return logger.infos[id].contains(info)
    }
}

struct GroupMatcher: LoggerMatcher {
    let all: [LoggerMatcher]
    let any: [LoggerMatcher]
    let none: [LoggerMatcher]

    func match(index: Int) -> Bool {
        for matcher in all {
            if matcher.match(index: index) == false {
                return false
            }
        }
        for matcher in none {
            if matcher.match(index: index) {
                return false
            }
        }
        if any.isEmpty {
            return true
        }

        for matcher in any {
            if matcher.match(index: index) {
                return true
            }
        }

        return false
    }
}
