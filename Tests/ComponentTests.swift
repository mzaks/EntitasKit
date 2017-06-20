//
//  Entitas_SwiftTests.swift
//  Entitas-SwiftTests
//
//  Created by Maxim Zaks on 04.06.17.
//  Copyright © 2017 Maxim Zaks. All rights reserved.
//

import XCTest
@testable import EntitasKit

class ComponentTests: XCTestCase {
    
    func testCreateComponentAndCheckCID() {
        let p = Position(x:12, y:14)
        XCTAssertEqual(Position.cid, p.cid)
        
        let g = God()
        XCTAssertEqual(God.cid, g.cid)
    }
    
}
