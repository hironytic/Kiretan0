//
// Recording.swift
// Kiretan0Tests
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

import XCTest
import RxSwift

/// An observer that fulfills specified expectation after it records events specified times.
public class Recording<Element>: ObserverType {
    public typealias E = Element
    private var expectation: XCTestExpectation
    private var currentCount: Int
    private var maxCount: Int
    public var events: [Event<E>]
    
    public init(_ expectation: XCTestExpectation, count: Int) {
        self.expectation = expectation
        maxCount = count
        currentCount = 0
        events = []
    }

    public func reset(_ expectation: XCTestExpectation, count: Int) {
        self.expectation = expectation
        maxCount = count
        currentCount = 0
        events = []
    }
    
    public func on(_ event: Event<Element>) {
        guard currentCount < maxCount else { return }
        
        events.append(event)
        currentCount += 1
        if currentCount >= maxCount {
            expectation.fulfill()
        }
    }
}
