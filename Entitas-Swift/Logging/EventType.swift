//
//  EventType.swift
//  EntitasKit
//
//  Created by Maxim Zaks on 06.03.18.
//  Copyright © 2018 Maxim Zaks. All rights reserved.
//

import Foundation

public enum EventType {
    case created
    case destroyed
    case added
    case removed
    case replaced
    case willInit
    case didInit
    case willExec
    case didExec
    case willCleanup
    case didCleanup
    case willTeardown
    case didTeardown
    case info
    case error
}

public typealias Tick = UInt16
public typealias EventId = UInt32
public typealias Timestamp = UInt32
public typealias ContextId = UInt8
public typealias EntityId = UInt32
public typealias CompNameId = UInt16
public typealias SystemNameId = UInt16
public typealias InfoId = UInt32
