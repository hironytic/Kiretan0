//
// Item.swift
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

public enum ItemError: Error {
    case invalidDataStructure
}

public struct Item: Entity {
    public let itemID: String
    public let name: String
    public let isInsufficient: Bool
    public let lastChange: Date?
    
    public init(itemID: String = "", name: String, isInsufficient: Bool, lastChange: Date? = nil) {
        self.itemID = itemID
        self.name = name
        self.isInsufficient = isInsufficient
        self.lastChange = lastChange
    }
    
    public init(raw: RawEntity) throws {
        guard let name = (raw.data["name"] ?? "") as? String else { throw ItemError.invalidDataStructure }
        guard let isInsufficient = (raw.data["insufficient"] ?? false) as? Bool else { throw ItemError.invalidDataStructure }
        let lastChange = (raw.data["last_change"] ?? 0) as? Date
        
        self.init(itemID: raw.documentID, name: name, isInsufficient: isInsufficient, lastChange: lastChange)
    }
    
    public func raw() -> RawEntity {
        var data: [String: Any] = [
            "name": name,
            "insufficient": isInsufficient,
        ]
        if let lastChange = lastChange {
            data["last_change"] = lastChange
        }
        return RawEntity(documentID: itemID, data: data)
    }
}
