//
// MockFunction.swift
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

public class MockFunction<F> {
    private let name: String
    private var inner = MockFunctionProvider<F>()

    public init(_ name: String) {
        self.name = name
    }
    
    public var call: F {
        return inner.nextFunction(name)
    }
    
    public func setup(function: F) {
        inner = SingleMockFunctionProvider(function: function)
    }
    
    public func setupSequence(functions: [F]) {
        inner = SequenceMockFunctionProvider(functions: functions)
    }
}

private class MockFunctionProvider<F> {
    func nextFunction(_ name: String) -> F {
        XCTFail("unexpected call in mock '\(name)'")
        fatalError()
    }
}

private class SingleMockFunctionProvider<F>: MockFunctionProvider<F> {
    let function: F
    
    init(function: F) {
        self.function = function
    }
    
    override func nextFunction(_ name: String) -> F {
        return function
    }
}

private class SequenceMockFunctionProvider<F>: MockFunctionProvider<F> {
    let functions: [F]
    var index = 0
    
    init(functions: [F]) {
        self.functions = functions
    }
    
    override func nextFunction(_ name: String) -> F {
        guard index < functions.count else {
            XCTFail("unexpected call in mock '\(name)'")
            fatalError()
        }
        
        let f = functions[index]
        index += 1
        return f
    }
}
