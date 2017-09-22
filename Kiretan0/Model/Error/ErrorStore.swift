//
// ErrorStore.swift
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

public protocol ErrorStore {
    var error: Observable<Error> { get }
    
    func post(error: Error)
}

public protocol ErrorStoreResolver {
    func resolveErrorStore() -> ErrorStore
}

extension DefaultResolver: ErrorStoreResolver {
    public func resolveErrorStore() -> ErrorStore {
        return errorStore
    }
}

public class DefaultErrorStore: ErrorStore {
    public typealias Resolver = NullResolver

    public let error: Observable<Error>
    
    private let _resolver: Resolver
    private let _errorSubject = PublishSubject<Error>()
    
    public init(resolver: Resolver) {
        _resolver = resolver
        error = _errorSubject.asObservable()
    }
    
    public func post(error: Error) {
        _errorSubject.onNext(error)
    }
}
