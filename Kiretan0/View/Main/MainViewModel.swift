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

public enum MainViewToolbar {
    case segment
    case checked0
    case checked1
}

public struct MainViewItemList {
    public let viewModels: [MainItemViewModel]
    public let hint: TableViewUpdateHint
}

public protocol MainViewModel: ViewModel {
    var title: Observable<String> { get }
    var segmentSelectedIndex: Observable<Int> { get }
    var itemList: Observable<MainViewItemList> { get }
    var itemListMessageText: Observable<String> { get }
    var itemListMessageHidden: Observable<Bool> { get }
    var mainViewToolbar: Observable<MainViewToolbar> { get }
    var displayRequest: Observable<DisplayRequest> { get }
    
    var onSetting: AnyObserver<Void> { get }
    var onSegmentSelectedIndexChange: AnyObserver<Int> { get }
    var onItemSelected: AnyObserver<IndexPath> { get }
    var onAdd: AnyObserver<Void> { get }
    var onUncheckAllItems: AnyObserver<Void> { get }
    var onMakeInsufficient: AnyObserver<Void> { get }
    var onMakeSufficient: AnyObserver<Void> { get }
}

public protocol MainViewModelResolver {
    func resolveMainViewModel() -> MainViewModel
}

extension DefaultResolver: MainViewModelResolver {
    public func resolveMainViewModel() -> MainViewModel {
        return DefaultMainViewModel(resolver: self)
    }
}

private let TEAM_ID = Config.bundled.teamID

public class DefaultMainViewModel: MainViewModel {
    public typealias Resolver = MainItemViewModelResolver & TextInputViewModelResolver & SettingViewModelResolver &
                                TeamRepositoryResolver & MainUserDefaultsRepositoryResolver & ItemRepositoryResolver

    public let title: Observable<String>
    public let segmentSelectedIndex: Observable<Int>
    public let itemList: Observable<MainViewItemList>
    public let itemListMessageText: Observable<String>
    public let itemListMessageHidden: Observable<Bool>
    public let mainViewToolbar: Observable<MainViewToolbar>
    public let displayRequest: Observable<DisplayRequest>
    
    public let onSetting: AnyObserver<Void>
    public let onSegmentSelectedIndexChange: AnyObserver<Int>
    public let onItemSelected: AnyObserver<IndexPath>
    public let onAdd: AnyObserver<Void>
    public let onUncheckAllItems: AnyObserver<Void>
    public let onMakeInsufficient: AnyObserver<Void>
    public let onMakeSufficient: AnyObserver<Void>

    private let disposeBag: DisposeBag

    private class ItemState {
        var item: Item {
            didSet {
                name.accept(ItemState.name(of: item))
                if item.error != nil && isChecked.value {
                    isChecked.accept(false)
                }
            }
        }
        let name: BehaviorRelay<String>
        let isChecked = BehaviorRelay<Bool>(value: false)

        init(item: Item) {
            self.item = item
            self.name = BehaviorRelay(value: ItemState.name(of: item))
        }
        
        private static func name(of item: Item) -> String {
            if item.error == nil {
                return item.name
            } else {
                return R.String.errorItem.localized()
            }
        }
    }

    private struct ItemListState {
        let states: [ItemState]
        let viewModels: [MainItemViewModel]
        let hint: TableViewUpdateHint
        let error: Error?
        
        public init(states: [ItemState], viewModels: [MainItemViewModel], hint: TableViewUpdateHint, error: Error? = nil) {
            self.states = states
            self.viewModels = viewModels
            self.hint = hint
            self.error = error
        }
    }

    private enum ItemStateAction {
        case change(CollectionChange<Item>)
        case select(Int)
        case uncheckAll
    }
    
    public init(resolver: Resolver) {
        let disposeBag = DisposeBag()
        
        struct Subject {
            let onSegmentSelectedIndexChange = PublishSubject<Int>()
            let onItemSelected = PublishSubject<Int>()
            let onSetting = PublishSubject<Void>()
            let onAdd = PublishSubject<Void>()
            let onAddItem = PublishSubject<(String, Bool)>()
            let onUncheckAllItems = PublishSubject<Void>()
            let onChangeInsufficiency = PublishSubject<Bool>()
        }
        let subject = Subject()
        
        let teamRepository = resolver.resolveTeamRepository()
        let mainUserDefaultsRepository = resolver.resolveMainUserDefaultsRepository()
        let itemRepository = resolver.resolveItemRepository()

        let lastMainSegment = mainUserDefaultsRepository
            .lastMainSegment
            .share(replay: 1, scope: .whileConnected)

        func createTitle() -> Observable<String> {
            return teamRepository
                .team(for: TEAM_ID)
                .map { team in
                    team?.name ?? ""
                }
                .share(replay: 1, scope: .whileConnected)
                .observeOn(MainScheduler.instance)
        }

        func createSegmentSelectedIndex() -> Observable<Int> {
            return lastMainSegment
                .observeOn(MainScheduler.instance)
        }
        
        func createItemListState() -> Observable<ItemListState> {
            return lastMainSegment
                .flatMapLatest { (segment: Int) -> Observable<ItemListState> in
                    let initialState = ItemListState(states: [], viewModels: [], hint: .whole)
                    let items = itemRepository.items(in: TEAM_ID, insufficient: segment == 1)
                    return Observable
                        .merge([
                            items.map { ItemStateAction.change($0) },
                            subject.onItemSelected.map { ItemStateAction.select($0) },
                            subject.onUncheckAllItems.map { ItemStateAction.uncheckAll },
                        ])
                        .scan(initialState, accumulator: itemListStateReducer)
                        .catchError { Observable.just(ItemListState(states: [], viewModels: [], hint: .whole, error: $0)) }
                        .startWith(initialState)
                }
                .share(replay: 1, scope: .whileConnected)
        }
        
        func itemListStateReducer(_ acc: ItemListState, _ action: ItemStateAction) -> ItemListState {
            var states = acc.states
            var viewModels = acc.viewModels
            let hint: TableViewUpdateHint

            switch action {
            case .change(let change):
                for event in change.events {
                    switch event {
                    case .inserted(let ix, let entity):
                        let state = ItemState(item: entity)
                        states.insert(state, at: ix)
                        
                        let name = state.name.distinctUntilChanged().asObservable()
                        let isChecked = state.isChecked.asObservable()
                        viewModels.insert(resolver.resolveMainItemViewModel(name: name, isChecked: isChecked), at: ix)
                    case .deleted(let ix):
                        states.remove(at: ix)
                        viewModels.remove(at: ix)
                    case .moved(let oldIndex, let newIndex, let entity):
                        let state = states.remove(at: oldIndex)
                        state.item = entity
                        states.insert(state, at: newIndex)
                        viewModels.insert(viewModels.remove(at: oldIndex), at: newIndex)
                    }
                }
                
                if acc.states.isEmpty {
                    hint = .whole
                } else {
                    hint = .partial(change.updateHintDifference())
                }
            case .select(let index):
                if states[index].item.error == nil {
                    states[index].isChecked.accept(!states[index].isChecked.value)
                }
                hint = .none
            
            case .uncheckAll:
                for s in states {
                    if s.isChecked.value {
                        s.isChecked.accept(false)
                    }
                }
                hint = .none
            }

            return ItemListState(states: states, viewModels: viewModels, hint: hint)
        }
        
        func createDisplayRequestOfTextInputForAdding() -> Observable<DisplayRequest> {
            return subject.onAdd
                .withLatestFrom(lastMainSegment)
                .map { segmentIndex in
                    let title: String
                    let isInsufficient: Bool
                    switch segmentIndex {
                    case 0:
                        title = R.String.addSufficientItem.localized()
                        isInsufficient = false
                    case 1:
                        title = R.String.addInsufficientItem.localized()
                        isInsufficient = true
                    default:
                        fatalError()
                    }

                    let onDone = ActionObserver.asObserver { title in subject.onAddItem.onNext((title, isInsufficient)) }
                    let onCancel = ActionObserver.asObserver { }
                    let textInputViewModel = resolver.resolveTextInputViewModel(
                        title: title,
                        detailMessage: nil,
                        placeholder: "",
                        initialText: "",
                        cancelButtonTitle: R.String.cancel.localized(),
                        doneButtonTitle: R.String.doAddItem.localized(),
                        onDone: onDone,
                        onCancel: onCancel)
                    
                    return DisplayRequest(viewModel: textInputViewModel, type: .present, animated: true)
                }
        }

        func createDisplayRequestOfSetting() -> Observable<DisplayRequest> {
            return subject.onSetting
                .map {
                    let settingViewModel = resolver.resolveSettingViewModel()
                    return DisplayRequest(viewModel: settingViewModel, type: .present, animated: true)
                }
        }
        
        func createDisplayRequest() -> Observable<DisplayRequest> {
            return Observable
                .merge([
                    createDisplayRequestOfTextInputForAdding(),
                    createDisplayRequestOfSetting(),
                ])
                .share(replay: 1, scope: .whileConnected)
                .observeOn(MainScheduler.instance)
        }

        let itemListState = createItemListState()
        
        func createItemList() -> Observable<MainViewItemList> {
            return itemListState
                .map { MainViewItemList(viewModels: $0.viewModels, hint: $0.hint) }
                .observeOn(MainScheduler.instance)
        }
        
        func createItemListMessageText() -> Observable<String> {
            return itemListState
                .map { state in
                    if let _ /*error*/ = state.error {
                        return R.String.errorItemList.localized()
                    } else {
                        return ""
                    }
                }
                .observeOn(MainScheduler.instance)
        }
        
        func createItemListMessageHidden() -> Observable<Bool> {
            return itemListState
                .map { $0.error == nil }
                .observeOn(MainScheduler.instance)
        }

        func createMainViewToolbar() -> Observable<MainViewToolbar> {
            return Observable
                .combineLatest(itemListState, lastMainSegment)
                .map { (itemListState, segmentSelectedIndex) in
                    if itemListState.states.contains(where: { $0.isChecked.value }) {
                        if segmentSelectedIndex == 0 {
                            return .checked0
                        } else {
                            return .checked1
                        }
                    } else {
                        return .segment
                    }
                }
                .share(replay: 1, scope: .whileConnected)
                .observeOn(MainScheduler.instance)
        }
        
        func handleSegmentSelectedIndexChange() -> Observable<Void> {
            return subject.onSegmentSelectedIndexChange
                .map { index in
                    guard index >= 0 else { return }
                    
                    mainUserDefaultsRepository.setLastMainSegment(index)
                }
        }
        
        func handleAddItem() -> Observable<String> {
            return subject.onAddItem
                .flatMapLatest { (name, isInsufficient) -> Observable<String> in
                    let newItem = Item(name: name, isInsufficient: isInsufficient)
                    return itemRepository.createItem(newItem, in: TEAM_ID).asObservable()
                }
            // TODO: handle error case
        }
        
        func handleMakeInsufficient() -> Observable<Void> {
            return subject.onChangeInsufficiency
                .withLatestFrom(itemListState) { ($0, $1) }
                .flatMapLatest { (isInsufficient, ils) -> Observable<Void> in
                    let completables = ils.states
                        .filter { $0.isChecked.value }
                        .map { state -> Completable in
                            var item = state.item
                            item.isInsufficient = isInsufficient
                            return itemRepository.updateItem(item, in: TEAM_ID)
                        }
                    return Completable.merge(completables)
                        .andThen(Observable<Void>.just(()))
                    // TODO: handle each error case
                }
        }
        
        handleSegmentSelectedIndexChange().publish().connect().disposed(by: disposeBag)
        handleAddItem().publish().connect().disposed(by: disposeBag)
        handleMakeInsufficient().publish().connect().disposed(by: disposeBag)
        
        // initialize stored properties
        title = createTitle()
        segmentSelectedIndex = createSegmentSelectedIndex()
        itemList = createItemList()
        itemListMessageText = createItemListMessageText()
        itemListMessageHidden = createItemListMessageHidden()
        mainViewToolbar = createMainViewToolbar()
        displayRequest = createDisplayRequest()

        onSetting = subject.onSetting.asObserver()
        onSegmentSelectedIndexChange = subject.onSegmentSelectedIndexChange.asObserver()
        onItemSelected = subject.onItemSelected.asObserver().mapObserver { $0.row }
        onAdd = subject.onAdd.asObserver()
        onUncheckAllItems = subject.onUncheckAllItems.asObserver()
        onMakeInsufficient = subject.onChangeInsufficiency.asObserver().mapObserver { true }
        onMakeSufficient = subject.onChangeInsufficiency.asObserver().mapObserver { false }
        
        self.disposeBag = disposeBag
    }
}

