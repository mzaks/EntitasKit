//
//  TestComponents.swift
//  Entitas-Swift
//
//  Created by Maxim Zaks on 04.06.17.
//  Copyright © 2017 Maxim Zaks. All rights reserved.
//

import Foundation
import EntitasKit

struct Position: Component {
    let x: Int
    let y: Int
}

struct Size: Component {
    let value: Int
}

struct Name: Component {
    let value: String
}

struct Person: Component {}

struct God: UniqueComponent {}
