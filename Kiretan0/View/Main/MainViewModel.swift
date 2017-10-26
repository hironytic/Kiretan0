//
// MainViewModel.swift
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

public protocol MainViewModel: ViewModel {
    var title: Observable<String> { get }
    var segmentSelectedIndex: Observable<Int> { get }
    
    var onSetting: AnyObserver<Void> { get }
    var onSegmentSelectedIndexChange: AnyObserver<Int> { get }
    var onAdd: AnyObserver<Void> { get }
    
    // FIXME: Temporary Implementation
    var onSignOut: AnyObserver<Void> { get }
}

public protocol MainViewModelResolver {
    func resolveMainViewModel() -> MainViewModel
}

extension DefaultResolver: MainViewModelResolver {
    public func resolveMainViewModel() -> MainViewModel {
        return DefaultMainViewModel(resolver: self)
    }
}

public class DefaultMainViewModel: MainViewModel {
    public typealias Resolver = UserAccountRepositoryResolver

    public let title: Observable<String>
    public let segmentSelectedIndex: Observable<Int>
    public let onSetting: AnyObserver<Void>
    public let onSegmentSelectedIndexChange: AnyObserver<Int>
    public let onAdd: AnyObserver<Void>

    public let onSignOut: AnyObserver<Void>

    private let _resolver: Resolver
    private let _disposeBag = DisposeBag()
    private let _onSetting = ActionObserver<Void>()
    private let _onAdd = ActionObserver<Void>()
    private let _onSegmentSelectedIndexChange = ActionObserver<Int>()
    private let _onSignOut = ActionObserver<Void>()
    private let _segmentSelectedIndex = Variable<Int>(0)
    
    public init(resolver: Resolver) {
        _resolver = resolver
        
        title = Observable.just("Team Name")
        segmentSelectedIndex = _segmentSelectedIndex.asObservable()
        onSetting = _onSetting.asObserver()
        onSegmentSelectedIndexChange = _onSegmentSelectedIndexChange.asObserver()
        onAdd = _onAdd.asObserver()
        onSignOut = _onSignOut.asObserver()
        
        _onSetting.handler = { [weak self] _ in self?.handleSetting() }
        _onAdd.handler = { [weak self] _ in self?.handleAdd() }
        _onSegmentSelectedIndexChange.handler = { [weak self] index in self?.handleSegmentSelectedIndexChange(index) }
        _onSignOut.handler = { [weak self] _ in self?.handleSignOut() }
    }
    
    private func handleSetting() {
        print("setting")
    }
    
    private func handleSegmentSelectedIndexChange(_ index: Int) {
        print("segment selected index change - \(index)")
    }
    
    private func handleAdd() {
        print("add")
    }
    
    private func handleSignOut() {
        let userAccountRepository = _resolver.resolveUserAccountRepository()
        userAccountRepository.signOut()
            .subscribe(onCompleted: {
            
            }, onError: { (error) in
            })
            .disposed(by: _disposeBag)
    }
}
