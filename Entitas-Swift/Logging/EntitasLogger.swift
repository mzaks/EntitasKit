//
//  EntitasLogger.swift
//  EntitasKitTests
//
//  Created by Maxim Zaks on 04.03.18.
//  Copyright © 2018 Maxim Zaks. All rights reserved.
//

import Foundation

public class EntitasLogger {
    var tick: Tick = 0
    var eventTypes = [EventType]()
    var ticks = [Tick]()
    var timestamps = [Timestamp]()
    var contextIds = [ContextId]()
    var entityIds = [EntityId]()
    var compNameIds = [CompNameId]()
    var systemNameIds = [SystemNameId]()
    var infoIds = [InfoId]()
    var infos = [String]()

    let loggingStartTime: CFAbsoluteTime

    var contextMap = [ObjectIdentifier: ContextId]()
    var contextNamesMap = [String: ContextId]()
    var contextNames = [String]()
    var entityContextMap = [ObjectIdentifier: ContextId]()

    var systemNameMap = [String: SystemNameId]()
    var systemNames = [String]()
    var firstExecSystemNameId = SystemNameId.max
    private func systemId(_ name: String) -> SystemNameId {
        if let systemId = systemNameMap[name] {
            return systemId
        }
        let id = SystemNameId(systemNameMap.count)
        systemNameMap[name] = id
        systemNames.append(name)
        return id
    }

    var componentCidMap = [CID: CompNameId]()
    var componentNameMap = [String: CompNameId]()
    var compNames = [String]()
    private func compId(_ component: Component) -> CompNameId {
        if let compId = componentCidMap[component.cid] {
            return compId
        }
        let id = UInt16(componentCidMap.count)
        componentCidMap[component.cid] = id
        componentNameMap["\(type(of:component))"] = id
        compNames.append("\(type(of:component))")
        return id
    }

    var sysCallStack = [(Timestamp, SystemNameId, EventType)]()
    var sysCallStackMaterialised = 0

    public init(contexts: [(Context, String)]) {
        loggingStartTime = CFAbsoluteTimeGetCurrent()
        for (ctx, name) in contexts {
            contextMap[ObjectIdentifier(ctx)] = ContextId(contextMap.count)
            contextNamesMap[name] = ContextId(contextNames.count)
            contextNames.append(name)
            ctx.observer(add: self)
        }
    }

    public func addInfo(_ text: String) {
        sysCallStackMaterialise()
        let infoId = InfoId(infos.count)
        infos.append(text)
        addEvent(
            type: .info,
            timestamp: currentTimestamp,
            systemNameId: sysCallStack.last?.1 ?? SystemNameId.max,
            infoId: infoId
        )
    }

    public func addError(_ text: String) {
        sysCallStackMaterialise()
        let infoId = InfoId(infos.count)
        infos.append(text)
        addEvent(
            type: .error,
            timestamp: currentTimestamp,
            systemNameId: sysCallStack.last?.1 ?? SystemNameId.max,
            infoId: infoId
        )
    }

    private func addEvent(
        type: EventType,
        timestamp: Timestamp,
        contextId: ContextId = .max,
        entityId: EntityId = .max,
        compNameId: CompNameId = .max,
        systemNameId: SystemNameId = .max,
        infoId: InfoId = .max
    ) {
        eventTypes.append(type)
        ticks.append(tick)
        timestamps.append(timestamp)
        contextIds.append(contextId)
        entityIds.append(entityId)
        compNameIds.append(compNameId)
        systemNameIds.append(systemNameId)
        infoIds.append(infoId)
    }

    private var currentTimestamp: Timestamp {
        // WE can record only 710 minutes
        return Timestamp((CFAbsoluteTimeGetCurrent() - loggingStartTime) * 100_000)
    }
}

extension EntitasLogger: SystemExecuteLogger {

    private func pushSysCall(event: EventType, sysName: String) {
        let sysId = systemId(sysName)
        if event == .willExec {
            if firstExecSystemNameId == .max {
                firstExecSystemNameId = sysId
                tick += 1
            } else if firstExecSystemNameId == sysId {
                tick += 1
            }
        }
        sysCallStack.append((currentTimestamp, sysId, event))
    }

    private func popSysCal(event: EventType, name: String) {
        let timestamp = currentTimestamp
        if sysCallStackMaterialised != sysCallStack.count {
            if let sysCall = sysCallStack.last, timestamp - sysCall.0 > 500 {
                sysCallStackMaterialise()
                addEvent(type: event, timestamp: timestamp, systemNameId: systemId(name))
                sysCallStack.removeLast()
                sysCallStackMaterialised = sysCallStack.count
            } else {
                sysCallStack.removeLast()
            }
        } else {
            addEvent(type: event, timestamp: timestamp, systemNameId: systemId(name))
            sysCallStack.removeLast()
            sysCallStackMaterialised = sysCallStack.count
        }
    }

    private func sysCallStackMaterialise() {
        guard sysCallStack.isEmpty == false
            && sysCallStackMaterialised < sysCallStack.count else { return }
        for sysCal in sysCallStack[sysCallStackMaterialised...] {
            addEvent(type: sysCal.2, timestamp: sysCal.0, systemNameId: sysCal.1)
        }
        sysCallStackMaterialised = sysCallStack.count
    }

    public func willExecute(_ name: String) {
        pushSysCall(event: .willExec, sysName: name)
    }

    public func didExecute(_ name: String) {
        popSysCal(event: .didExec, name: name)
    }

    public func willInit(_ name: String) {
        pushSysCall(event: .willInit, sysName: name)
    }

    public func didInit(_ name: String) {
        popSysCal(event: .didInit, name: name)
    }

    public func willCleanup(_ name: String) {
        pushSysCall(event: .willCleanup, sysName: name)
    }

    public func didCleanup(_ name: String) {
        popSysCal(event: .didCleanup, name: name)
    }

    public func willTeardown(_ name: String) {
        pushSysCall(event: .willTeardown, sysName: name)
    }

    public func didTeardown(_ name: String) {
        popSysCal(event: .didTeardown, name: name)
    }
}

extension EntitasLogger: ContextObserver {
    public func created(entity: Entity, in context: Context) {
        entity.observer(add: self)
        sysCallStackMaterialise()
        let entityId = EntityId(entity.creationIndex)
        let contextId = contextMap[ObjectIdentifier(context)] ?? ContextId.max
        addEvent(
            type: .created,
            timestamp: currentTimestamp,
            contextId: contextId,
            entityId: entityId,
            systemNameId: sysCallStack.last?.1 ?? SystemNameId.max
        )
        entityContextMap[ObjectIdentifier(entity)] = contextId
    }

    public func created(group: Group, withMatcher matcher: Matcher, in context: Context) {}

    public func created<T, C>(index: Index<T, C>, in context: Context) {}
}

extension EntitasLogger: EntityObserver {
    public func updated(component oldComponent: Component?, with newComponent: Component, in entity: Entity) {
        sysCallStackMaterialise()
        let entityId = EntityId(entity.creationIndex)
        let entityObjectId = ObjectIdentifier(entity)
        let contextId = entityContextMap[entityObjectId] ?? ContextId.max
        let compNameId = compId(newComponent)
        let infoId: InfoId
        if let compInfo = (newComponent as? ComponentInfo)?.info {
            infoId = InfoId(infos.count)
            infos.append(compInfo)
        } else {
            infoId = .max
        }
        addEvent(
            type: oldComponent == nil ? .added : .replaced,
            timestamp: currentTimestamp,
            contextId: contextId,
            entityId: entityId,
            compNameId: compNameId,
            systemNameId: sysCallStack.last?.1 ?? SystemNameId.max,
            infoId: infoId
        )
    }

    public func removed(component: Component, from entity: Entity) {
        sysCallStackMaterialise()
        let entityId = EntityId(entity.creationIndex)
        let entityObjectId = ObjectIdentifier(entity)
        let contextId = entityContextMap[entityObjectId] ?? ContextId.max
        let compNameId = compId(component)
        addEvent(
            type: .removed,
            timestamp: currentTimestamp,
            contextId: contextId,
            entityId: entityId,
            compNameId: compNameId,
            systemNameId: sysCallStack.last?.1 ?? SystemNameId.max
        )
    }

    public func destroyed(entity: Entity) {
        entity.observer(add: self)
        sysCallStackMaterialise()
        let entityId = EntityId(entity.creationIndex)
        let entityObjectId = ObjectIdentifier(entity)
        let contextId = entityContextMap[entityObjectId] ?? ContextId.max
        addEvent(
            type: .destroyed,
            timestamp: currentTimestamp,
            contextId: contextId,
            entityId: entityId,
            systemNameId: sysCallStack.last?.1 ?? SystemNameId.max
        )
        entityContextMap[entityObjectId] = nil
    }
}
