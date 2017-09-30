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
import FirebaseDatabase

public enum ItemError: Error {
    case invalidDataStructure
}

public struct Item: DatabaseEntity {
    public let itemID: String
    public let name: String
    public let isInsufficient: Bool
    public let lastChange: Int64
    
    public init(itemID: String = "", name: String, isInsufficient: Bool, lastChange: Int64 = 0) {
        self.itemID = itemID
        self.name = name
        self.isInsufficient = isInsufficient
        self.lastChange = lastChange
    }
    
    public init(key: String, value: Any) throws {
        guard let value = value as? [String: Any] else { throw ItemError.invalidDataStructure }
        guard let name = (value["name"] ?? "") as? String else { throw ItemError.invalidDataStructure }
        guard let isInsufficient = (value["insufficient"] ?? false) as? Bool else { throw ItemError.invalidDataStructure }
        guard let lastChange = (value["last_change"] ?? 0) as? Int64 else { throw ItemError.invalidDataStructure }
        
        self.init(itemID: key, name: name, isInsufficient: isInsufficient, lastChange: lastChange)
    }
    
    public var key: String {
        return itemID
    }
    
    public var value: Any {
        return [
            "name": name,
            "insufficient": isInsufficient,
            "last_change": ServerValue.timestamp(),
        ]
    }
}
