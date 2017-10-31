//
// MainItemViewModel.swift
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
import RxCocoa

public protocol MainItemViewModel: ViewModel {
    var name: Observable<String> { get }
    var selected: Observable<Bool> { get }
}

public protocol MainItemViewModelResolver {
    func resolveMainItemViewModel() -> MainItemViewModel
}

extension DefaultResolver: MainItemViewModelResolver {
    public func resolveMainItemViewModel() -> MainItemViewModel {
        return DefaultMainItemViewModel(resolver: self)
    }
}

public class DefaultMainItemViewModel: MainItemViewModel {
    public typealias Resolver = NullResolver

    private let _resolver: Resolver

    public let name: Observable<String>
    public let selected: Observable<Bool>
    
    private let _selected = BehaviorRelay(value: false)
    
    public init(resolver: Resolver) {
        _resolver = resolver
        
        switch arc4random() % 3 {
        case 0:
            name = Observable.just("洗剤")
        case 1:
            name = Observable.just("シャンプー")
        case 2:
            name = Observable.just("トイレットペーパー（ダブル・無臭タイプ）")
        default:
            name = Observable.just("洗剤")
        }
        selected = _selected.asObservable().observeOn(MainScheduler.instance)
    }
}
