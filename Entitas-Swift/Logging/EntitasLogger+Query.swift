//
//  EntitasLogger+Query.swift
//  EntitasKit
//
//  Created by Maxim Zaks on 07.03.18.
//  Copyright © 2018 Maxim Zaks. All rights reserved.
//

import Foundation

struct EntityContextTuple: Hashable, Comparable {
    let entityId: EntityId
    let contextId: ContextId

    var hashValue: Int {
        return Int(contextId) * 1000000 + Int(entityId)
    }

    public static func ==(lhs: EntityContextTuple, rhs: EntityContextTuple) -> Bool {
        return lhs.contextId == rhs.contextId && lhs.entityId == rhs.entityId
    }

    static func <(lhs: EntityContextTuple, rhs: EntityContextTuple) -> Bool {
        if lhs.contextId == rhs.contextId {
            return lhs.entityId < rhs.entityId
        }
        return lhs.contextId < rhs.contextId
    }
}

public enum QueryResult: Equatable {
    case names([String])
    case eventIds([EventId])
    case durations([(durationInMs: TimeInterval, willEvent: EventId, didEvent:EventId)])
    case entities([(lifeSpan: (Double, Double), eventsCount: Int, entityId: EntityId, contextId: ContextId)])

    public static func ==(lhs: QueryResult, rhs: QueryResult) -> Bool {
        switch (lhs, rhs) {
        case let(.names(n1), .names(n2)):
            return n1 == n2
        case let(.eventIds(ids1), .eventIds(ids2)):
            return ids1 == ids2
        case let(.durations(triples1), .durations(triples2)):
            guard triples1.count == triples2.count else { return false }
            for i in 0..<triples1.count {
                guard triples1[i].durationInMs == triples2[i].durationInMs
                    && triples1[i].willEvent == triples2[i].willEvent
                    && triples1[i].didEvent == triples2[i].didEvent else {
                    return false
                }
            }
            return true
        case let(.entities(tupple1), .entities(tupple2)):
            guard tupple1.count == tupple2.count else { return false }
            for i in 0..<tupple1.count {
                guard tupple1[i].entityId == tupple2[i].entityId
                    && tupple1[i].contextId == tupple2[i].contextId else {
                    return false
                }
            }
            return true
        default:
            return false
        }
    }
}

public enum EventData {
    case systemEvent(eventTtype: EventType, tick: Int, timestampInMs: TimeInterval, systemName: String)
    case entityEvent(eventTtype: EventType, tick: Int, timestampInMs: TimeInterval, entityId: Int, contextName: String, systemName: String?)
    case componentEvent(eventTtype: EventType, tick: Int, timestampInMs: TimeInterval, entityId: Int, contextName: String, componentName: String, info: String?, systemName: String?)
    case infoEvent(eventType: EventType, tick: Int, timestampInMs: TimeInterval, systemName: String?, info: String)
}

let willEvents: Set<EventType> = [
    EventType.willExec, .willInit, .willCleanup, .willTeardown
]
let durationRelevantEvents: Set<EventType> = [
    EventType.willExec, .willInit, .willCleanup, .willTeardown,
    .didExec, .didInit, .didCleanup, .didTeardown
]

extension EntitasLogger {
    func systems(matcher: GroupMatcher?) -> [String] {
        guard let matcher = matcher else {
            return systemNames
        }
        var indexies: Set<SystemNameId> = []
        for i in 0..<systemNameIds.count {
            if matcher.match(index: i) {
                indexies.insert(systemNameIds[i])
                if indexies.count == systemNames.count {
                    break
                }
            }
        }
        var result = [String]()
        for i in indexies.sorted() where i < systemNames.count {
            result.append(systemNames[Int(i)])
        }
        return result
    }

    func components(matcher: GroupMatcher?) -> [String] {
        guard let matcher = matcher else {
            return compNames
        }
        var indexies: Set<CompNameId> = []
        for i in 0..<compNameIds.count {
            if matcher.match(index: i) {
                indexies.insert(compNameIds[i])
                if indexies.count == compNameIds.count {
                    break
                }
            }
        }
        var result = [String]()
        for i in indexies.sorted() where i < compNames.count {
            result.append(compNames[Int(i)])
        }
        return result
    }

    func events(matcher: GroupMatcher?) -> [EventId] {
        guard let matcher = matcher else {
            return (0..<eventTypes.count).map{ EventId($0) }
        }
        var result = [EventId]()
        for i in 0..<eventTypes.count {
            if matcher.match(index: i) {
                result.append(EventId(i))
            }
        }
        return result
    }

    func entities(matcher: GroupMatcher?) -> [((Double, Double), Int, EntityId, ContextId)] {
        var entityEvents = [EntityContextTuple: Int]()
        var entityCreation = [EntityContextTuple: Double]()
        var entityDestruction = [EntityContextTuple: Double]()

        for i in 0..<eventTypes.count where entityIds[i] < .max {
            let key = EntityContextTuple(entityId: entityIds[i], contextId: contextIds[i])
            if eventTypes[i] == .created {
                entityCreation[key] = Double(i)
            } else if eventTypes[i] == .destroyed {
                entityDestruction[key] = Double(i)
            }

            if matcher?.match(index: i) == false {
                continue
            }
            
            if let number = entityEvents[key] {
                entityEvents[key] = number + 1
            } else {
                entityEvents[key] = 1
            }
        }

        return entityEvents.keys.sorted().map {
            let numberOfEvents = Double(eventTypes.count - 1)
            let lifeSpanStart: Double
            let lifeSpanEnd: Double
            if let createEvent = entityCreation[$0] {
                lifeSpanStart = createEvent / numberOfEvents
            } else {
                lifeSpanStart = 1.0
            }
            if let destroyEvent = entityDestruction[$0] {
                lifeSpanEnd = destroyEvent / numberOfEvents
            } else {
                lifeSpanEnd = 1.0
            }
            return ((lifeSpanStart, lifeSpanEnd), entityEvents[$0] ?? 0, $0.entityId, $0.contextId)
        }
    }

    func durations(matcher: GroupMatcher?) -> [(TimeInterval, EventId, EventId)] {
        var result = [(TimeInterval, EventId, EventId)]()
        var lookup = [SystemNameId: EventId]()
        for i in 0..<eventTypes.count {
            let type = eventTypes[i]
            if durationRelevantEvents.contains(eventTypes[i]) == false ||
                matcher?.match(index: i) == false {
                continue
            }
            let systemId = systemNameIds[i]
            if willEvents.contains(type) {
                lookup[systemId] = EventId(i)
            } else {
                if let startId = lookup[systemId] {
                    let duration = timestamps[i] - timestamps[Int(startId)]
                    result.append((TimeInterval(duration) / 100, startId, EventId(i)))
                }
            }
        }
        return result
    }
}

extension EntitasLogger {
    public func query(_ expresion: String) throws -> QueryResult {
        let length = expresion.utf8.count
        return try expresion.withCString{ [weak self] pointer throws -> QueryResult in
            let charPointer = pointer.withMemoryRebound(to: UInt8.self, capacity: 1) {
                return $0
            }
            if let p = eat("systems", from: charPointer, length: length) {
                if let p = eat("where", from: p, length: length - charPointer.distance(to: p)) {
                    let groupMatcher = try self!.parseGroupMatcher(from: p, length: length - charPointer.distance(to: p))
                    return QueryResult.names(self!.systems(matcher: groupMatcher))
                }
                return QueryResult.names(self!.systems(matcher: nil))
            } else if let p = eat("components", from: charPointer, length: length) {
                if let p = eat("where", from: p, length: length - charPointer.distance(to: p)) {
                    let groupMatcher = try self!.parseGroupMatcher(from: p, length: length - charPointer.distance(to: p))
                    return QueryResult.names(self!.components(matcher: groupMatcher))
                }
                return QueryResult.names(self!.components(matcher: nil))
            } else if let p = eat("events", from: charPointer, length: length) {
                if let p = eat("where", from: p, length: length - charPointer.distance(to: p)) {
                    let groupMatcher = try self!.parseGroupMatcher(from: p, length: length - charPointer.distance(to: p))
                    return QueryResult.eventIds(self!.events(matcher: groupMatcher))
                }
                return QueryResult.eventIds(self!.events(matcher: nil))
            } else if let p = eat("durations", from: charPointer, length: length) {
                if let p = eat("where", from: p, length: length - charPointer.distance(to: p)) {
                    let groupMatcher = try self!.parseGroupMatcher(from: p, length: length - charPointer.distance(to: p))
                    return QueryResult.durations(self!.durations(matcher: groupMatcher))
                }
                return QueryResult.durations(self!.durations(matcher: nil))
            } else if let p = eat("entities", from: charPointer, length: length) {
                if let p = eat("where", from: p, length: length - charPointer.distance(to: p)) {
                    let groupMatcher = try self!.parseGroupMatcher(from: p, length: length - charPointer.distance(to: p))
                    return QueryResult.entities(self!.entities(matcher: groupMatcher))
                }
                return QueryResult.entities(self!.entities(matcher: nil))
            }
            throw ParsingError.unexpectedExpression("Query needs to start with 'systems', 'events', 'durations' or 'components'")
        }
    }

    public func eventData(eventId: EventId) -> EventData? {
        let index = Int(eventId)
        guard index < eventTypes.count else {
            return nil
        }
        let tick = Int(ticks[index])
        let timeStampInMs = TimeInterval(timestamps[index]) / 100
        let eventType = eventTypes[index]
        switch eventType {
        case .willExec, .didExec, .willInit, .didInit, .willCleanup, .didCleanup, .willTeardown, .didTeardown:
            let systemName = systemNames[Int(systemNameIds[index])]
            return EventData.systemEvent(eventTtype: eventType, tick: tick, timestampInMs: timeStampInMs, systemName: systemName)
        case .created, .destroyed:
            let entityId = Int(entityIds[index])
            let contextName = contextNames[Int(contextIds[index])]
            let systemNameId = Int(systemNameIds[index])
            let systemName: String?
            if systemNameId < systemNames.count {
                systemName = systemNames[systemNameId]
            } else {
                systemName = nil
            }
            return EventData.entityEvent(eventTtype: eventType, tick: tick, timestampInMs: timeStampInMs, entityId: entityId, contextName: contextName, systemName: systemName)
        case .added, .replaced, .removed:
            let entityId = Int(entityIds[index])
            let contextName = contextNames[Int(contextIds[index])]
            let componentName = compNames[Int(compNameIds[index])]
            let infoId = Int(infoIds[index])
            let info: String?
            if infoId < infos.count {
                info = infos[infoId]
            } else {
                info = nil
            }
            let systemNameId = Int(systemNameIds[index])
            let systemName: String?
            if systemNameId < systemNames.count {
                systemName = systemNames[systemNameId]
            } else {
                systemName = nil
            }
            return EventData.componentEvent(eventTtype: eventType, tick: tick, timestampInMs: timeStampInMs, entityId: entityId, contextName: contextName, componentName: componentName, info: info, systemName: systemName)
        case .info, .error:
            let systemNameId = Int(systemNameIds[index])
            let systemName: String?
            if systemNameId < systemNames.count {
                systemName = systemNames[systemNameId]
            } else {
                systemName = nil
            }
            let infoId = Int(infoIds[index])
            let info: String
            if infoId < infos.count {
                info = infos[infoId]
            } else {
                info = ""
            }
            return EventData.infoEvent(eventType: eventType, tick: tick, timestampInMs: timeStampInMs, systemName: systemName, info: info)
        }
    }

    public func contextName(id: ContextId) -> String? {
        let index = Int(id)
        guard id < contextNames.count else {
            return nil
        }
        return contextNames[index]
    }

    public func relevantEntityEvents(entityId: EntityId, contextId: ContextId) -> [EventId] {
        var componentIdLookup = [CompNameId: EventId]()
        var result: Set<EventId> = []
        for i in 0..<eventTypes.count where entityIds[i] < EntityId.max {
            switch eventTypes[i] {
            case .created, .destroyed:
                result.insert(EventId(i))
            case .added, .replaced:
                componentIdLookup[compNameIds[i]] = EventId(i)
            case .removed:
                componentIdLookup[compNameIds[i]] = nil
            default:
                continue
            }
        }
        return result.union(componentIdLookup.values).sorted()
    }
}

public enum ParsingError: Error {
    case unexpectedExpression(String)
}


extension EntitasLogger {
    func parseGroupMatcher(from start: UnsafePointer<UInt8>, length: Int) throws -> GroupMatcher {
        var all = [LoggerMatcher]()
        var any = [LoggerMatcher]()
        var none = [LoggerMatcher]()
        var p = start
        if let (matchers, p1) = try parseAllMatcher(from: p, length: length - start.distance(to: p)) {
            all = matchers
            p = p1
        }
        if let (matchers, p1) = try parseAnyMatcher(from: p, length: length - start.distance(to: p)) {
            any = matchers
            p = p1
        }
        if let (matchers, p1) = try parseNoneMatcher(from: p, length: length - start.distance(to: p)) {
            none = matchers
            p = p1
        }
        if all.isEmpty && any.isEmpty && none.isEmpty {
            throw ParsingError.unexpectedExpression("Expected all(...) any(...) none(...) after where")
        }

        return GroupMatcher(all: all, any: any, none: none)
    }

    func parseAllMatcher(from start: UnsafePointer<UInt8>, length: Int) throws -> ([LoggerMatcher], UnsafePointer<UInt8>)? {
        if let p = eat("all(", from: start, length: length) {
            if let (matchers, p) = try parseMatchers(from: p, length: length - start.distance(to: p)) {
                if let p = eat(")", from: p, length: length - start.distance(to: p)) {
                    return (matchers, p)
                } else {
                    throw ParsingError.unexpectedExpression("'all(' could not be parsed to the end, maybe you forgot ')'")
                }
            }
        }
        return nil
    }

    func parseAnyMatcher(from start: UnsafePointer<UInt8>, length: Int) throws -> ([LoggerMatcher], UnsafePointer<UInt8>)? {
        if let p = eat("any(", from: start, length: length) {
            if let (matchers, p) = try parseMatchers(from: p, length: length - start.distance(to: p)) {
                if let p = eat(")", from: p, length: length - start.distance(to: p)) {
                    return (matchers, p)
                } else {
                    throw ParsingError.unexpectedExpression("'any(' could not be parsed to the end, maybe you forgot ')'")
                }
            }
        }
        return nil
    }

    func parseNoneMatcher(from start: UnsafePointer<UInt8>, length: Int) throws -> ([LoggerMatcher], UnsafePointer<UInt8>)? {
        if let p = eat("none(", from: start, length: length) {
            if let (matchers, p) = try parseMatchers(from: p, length: length - start.distance(to: p)) {
                if let p = eat(")", from: p, length: length - start.distance(to: p)) {
                    return (matchers, p)
                } else {
                    throw ParsingError.unexpectedExpression("'none(' could not be parsed to the end, maybe you forgot ')'")
                }
            }
        }
        return nil
    }

    func parseMatchers(from start: UnsafePointer<UInt8>, length: Int) throws -> ([LoggerMatcher], UnsafePointer<UInt8>)? {
        var matchers = [LoggerMatcher]()
        var p = start;
        var found = false
        repeat {
            if let (matcher, p1) = try parseSystemMatcher(from: p, length: length - start.distance(to: p)) {
                matchers.append(matcher)
                p = p1
                found = true
            } else if let (matcher, p1) = try parseComponentMatcher(from: p, length: length - start.distance(to: p)) {
                matchers.append(matcher)
                p = p1
                found = true
            } else if let (matcher, p1) = try parseContextMatcher(from: p, length: length - start.distance(to: p)) {
                matchers.append(matcher)
                p = p1
                found = true
            } else if let (matcher, p1) = try parseEventTypeMatcher(from: p, length: length - start.distance(to: p)) {
                matchers.append(matcher)
                p = p1
                found = true
            } else if let (matcher, p1) = try parseEntityMatcher(from: p, length: length - start.distance(to: p)) {
                matchers.append(matcher)
                p = p1
                found = true
            } else if let (matcher, p1) = try parseInfoMatcher(from: p, length: length - start.distance(to: p)) {
                matchers.append(matcher)
                p = p1
                found = true
            } else if let (matcher, p1) = try parseEventIndexMatcher(from: p, length: length - start.distance(to: p)) {
                matchers.append(matcher)
                p = p1
                found = true
            } else if let (matcher, p1) = try parseTickMatcher(from: p, length: length - start.distance(to: p)) {
                matchers.append(matcher)
                p = p1
                found = true
            } else {
                found = false
            }
        } while found
        return (matchers, p)
    }

    func parseSystemMatcher(from start: UnsafePointer<UInt8>, length: Int) throws -> (SystemNameIdMatcher, UnsafePointer<UInt8>)? {
        if let p = eat("system:", from: start, length: length) {
            if let p = eat("-", from: p, length: length - start.distance(to: p)) {
                return (SystemNameIdMatcher(logger: self, sysId: .max), p)
            } else if let (ident, p) = try parseIdent(pointer: p, length: length - start.distance(to: p)) {
                if let sysId = self.systemNameMap[ident] {
                    return (SystemNameIdMatcher(logger: self, sysId: sysId), p)
                } else {
                    throw ParsingError.unexpectedExpression("No system with name '\(ident)'")
                }
            } else {
                throw ParsingError.unexpectedExpression("No identifier after 'system:'")
            }
        }
        return nil
    }

    func parseComponentMatcher(from start: UnsafePointer<UInt8>, length: Int) throws -> (ComponentNameIdMatcher, UnsafePointer<UInt8>)? {
        if let p = eat("component:", from: start, length: length) {
            if let p = eat("-", from: p, length: length - start.distance(to: p)) {
                return (ComponentNameIdMatcher(logger: self, compId: .max), p)
            } else if let (ident, p) = try parseIdent(pointer: p, length: length - start.distance(to: p)) {
                if let compId = self.componentNameMap[ident] {
                    return (ComponentNameIdMatcher(logger: self, compId: compId), p)
                } else {
                    throw ParsingError.unexpectedExpression("No component with name '\(ident)'")
                }
            } else {
                throw ParsingError.unexpectedExpression("No identifier after 'component:'")
            }
        }
        return nil
    }

    func parseContextMatcher(from start: UnsafePointer<UInt8>, length: Int) throws -> (ContextNameMatcher, UnsafePointer<UInt8>)? {
        if let p = eat("context:", from: start, length: length) {
            if let (ident, p) = try parseIdent(pointer: p, length: length - start.distance(to: p)) {
                if let contextId = self.contextNamesMap[ident] {
                    return (ContextNameMatcher(logger: self, contextId: contextId), p)
                } else {
                    throw ParsingError.unexpectedExpression("No context with name '\(ident)'")
                }
            } else {
                throw ParsingError.unexpectedExpression("No identifier after 'context:'")
            }
        }
        return nil
    }

    func parseEntityMatcher(from start: UnsafePointer<UInt8>, length: Int) throws -> (EntityIdMatcher, UnsafePointer<UInt8>)? {
        if let p = eat("entity:", from: start, length: length) {
            if let (int, p) = try parseInt(pointer: p, length: length - start.distance(to: p)) {
                if int < EntityId.max {
                    return (EntityIdMatcher(logger: self, entityId: EntityId(int)), p)
                } else {
                    throw ParsingError.unexpectedExpression("Number is too high to be an entity id'\(int)'")
                }
            } else {
                throw ParsingError.unexpectedExpression("No identifier after 'entity:'")
            }
        }
        return nil
    }

    func parseInfoMatcher(from start: UnsafePointer<UInt8>, length: Int) throws -> (InfoMatcher, UnsafePointer<UInt8>)? {
        if let p = eat("info:", from: start, length: length) {
            if let (text, p) = try parseString(pointer: p, length: length - start.distance(to: p)) {
                return (InfoMatcher(logger: self, info: text), p)
            } else {
                throw ParsingError.unexpectedExpression("No valid string in quotes '\"' after 'info:'")
            }
        }
        return nil
    }

    func parseEventIndexMatcher(from start: UnsafePointer<UInt8>, length: Int) throws -> (EventIndexMatcher, UnsafePointer<UInt8>)? {
        if let p = eat("event:", from: start, length: length) {
            if let ((min, max), p) = try parseRange(pointer: p, length: length - start.distance(to: p)) {
                return (EventIndexMatcher(logger: self, min: min, max: max), p)
            } else {
                throw ParsingError.unexpectedExpression("No valid string in quotes '\"' after 'info:'")
            }
        }
        return nil
    }

    func parseTickMatcher(from start: UnsafePointer<UInt8>, length: Int) throws -> (TickMatcher, UnsafePointer<UInt8>)? {
        if let p = eat("tick:", from: start, length: length) {
            if let ((min, max), p) = try parseRange(pointer: p, length: length - start.distance(to: p)) {
                guard min < Tick.max else {
                    throw ParsingError.unexpectedExpression("Min value is to hig: \(min)")
                }
                let min = Tick(min)
                let max = max > Tick.max ? Tick.max : Tick(max)
                return (TickMatcher(logger: self, min: min, max: max), p)
            } else {
                throw ParsingError.unexpectedExpression("No valid string in quotes '\"' after 'info:'")
            }
        }
        return nil
    }

    func parseEventTypeMatcher(from start: UnsafePointer<UInt8>, length: Int) throws -> (EventTypeMatcher, UnsafePointer<UInt8>)? {
        if let p = eat("added", from: start, length: length) {
            return (EventTypeMatcher(logger: self, type: .added), p)
        }
        if let p = eat("removed", from: start, length: length) {
            return (EventTypeMatcher(logger: self, type: .removed), p)
        }
        if let p = eat("replaced", from: start, length: length) {
            return (EventTypeMatcher(logger: self, type: .replaced), p)
        }
        if let p = eat("created", from: start, length: length) {
            return (EventTypeMatcher(logger: self, type: .created), p)
        }
        if let p = eat("destroyed", from: start, length: length) {
            return (EventTypeMatcher(logger: self, type: .destroyed), p)
        }
        if let p = eat("infoLog", from: start, length: length) {
            return (EventTypeMatcher(logger: self, type: .info), p)
        }
        if let p = eat("errorLog", from: start, length: length) {
            return (EventTypeMatcher(logger: self, type: .error), p)
        }
        if let p = eat("willExec", from: start, length: length) {
            return (EventTypeMatcher(logger: self, type: .willExec), p)
        }
        if let p = eat("didExec", from: start, length: length) {
            return (EventTypeMatcher(logger: self, type: .didExec), p)
        }
        if let p = eat("willInit", from: start, length: length) {
            return (EventTypeMatcher(logger: self, type: .willInit), p)
        }
        if let p = eat("didInit", from: start, length: length) {
            return (EventTypeMatcher(logger: self, type: .willInit), p)
        }
        if let p = eat("willCleanup", from: start, length: length) {
            return (EventTypeMatcher(logger: self, type: .willCleanup), p)
        }
        if let p = eat("didCleanup", from: start, length: length) {
            return (EventTypeMatcher(logger: self, type: .didCleanup), p)
        }
        if let p = eat("willTeardown", from: start, length: length) {
            return (EventTypeMatcher(logger: self, type: .willTeardown), p)
        }
        if let p = eat("didTeardown", from: start, length: length) {
            return (EventTypeMatcher(logger: self, type: .didTeardown), p)
        }
        return nil
    }
}

func parseIdent(pointer p: UnsafePointer<UInt8>, length: Int) throws -> (String, UnsafePointer<UInt8>)? {
    guard let p1 = eatWhiteSpace(p, length: length) else {return nil}
    guard A_Z.contains(p1.pointee) || a_z.contains(p1.pointee) || __ == p1.pointee else {
        return nil
    }
    var p2 = p1
    while A_Z.contains(p2.pointee)
        || a_z.contains(p2.pointee)
        || _0_9.contains(p2.pointee)
        || __ == p2.pointee {
            p2 = p2.advanced(by: 1)
    }
    guard let value = String(bytesNoCopy: UnsafeMutableRawPointer(mutating: p1), length: p1.distance(to: p2), encoding: .utf8, freeWhenDone: false) else {
        return nil
    }
    return (value, p2)
}

func parseString(pointer p: UnsafePointer<UInt8>, length: Int) throws -> (String, UnsafePointer<UInt8>)? {
    guard let p1 = eatWhiteSpace(p, length: length) else {return nil}
    guard 34 == p1.pointee else {
        return nil
    }
    var p2 = p1.advanced(by: 1)
    while 34 != p2.pointee {
        p2 = p2.advanced(by: 1)
    }
    guard let value = String(
        bytesNoCopy: UnsafeMutableRawPointer(mutating: p1.advanced(by: 1)),
        length: p1.distance(to: p2.advanced(by: -1)),
        encoding: .utf8,
        freeWhenDone: false
    ) else {
        return nil
    }
    return (value, p2.advanced(by: 1))
}

func parseRange(pointer p: UnsafePointer<UInt8>, length: Int) throws -> ((Int, Int), UnsafePointer<UInt8>)? {
    var minInt = 0
    var p1 = p
    if let (int, p2) = try parseInt(pointer: p, length: length) {
        minInt = int
        p1 = p2
    }
    if let p2 = eat("..", from: p1, length: length - p.distance(to: p1)) {
        if let (int, p3) = try parseInt(pointer: p2, length: length - p.distance(to: p2)) {
            guard int >= minInt else {
                throw ParsingError.unexpectedExpression("Second value in range is smaller that first \(minInt)..\(int)")
            }
            return ((minInt, int), p3)
        } else {
            return ((minInt, Int.max), p2)
        }
    } else {
        if p.distance(to: p1) > 0 {
            return ((minInt, minInt), p1)
        } else {
            throw ParsingError.unexpectedExpression("Expresion is not a range")
        }
    }
}

func parseInt(pointer p: UnsafePointer<UInt8>, length: Int) throws -> (Int, UnsafePointer<UInt8>)? {
    guard let p1 = eatWhiteSpace(p, length: length) else {return nil}
    guard _0_9.contains(p1.pointee) else {
        return nil
    }
    var p2 = p1
    var result = 0
    while _0_9.contains(p2.pointee) {
            result = result * 10 + Int(p2.pointee - 48)
            p2 = p2.advanced(by: 1)
    }
    return (result, p2)
}

func eat(_ s: StaticString, from p: UnsafePointer<UInt8>, length: Int) -> UnsafePointer<UInt8>? {
    guard let p1 = eatWhiteSpace(p, length: length) else {return nil}
    let count = s.utf8CodeUnitCount
    guard count + p.distance(to: p1) <= length else {return nil}
    for i in 0 ..< count {
        if s.utf8Start.advanced(by: i).pointee != p1.advanced(by: i).pointee {
            return nil
        }
    }
    return p1.advanced(by: count)
}

func eatWhiteSpace(_ p: UnsafePointer<UInt8>, length: Int) -> UnsafePointer<UInt8>? {
    var p1 = p
    while p1.pointee < 33 {
        p1 = p1.advanced(by: 1)
        if p.distance(to: p1) > length {
            return nil
        }
    }
    return p1
}

let A_Z = (UInt8(65)...90)
let a_z = (UInt8(97)...122)
let _0_9 = (UInt8(48)...57)
let __ = UInt8(95)
