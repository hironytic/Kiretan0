//
// UserAccountStore.swift
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
import FirebaseAuth

public protocol UserAccountStore {
    var currentUser: Observable<UserAccount?> { get }
    
    func signInAnonymously()
    func signOut()
}

public protocol UserAccountStoreResolver {
    func resolveUserAccountStore() -> UserAccountStore
}

extension DefaultResolver: UserAccountStoreResolver {
    public func resolveUserAccountStore() -> UserAccountStore {
        return userAccountStore
    }
}

public class DefaultUserAccountStore: UserAccountStore {
    public typealias Resolver = ErrorStoreResolver

    public let currentUser: Observable<UserAccount?>
    
    private let _resolver: Resolver
    
    public init(resolver: Resolver) {
        _resolver = resolver
        
        currentUser =
            Observable.create({ (observer) -> Disposable in
                let handle =  Auth.auth().addStateDidChangeListener() { (auth, user) in
                    observer.onNext(user.map { UserAccount(user: $0) })
                }
                return Disposables.create {
                    Auth.auth().removeStateDidChangeListener(handle)
                }
            })
            .shareReplayLatestWhileConnected()
    }
    
    public func signInAnonymously() {
        Auth.auth().signInAnonymously()
    }
    
    public func signOut() {
        do {
            try Auth.auth().signOut()
        } catch let error {
            _resolver.resolveErrorStore().post(error: error)
        }
    }
}
