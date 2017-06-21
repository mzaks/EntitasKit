//
//  Matcher.swift
//  Entitas-Swift
//
//  Created by Maxim Zaks on 04.06.17.
//  Copyright © 2017 Maxim Zaks. All rights reserved.
//

import Foundation

public struct Matcher {
    let allOf: Set<CID>
    let anyOf: Set<CID>
    let noneOf: Set<CID>
    public func matches(_ e: Entity) -> Bool {
        for id in allOf {
            if e.has(id) == false {
                return false
            }
        }
        for id in noneOf {
            if e.has(id) == true {
                return false
            }
        }
        if anyOf.isEmpty {
            return true
        }
        for id in anyOf {
            if e.has(id) == true {
                return true
            }
        }
        return false
    }
    
    public init(all: Set<CID>, any: Set<CID>, none: Set<CID>) {
        allOf = all
        anyOf = any
        noneOf = none
        assert(allOf.isEmpty == false || anyOf.isEmpty == false, "Your matcher does not have elements in allOf or in anyOf set")
        assert(isDisjoint, "Your matcher is not disjoint")
    }
    
    public init(all: Set<CID>) {
        self.init(all: all, any:[], none: [])
    }
    public init(all: Set<CID>, any: Set<CID>) {
        self.init(all: all, any:any, none: [])
    }
    public init(any: Set<CID>) {
        self.init(all: [], any:any, none: [])
    }
    public init(any: Set<CID>, none: Set<CID>) {
        self.init(all: [], any:any, none: none)
    }
    public init(all: Set<CID>, none: Set<CID>) {
        self.init(all: all, any:[], none: none)
    }
    
    private var isDisjoint : Bool {
        return allOf.isDisjoint(with: anyOf) && allOf.isDisjoint(with: noneOf) && anyOf.isDisjoint(with: noneOf)
    }
}

extension Matcher: Hashable {
    public var hashValue: Int {
        return allOf.hashValue ^ anyOf.hashValue ^ noneOf.hashValue
    }
    public static func ==(a: Matcher, b: Matcher) -> Bool {
        return a.allOf == b.allOf && a.anyOf == b.anyOf && a.noneOf == b.noneOf
    }
}

extension Component {
    public static var matcher: Matcher {
        return Matcher(all:[Self.cid])
    }
}
