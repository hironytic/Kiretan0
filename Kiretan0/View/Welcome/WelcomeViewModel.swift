//
// WelcomeViewModel.swift
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

public protocol WelcomeViewModel: ViewModel {
    var newAnonymousUserEnabled: Observable<Bool> { get }
    
    var onNewAnonymousUser: AnyObserver<Void> { get }
}

public protocol WelcomeViewModelResolver {
    func resolveWelcomeViewModel() -> WelcomeViewModel
}

extension DefaultResolver: WelcomeViewModelResolver {
    public func resolveWelcomeViewModel() -> WelcomeViewModel {
        return DefaultWelcomeViewModel(resolver: self)
    }
}

public class DefaultWelcomeViewModel: WelcomeViewModel {
    public typealias Resolver = UserAccountRepositoryResolver

    public let newAnonymousUserEnabled: Observable<Bool>
    public let onNewAnonymousUser: AnyObserver<Void>
    
    private let _resolver: Resolver
    private let _disposeBag = DisposeBag()
    private let _processing = Variable<Bool>(false)
    private let _onNewAnonymousUser = ActionObserver<Void>()
    
    public init(resolver: Resolver) {
        _resolver = resolver
        
        let buttonsDisabled = _processing
            .asObservable()
            .map { !$0 }
            .asDriver(onErrorJustReturn: false)
            .asObservable()
        newAnonymousUserEnabled = buttonsDisabled
        
        onNewAnonymousUser = _onNewAnonymousUser.asObserver()
        
        _onNewAnonymousUser.handler = { [weak self] _ in self?.handleNewAnonymousUser() }
    }
    
    private func handleNewAnonymousUser() {
        let userAccountRepository = _resolver.resolveUserAccountRepository()
        _processing.value = true
        userAccountRepository.signInAnonymously()
            .subscribe(onCompleted: {
                self._processing.value = false
            }, onError: { (error) in
                self._processing.value = false
                // TODO
            })
            .disposed(by: _disposeBag)
    }
}
