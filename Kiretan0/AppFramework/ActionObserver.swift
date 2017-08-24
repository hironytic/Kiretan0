//
// ActionObserver.swift
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
import RxSwift

public class ActionObserver<Element>: ObserverType {
    public typealias E = Element
    public typealias Handler = (Element) -> Void
    
    public var handler: Handler

    public convenience init() {
        self.init { _ in }
    }
    
    public init(handler: @escaping Handler) {
        self.handler = handler
    }

    public func on(_ event: Event<Element>) {
        switch event {
        case .next(let element):
            handler(element)
        case .error(_):
            break
        case .completed:
            break
        }
    }
    
    public static func asObserver(_ handler: @escaping Handler) -> AnyObserver<Element> {
        return ActionObserver<Element>(handler: handler).asObserver()
    }
}
