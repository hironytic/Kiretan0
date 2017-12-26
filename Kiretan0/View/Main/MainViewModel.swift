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
import RxCocoa

public protocol MainViewModel: ViewModel {
    var title: Observable<String> { get }
    var segmentSelectedIndex: Observable<Int> { get }
    var itemList: Observable<[MainItemViewModel]> { get }
    var displayMessage: Observable<DisplayMessage> { get }
    
    var onSetting: AnyObserver<Void> { get }
    var onSegmentSelectedIndexChange: AnyObserver<Int> { get }
    var onAdd: AnyObserver<Void> { get }
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
    public typealias Resolver = MainUserDefaultsRepositoryResolver & MainItemViewModelResolver &
                                ItemRepositoryResolver & TextInputViewModelResolver & SettingViewModelResolver

    public let title: Observable<String>
    public let segmentSelectedIndex: Observable<Int>
    public let itemList: Observable<[MainItemViewModel]>
    public let displayMessage: Observable<DisplayMessage>
    public let onSetting: AnyObserver<Void>
    public let onSegmentSelectedIndexChange: AnyObserver<Int>
    public let onAdd: AnyObserver<Void>

    private let _resolver: Resolver
    private let _disposeBag = DisposeBag()
    private let _onSetting = ActionObserver<Void>()
    private let _onAdd = ActionObserver<Void>()
    private let _onSegmentSelectedIndexChange = ActionObserver<Int>()
    private let _onSignOut = ActionObserver<Void>()
    private let _segmentSelectedIndex: BehaviorRelay<Int>
    private var _itemSelectedStates: [BehaviorRelay<Bool>]
    private var _displayMessageSlot = PublishSubject<DisplayMessage>()
    
    public init(resolver: Resolver) {
        _resolver = resolver
        
        title = Observable.just("Team Name")
        _itemSelectedStates = [
            BehaviorRelay(value: false),
            BehaviorRelay(value: false),
            BehaviorRelay(value: false),
            BehaviorRelay(value: true),
            BehaviorRelay(value: false),
            BehaviorRelay(value: false),
            BehaviorRelay(value: false),
        ]
        itemList = Observable.just(_itemSelectedStates.map { state in
            let selected = state.asObservable()
            let onSelected = AnyObserver<Void>(eventHandler: { _ in
                state.accept(!state.value)
            })
            return resolver.resolveMainItemViewModel(selected: selected, onSelected: onSelected)
        })
        let segmentSelectedIndexRelay = BehaviorRelay(value: 0)
        _segmentSelectedIndex = segmentSelectedIndexRelay
        
        let mainUserDefaultsRepository = _resolver.resolveMainUserDefaultsRepository()
        mainUserDefaultsRepository.lastMainSegment
            .subscribe(onNext: { segmentSelectedIndexRelay.accept($0) })
            .disposed(by: _disposeBag)
        segmentSelectedIndex = _segmentSelectedIndex.observeOn(MainScheduler.instance)
        
        displayMessage = _displayMessageSlot.observeOn(MainScheduler.instance)
        onSetting = _onSetting.asObserver()
        onSegmentSelectedIndexChange = _onSegmentSelectedIndexChange.asObserver()
        onAdd = _onAdd.asObserver()
        
        _onSetting.handler = { [weak self] _ in self?.handleSetting() }
        _onAdd.handler = { [weak self] _ in self?.handleAdd() }
        _onSegmentSelectedIndexChange.handler = { [weak self] index in self?.handleSegmentSelectedIndexChange(index) }
    }
    
    private func handleSetting() {
        let settingViewModel = _resolver.resolveSettingViewModel()
        _displayMessageSlot.onNext(DisplayMessage(viewModel: settingViewModel, type: .present, animated: true))
    }
    
    private func handleSegmentSelectedIndexChange(_ index: Int) {
        let mainUserDefaultsRepository = _resolver.resolveMainUserDefaultsRepository()
        mainUserDefaultsRepository.setLastMainSegment(index)
    }
    
    private func handleAdd() {
        let title: String
        switch _segmentSelectedIndex.value {
        case 0:
            title = "まだあるものを登録"
        case 1:
            title = "切らしてるものを登録"
        default:
            fatalError()
        }
        
        let onDone = ActionObserver<String> { [weak self] name in self?.handleAddItem(name) }
        let onCancel = AnyObserver<Void> { _ in }
        let textInputViewModel = _resolver.resolveTextInputViewModel(
            title: title,
            detailMessage: nil,
            placeholder: "",
            initialText: "",
            cancelButtonTitle: "キャンセル",
            doneButtonTitle: "作成",
            onDone: onDone.asObserver(),
            onCancel: onCancel)
        _displayMessageSlot.onNext(DisplayMessage(viewModel: textInputViewModel, type: .present, animated: true))
    }
    
    private func handleAddItem(_ name: String) {
        print("add \(name)")
    }
}
