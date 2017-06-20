//
//  MatcherTests.swift
//  Entitas-Swift
//
//  Created by Maxim Zaks on 04.06.17.
//  Copyright © 2017 Maxim Zaks. All rights reserved.
//

import Foundation

import XCTest
@testable import EntitasKit

class MatcherTests: XCTestCase {
    
    let observer = EntityObserverStub()
    
    func testPositionMatcher() {
        let e = Entity(index: 0, mainObserver: observer)
        e.set(Position(x: 1, y: 1))
        XCTAssertTrue(Position.matcher.matches(e))
    }
    
    func testPositionAndSizeMatcher() {
        let e = Entity(index: 0, mainObserver: observer)
        let m = Matcher(all: [Position.cid, Size.cid])
        e.set(Position(x: 1, y: 1))
        XCTAssertFalse(m.matches(e))
        e.set(Size(value: 2))
        XCTAssertTrue(m.matches(e))
    }
    
    func testPositionOrSizeMatcher() {
        let e = Entity(index: 0, mainObserver: observer)
        let m = Matcher(any: [Position.cid, Size.cid])
        e.set(Position(x: 1, y: 1))
        XCTAssertTrue(m.matches(e))
        e.set(Size(value: 2))
        XCTAssertTrue(m.matches(e))
        e.remove(Position.cid)
        XCTAssertTrue(m.matches(e))
        e.remove(Size.cid)
        XCTAssertFalse(m.matches(e))
    }
    
    func testPositionOrSizeButNotNameMatcher() {
        let e = Entity(index: 0, mainObserver: observer)
        let m = Matcher(any: [Position.cid, Size.cid], none:[Name.cid])
        e.set(Position(x: 1, y: 1))
        XCTAssertTrue(m.matches(e))
        e.set(Size(value: 2))
        XCTAssertTrue(m.matches(e))
        e.set(Name(value: "Max"))
        XCTAssertFalse(m.matches(e))
    }
    
    func testPositionAndSizeButNotNameMatcher() {
        let e = Entity(index: 0, mainObserver: observer)
        let m = Matcher(all: [Position.cid, Size.cid], none:[Name.cid])
        e.set(Position(x: 1, y: 1))
        XCTAssertFalse(m.matches(e))
        e.set(Size(value: 2))
        XCTAssertTrue(m.matches(e))
        e.set(Name(value: "Max"))
        XCTAssertFalse(m.matches(e))
    }
    
    func testPositionAndSizeNameOrPersonButNotGodMatcher() {
        let e = Entity(index: 0, mainObserver: observer)
        let m = Matcher(all: [Position.cid, Size.cid], any: [Name.cid, Person.cid], none:[God.cid])
        e.set(Position(x: 1, y: 1))
        XCTAssertFalse(m.matches(e))
        e.set(Size(value: 2))
        XCTAssertFalse(m.matches(e))
        e.set(Name(value: "Max"))
        XCTAssertTrue(m.matches(e))
        e.set(Person())
        XCTAssertTrue(m.matches(e))
        e.remove(Name.cid)
        XCTAssertTrue(m.matches(e))
        e.set(God())
        XCTAssertFalse(m.matches(e))
    }
}
