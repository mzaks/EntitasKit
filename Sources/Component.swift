//
//  Component.swift
//  Entitas-Swift
//
//  Created by Maxim Zaks on 04.06.17.
//  Copyright © 2017 Maxim Zaks. All rights reserved.
//

import Foundation

public struct CID : Hashable {
    let oi: ObjectIdentifier
    init(_ c : Component.Type) {
        oi = ObjectIdentifier(c)
    }
    public var hashValue: Int {
        return oi.hashValue
    }
    public static func ==(a: CID, b: CID) -> Bool {
        return a.oi == b.oi
    }
}

public protocol Component {}
public protocol UniqueComponent: Component {}

extension Component {
    public static var cid : CID {
        return CID(Self.self)
    }
    public var cid : CID {
        return CID(Self.self)
    }
}
