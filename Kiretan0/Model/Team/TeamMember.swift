//
// TeamMember.swift
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

public enum TeamMemberError: Error {
    case invalidDataStructure
}

public struct TeamMember: DatabaseEntity {
    public let memberID: String
    public let name: String
    
    public init(memberID: String = "", name: String) {
        self.memberID = memberID
        self.name = name
    }
    
    public init(key: String, value: Any) throws {
        guard let value = value as? [String: Any] else { throw TeamMemberError.invalidDataStructure }
        guard let name = (value["name"] ?? "") as? String else { throw TeamMemberError.invalidDataStructure }
        
        self.init(memberID: key, name: name)
    }
    
    public var key: String {
        return memberID
    }
    
    public var value: Any {
        return ["name": name]
    }
}
