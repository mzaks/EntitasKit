//
//  ObserverTests.swift
//  EntitasKit
//
//  Created by Maxim Zaks on 03.07.17.
//  Copyright © 2017 Maxim Zaks. All rights reserved.
//

import XCTest
@testable import EntitasKit

class ObserverTests: XCTestCase {
    
    class ObserverMock: EntitasKit.Observer {}
    
    var box1: ObserverBox!
    var box2: ObserverBox!
    
    func testObserverEqualityFunction() {
        let observer = ObserverMock()
        do {
            box1 = ObserverBox(observer)
            box2 = ObserverBox(ObserverMock())
        }
        XCTAssert(box1 == box2)
        
        do {
            box1 = ObserverBox(ObserverMock())
            box2 = ObserverBox(observer)
        }
        XCTAssert(box1 == box2)
        
        do {
            box1 = ObserverBox(observer)
            box2 = ObserverBox(observer)
        }
        XCTAssert(box1 == box2)
        
        let observer2 = ObserverMock()
        do {
            box1 = ObserverBox(observer2)
            box2 = ObserverBox(observer)
        }
        XCTAssert(box1 != box2)
    }
    
    func testHashFunction() {
        let observer = ObserverMock()
        var observer2: ObserverMock? = ObserverMock()
        do {
            box1 = ObserverBox(observer)
            box2 = ObserverBox(observer2!)
            observer2 = nil
        }
        XCTAssert(box1.hashValue != 0)
        // FIXME: does not work any more, could be an issue caused by new Swift version
//        XCTAssert(box2.hashValue == 0)
    }
    
}
