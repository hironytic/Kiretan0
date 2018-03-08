//
// CollectionChange.swift
// Kiretan0
//
// Copyright (c) 2017 Hironori Ichimiya <hiron@hironytic.com>
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
//

import Foundation

public struct CollectionChange<Entity> {
    public let result: [Entity]
    public let events: [CollectionEvent<Entity>]
}

private class ChangeTarget: Hashable {
    var prevIndex: Int = NSNotFound
    let currentIndex: Int
    init(currentIndex: Int = NSNotFound) {
        self.currentIndex = currentIndex
    }
    
    var hashValue: Int { return currentIndex }
    static func ==(lhs: ChangeTarget, rhs: ChangeTarget) -> Bool {
        return lhs === rhs
    }
}

extension CollectionChange {
    public func updateHintDifference() -> TableViewUpdateHint.Difference {
        // simulate targets location by applying changes in reverse order
        // so that we get original indices in previous snapshot
        var targets = Set<ChangeTarget>()
        var collection = result.enumerated().map { ChangeTarget(currentIndex: $0.0) }
        for event in events.reversed() {
            let ct: ChangeTarget
            switch event {
            case .inserted(let nx, _):
                ct = collection.remove(at: nx)
                
            case .deleted(let ox):
                ct = ChangeTarget()
                collection.insert(ct, at: ox)
                
            case .moved(let ox, let nx, _):
                ct = collection.remove(at: nx)
                collection.insert(ct, at: ox)
            }
            targets.insert(ct)
        }
        for (i, target) in collection.enumerated() {
            target.prevIndex = i
        }
        
        let deletions = targets.filter { $0.prevIndex != NSNotFound && $0.currentIndex == NSNotFound }.map { $0.prevIndex }.sorted()
        let modifications = targets.filter { $0.prevIndex != NSNotFound && $0.currentIndex != NSNotFound }.map { ($0.prevIndex, $0.currentIndex) }.sorted { $0.0 < $1.0 }
        let insertions = targets.filter { $0.prevIndex == NSNotFound && $0.currentIndex != NSNotFound }.map { $0.currentIndex }.sorted()
        return TableViewUpdateHint.Difference(deletedRows: deletions.map({ IndexPath(row: $0, section: 0) }),
                                              insertedRows: insertions.map({ IndexPath(row: $0, section: 0) }),
                                              movedRows: modifications.map({ (IndexPath(row: $0.0, section: 0), IndexPath(row: $0.1, section: 0)) }))
    }
}
