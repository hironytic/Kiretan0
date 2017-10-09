//
// MemberTeam.swift
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

public enum MemberTeamError: Error {
    case invalidDataStructure
}

public struct MemberTeam: Entity {
    public let memberID: String
    public let teamIDList: [String]
    
    public init(memberID: String = "", teamIDList: [String]) {
        self.memberID = memberID
        self.teamIDList = teamIDList
    }
    
    public init(documentID: String, data: [String: Any]) throws {
        let teamIDList = data.keys.sorted()
        self.init(memberID: documentID, teamIDList: teamIDList)
    }
    
    public var documentID: String {
        return memberID
    }
    
    public var data: [String: Any] {
        return teamIDList.reduce(into: [:]) { (acc, teamID) in
            acc[teamID] = true
        }
    }
}
