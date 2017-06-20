//
//  Listener.swift
//  Entitas-Swift
//
//  Created by Maxim Zaks on 04.06.17.
//  Copyright © 2017 Maxim Zaks. All rights reserved.
//

import Foundation

public protocol Observer: class {}

struct ObserverBox: Hashable {
    private(set) weak var ref: Observer?
    
    init(_ ref: Observer) {
        self.ref = ref
    }
    public var hashValue: Int {
        guard let ref = ref else {
            return 0
        }
        return ObjectIdentifier(ref).hashValue
    }
    public static func ==(a: ObserverBox, b: ObserverBox) -> Bool {
        if a.ref == nil || b.ref == nil {
            // ⚠️ This is a trick to make the set replace empty observer boxes.
            // The trick works iff the ObeserverBox is inserted with `Set.update(with:)` method.
            // In case you use `Set.insert()` method.
            // This trick will prevent inserting new observers, if the set contains an empty box.
            // Which leads to unexpected behaviour. 🔴
            return true
        }
        return a.ref === b.ref
    }
}
