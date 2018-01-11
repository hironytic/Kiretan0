//
// Team.swift
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

public enum TeamError: Error {
    case invalidDataStructure
}

public struct Team: Entity {
    public let teamID: String
    public let error: Error?
    public var name: String
    
    public init(teamID: String = "", error: Error? = nil, name: String) {
        self.teamID = teamID
        self.error = error
        self.name = name
    }
    
    private init(teamID: String, error: Error) {
        self.init(teamID: teamID, error: error, name: "")
    }
    
    public init(raw: RawEntity) throws {
        guard let name = (raw.data["name"] ?? "") as? String else {
            self.init(teamID: raw.documentID, error: TeamError.invalidDataStructure)
            return
        }
        
        self.init(teamID: raw.documentID, name: name)
    }
    
    public func raw() -> RawEntity {
        return RawEntity(documentID: teamID, data: ["name": name])
    }
}
