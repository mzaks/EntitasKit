//
//  GroupTests.swift
//  Entitas-Swift
//
//  Created by Maxim Zaks on 17.06.17.
//  Copyright © 2017 Maxim Zaks. All rights reserved.
//

import Foundation

import XCTest
@testable import EntitasKit

class GroupTests: XCTestCase {
    
    class Observer: GroupObserver {
        
        var addedData: [(entity: Entity, oldComponent: Component?, newComponent: Component?)] = []
        func added(entity: Entity, oldComponent: Component?, newComponent: Component?, in group: Group) {
            addedData.append((entity: entity, oldComponent: oldComponent, newComponent:newComponent))
        }
        var updatedData: [(entity: Entity, oldComponent: Component?, newComponent: Component?)] = []
        func updated(entity: Entity, oldComponent: Component?, newComponent: Component?, in group: Group) {
            updatedData.append((entity: entity, oldComponent: oldComponent, newComponent:newComponent))
        }
        var removedData: [(entity: Entity, oldComponent: Component?, newComponent: Component?)] = []
        func removed(entity: Entity, oldComponent: Component?, newComponent: Component?, in group: Group) {
            removedData.append((entity: entity, oldComponent: oldComponent, newComponent:newComponent))
        }
    }
    
    func testObservAllOfGroup() {
        let ctx = Context()
        let g = ctx.getGroup(Matcher(all:[Position.cid, Size.cid]))
        let o = Observer()
        g.observer(add:o)
        
        let e = ctx.createEntity().set(Position(x: 1, y:2)).set(Size(value: 123))
        
        XCTAssertEqual(o.addedData.count, 1)
        XCTAssertEqual(o.updatedData.count, 0)
        XCTAssertEqual(o.removedData.count, 0)
        
        XCTAssert(o.addedData[0].entity === e)
        XCTAssertNil(o.addedData[0].oldComponent)
        XCTAssertEqual((o.addedData[0].newComponent as? Size)?.value, 123)

        
        e.set(Position(x:3, y:1))
        XCTAssertEqual(o.addedData.count, 1)
        XCTAssertEqual(o.updatedData.count, 1)
        XCTAssertEqual(o.removedData.count, 0)
        
        XCTAssert(o.addedData[0].entity === e)
        XCTAssertEqual((o.updatedData[0].oldComponent as? Position)?.x, 1)
        XCTAssertEqual((o.updatedData[0].oldComponent as? Position)?.y, 2)
        XCTAssertEqual((o.updatedData[0].newComponent as? Position)?.x, 3)
        XCTAssertEqual((o.updatedData[0].newComponent as? Position)?.y, 1)
        
        e.remove(Size.cid)
        XCTAssertEqual(o.addedData.count, 1)
        XCTAssertEqual(o.updatedData.count, 1)
        XCTAssertEqual(o.removedData.count, 1)
        
        XCTAssert(o.removedData[0].entity === e)
        XCTAssertNil(o.removedData[0].newComponent)
        XCTAssertEqual((o.removedData[0].oldComponent as? Size)?.value, 123)
        
        e.destroy() // no effect because is already out of the group
        XCTAssertEqual(o.addedData.count, 1)
        XCTAssertEqual(o.updatedData.count, 1)
        XCTAssertEqual(o.removedData.count, 1)
    }
    
    
    func testObservAnyOfGroup() {
        let ctx = Context()
        let g = ctx.getGroup(Matcher(any:[Position.cid, Size.cid]))
        let o = Observer()
        g.observer(add:o)
        
        let e = ctx.createEntity().set(Position(x: 1, y:2))
        XCTAssertEqual(o.addedData.count, 1)
        XCTAssertEqual(o.updatedData.count, 0)
        XCTAssertEqual(o.removedData.count, 0)
        
        XCTAssert(o.addedData[0].entity === e)
        XCTAssertNil(o.addedData[0].oldComponent)
        XCTAssertEqual((o.addedData[0].newComponent as? Position)?.x, 1)
        XCTAssertEqual((o.addedData[0].newComponent as? Position)?.y, 2)
        
        e.set(Size(value:34))
        XCTAssertEqual(o.addedData.count, 1)
        XCTAssertEqual(o.updatedData.count, 1)
        XCTAssertEqual(o.removedData.count, 0)
        
        XCTAssert(o.updatedData[0].entity === e)
        XCTAssertNil(o.updatedData[0].oldComponent)
        XCTAssertEqual((o.updatedData[0].newComponent as? Size)?.value, 34)
        
        e.remove(Size.cid)
        XCTAssertEqual(o.addedData.count, 1)
        XCTAssertEqual(o.updatedData.count, 2)
        XCTAssertEqual(o.removedData.count, 0)
        
        XCTAssert(o.updatedData[1].entity === e)
        XCTAssertNil(o.updatedData[1].newComponent)
        XCTAssertEqual((o.updatedData[1].oldComponent as? Size)?.value, 34)
        
        e.destroy()
        XCTAssertEqual(o.addedData.count, 1)
        XCTAssertEqual(o.updatedData.count, 2)
        XCTAssertEqual(o.removedData.count, 1)
        
        XCTAssert(o.removedData[0].entity === e)
        XCTAssertNil(o.removedData[0].newComponent)
        XCTAssertEqual((o.removedData[0].oldComponent as? Position)?.x, 1)
        XCTAssertEqual((o.removedData[0].oldComponent as? Position)?.y, 2)
        
    }
    
    func testObservAllOfNoneOfGroup(){
        let ctx = Context()
        let g = ctx.getGroup(Matcher(all:[Position.cid, Size.cid], none: [Name.cid]))
        let o = Observer()
        g.observer(add:o)
        
        let e = ctx.createEntity().set(Position(x: 1, y:2))
        
        XCTAssertEqual(o.addedData.count, 0)
        XCTAssertEqual(o.updatedData.count, 0)
        XCTAssertEqual(o.removedData.count, 0)
        
        e.set(Size(value: 12))
        XCTAssertEqual(o.addedData.count, 1)
        XCTAssertEqual(o.updatedData.count, 0)
        XCTAssertEqual(o.removedData.count, 0)
        
        XCTAssert(o.addedData[0].entity === e)
        XCTAssertNil(o.addedData[0].oldComponent)
        XCTAssertEqual((o.addedData[0].newComponent as? Size)?.value, 12)
        
        e.set(Name(value: "Max"))
        XCTAssertEqual(o.addedData.count, 1)
        XCTAssertEqual(o.updatedData.count, 0)
        XCTAssertEqual(o.removedData.count, 1)
        
        XCTAssert(o.removedData[0].entity === e)
        XCTAssertNil(o.removedData[0].oldComponent)
        XCTAssertEqual((o.removedData[0].newComponent as? Name)?.value, "Max")
        
        e.remove(Name.cid)
        XCTAssertEqual(o.addedData.count, 2)
        XCTAssertEqual(o.updatedData.count, 0)
        XCTAssertEqual(o.removedData.count, 1)
        
        XCTAssert(o.addedData[1].entity === e)
        XCTAssertNil(o.addedData[1].newComponent)
        XCTAssertEqual((o.addedData[1].oldComponent as? Name)?.value, "Max")
    }
    
    func testRemoveObserving() {
        let ctx = Context()
        let g = ctx.getGroup(Matcher(any:[Position.cid, Size.cid]))
        let o = Observer()
        g.observer(add:o)
        
        let e = ctx.createEntity().set(Position(x: 1, y:2))
        XCTAssertEqual(o.addedData.count, 1)
        XCTAssertEqual(o.updatedData.count, 0)
        XCTAssertEqual(o.removedData.count, 0)
        
        g.observer(remove:o)
        e.set(Size(value: 123))
        XCTAssertEqual(o.addedData.count, 1)
        XCTAssertEqual(o.updatedData.count, 0)
        XCTAssertEqual(o.removedData.count, 0)
    }
    
    func testWeakObserverGetRemoved() {
        let ctx = Context()
        let g = ctx.getGroup(Matcher(any:[Position.cid, Size.cid]))
        weak var o0 : Observer?
        do {
            let o = Observer()
            g.observer(add:o)
            o0 = o
        }
        let o1 = Observer()
        g.observer(add:o1)
        
        ctx.createEntity().set(Position(x: 1, y:2))
        XCTAssertNil(o0)
        XCTAssertEqual(o1.addedData.count, 1)
        XCTAssertEqual(o1.updatedData.count, 0)
        XCTAssertEqual(o1.removedData.count, 0)
    }
    
    func testMultipleGroups() {
        let ctx = Context()
        let g1 = ctx.getGroup(Matcher(any:[Position.cid, Size.cid]))
        let g2 = ctx.getGroup(Matcher(all:[Position.cid, Size.cid]))
        
        let o1 = Observer()
        let o2 = Observer()
        
        g1.observer(add:o1)
        g2.observer(add:o2)
        
        let e = ctx.createEntity().set(Position(x: 1, y:2))
        
        XCTAssertEqual(o1.addedData.count, 1)
        XCTAssertEqual(o1.updatedData.count, 0)
        XCTAssertEqual(o1.removedData.count, 0)
        
        XCTAssertEqual(o2.addedData.count, 0)
        XCTAssertEqual(o2.updatedData.count, 0)
        XCTAssertEqual(o2.removedData.count, 0)
        
        e.set(Size(value: 43))
        
        XCTAssertEqual(o1.addedData.count, 1)
        XCTAssertEqual(o1.updatedData.count, 1)
        XCTAssertEqual(o1.removedData.count, 0)
        
        XCTAssertEqual(o2.addedData.count, 1)
        XCTAssertEqual(o2.updatedData.count, 0)
        XCTAssertEqual(o2.removedData.count, 0)
    }
    
    func testEntityObjectPool() {
        let ctx = Context()
        let g = ctx.getGroup(Position.matcher)
        
        weak var e = ctx.createEntity().set(Position(x: 1, y:2))
        
        weak var e1 = ctx.createEntity().set(Position(x: 2, y:2))
        
        XCTAssertEqual(g.count, 2)
        
        XCTAssert(e !== e1)
        
        e?.destroy()
        
        XCTAssertEqual(g.count, 1)
        
        weak var e2 = ctx.createEntity().set(Position(x: 3, y:2))
        
        XCTAssertEqual(g.count, 2)
        
        XCTAssert(e2 === e)
    }
    
    func testSoretedListFromGroup() {
        let ctx = Context()
        let g = ctx.getGroup(Position.matcher)
        
        var list = g.sorted()
        
        XCTAssertEqual(list, [])
        
        let e = ctx.createEntity().set(Position(x: 1, y:2))
        
        let e1 = ctx.createEntity().set(Position(x: 2, y:2))
        
        list = g.sorted()
        
        XCTAssertEqual(list, [e, e1])
    }
}
