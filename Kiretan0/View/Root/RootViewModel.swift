//
// RootViewModel.swift
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

public enum RootScene {
    case welcome
    case main
}

public protocol RootViewModel: ViewModel {
    var scene: Observable<RootScene> { get }
}

public class DefaultRootViewModel: RootViewModel {
    public typealias Resolver = UserAccountStoreResolver
    
    public let scene: Observable<RootScene>

    private let _resolver: Resolver
    private var _disposeBag: DisposeBag? = DisposeBag()
    private let _scene: Observable<RootScene>
    
    public init(resolver: Resolver) {
        _resolver = resolver
        
        let userStore = _resolver.resolveUserAccountStore()
        _scene = userStore.currentUser
            .map { (userAccount) -> RootScene in
                if userAccount == nil {
                    return .welcome
                } else {
                    return .main
                }
            }
            .distinctUntilChanged()
        
        scene = _scene
            .shareReplayLatestWhileConnected()
            .observeOn(MainScheduler.instance)
    }
}
