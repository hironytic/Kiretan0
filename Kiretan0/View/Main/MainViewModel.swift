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
    case selection0
    case selection1
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
    var displayMessage: Observable<DisplayMessage> { get }
    
    var onSetting: AnyObserver<Void> { get }
    var onSegmentSelectedIndexChange: AnyObserver<Int> { get }
    var onItemSelected: AnyObserver<IndexPath> { get }
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

private let TEAM_ID = "TEST_TEAM_ID"

public class DefaultMainViewModel: MainViewModel {
    public typealias Resolver = MainItemViewModelResolver & TextInputViewModelResolver & SettingViewModelResolver &
                                TeamRepositoryResolver & MainUserDefaultsRepositoryResolver & ItemRepositoryResolver

    public let title: Observable<String>
    public let segmentSelectedIndex: Observable<Int>
    public let itemList: Observable<MainViewItemList>
    public let itemListMessageText: Observable<String>
    public let itemListMessageHidden: Observable<Bool>
    public let mainViewToolbar: Observable<MainViewToolbar>
    public let displayMessage: Observable<DisplayMessage>
    
    public let onSetting: AnyObserver<Void>
    public let onSegmentSelectedIndexChange: AnyObserver<Int>
    public let onItemSelected: AnyObserver<IndexPath>
    public let onAdd: AnyObserver<Void>

    private let disposeBag: DisposeBag

    private class ItemState {
        let itemID: String
        let name: BehaviorRelay<String>
        let isSelected = BehaviorRelay<Bool>(value: false)

        init(itemID: String, name: String) {
            self.itemID = itemID
            self.name = BehaviorRelay(value: name)
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
    }

    public init(resolver: Resolver) {
        let disposeBag = DisposeBag()
        
        struct Subject {
            let onSegmentSelectedIndexChange = PublishSubject<Int>()
            let onItemSelected = PublishSubject<Int>()
            let onSetting = PublishSubject<Void>()
            let onAdd = PublishSubject<Void>()
            let onAddItem = PublishSubject<(String, Bool)>()
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
                for ix in change.deletions.reversed() {
                    states.remove(at: ix)
                    viewModels.remove(at: ix)
                }
                for ix in change.insertions {
                    let itemID = change.result[ix].itemID
                    let state = ItemState(itemID: itemID, name: change.result[ix].name)
                    states.insert(state, at: ix)

                    let name = state.name.distinctUntilChanged().asObservable()
                    let selected = state.isSelected.asObservable()
                    viewModels.insert(resolver.resolveMainItemViewModel(name: name, selected: selected), at: ix)
                }
                var movings = [(ItemState, MainItemViewModel, Int)]()
                for (oldIndex, newIndex) in change.modifications.sorted(by: { lhs, rhs in lhs.0 > rhs.0 }) {
                    let state = states.remove(at: oldIndex)
                    let itemViewModel = viewModels.remove(at: oldIndex)
                    movings.append((state, itemViewModel, newIndex))
                }
                for (state, itemViewModel, newIndex) in movings.sorted(by: { lhs, rhs in lhs.2 < rhs.2 }) {
                    states.insert(state, at: newIndex)
                    viewModels.insert(itemViewModel, at: newIndex)
                    state.name.accept(change.result[newIndex].name)
                }
                if acc.states.isEmpty {
                    hint = .whole
                } else {
                    hint = .partial(.init(deletedRows: change.deletions.map({ IndexPath(row: $0, section: 0) }),
                                          insertedRows: change.insertions.map({ IndexPath(row: $0, section: 0) }),
                                          movedRows: change.modifications.map({ (IndexPath(row: $0.0, section: 0), IndexPath(row: $0.1, section: 0)) })))
                }
            case .select(let index):
                states[index].isSelected.accept(!states[index].isSelected.value)
                hint = .nothing
            }

            return ItemListState(states: states, viewModels: viewModels, hint: hint)
        }
        
        func createDisplayMessageOfTextInputForAdding() -> Observable<DisplayMessage> {
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
                    
                    return DisplayMessage(viewModel: textInputViewModel, type: .present, animated: true)
                }
        }

        func createDisplayMessageOfSetting() -> Observable<DisplayMessage> {
            return subject.onSetting
                .map {
                    let settingViewModel = resolver.resolveSettingViewModel()
                    return DisplayMessage(viewModel: settingViewModel, type: .present, animated: true)
                }
        }
        
        func createDisplayMessage() -> Observable<DisplayMessage> {
            return Observable
                .merge([
                    createDisplayMessageOfTextInputForAdding(),
                    createDisplayMessageOfSetting(),
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
                    if itemListState.states.contains(where: { $0.isSelected.value }) {
                        if segmentSelectedIndex == 0 {
                            return .selection0
                        } else {
                            return .selection1
                        }
                    } else {
                        return .segment
                    }
                }
                .share(replay: 1, scope: .whileConnected)
                .observeOn(MainScheduler.instance)
        }
        
        func handleSegmentSelectedIndexChange() {
            subject.onSegmentSelectedIndexChange
                .subscribe(onNext: { index in
                    guard index >= 0 else { return }
                    
                    mainUserDefaultsRepository.setLastMainSegment(index)
                })
                .disposed(by: disposeBag)
        }
        
        func handleAddItem() {
            subject.onAddItem
                .subscribe(onNext: { (name, isInsufficient) in
                    let newItem = Item(name: name, isInsufficient: isInsufficient)
                    itemRepository.createItem(newItem, in: TEAM_ID)
                        .subscribe(onSuccess: { _ in }, onError: { _ in })  // TODO: handle error!
                        .disposed(by: disposeBag)
                })
                .disposed(by: disposeBag)
        }
        
        handleSegmentSelectedIndexChange()
        handleAddItem()
        
        // initialize stored properties
        title = createTitle()
        segmentSelectedIndex = createSegmentSelectedIndex()
        itemList = createItemList()
        itemListMessageText = createItemListMessageText()
        itemListMessageHidden = createItemListMessageHidden()
        mainViewToolbar = createMainViewToolbar()
        displayMessage = createDisplayMessage()

        onSetting = subject.onSetting.asObserver()
        onSegmentSelectedIndexChange = subject.onSegmentSelectedIndexChange.asObserver()
        onItemSelected = subject.onItemSelected.asObserver().mapObserver{ $0.row }
        onAdd = subject.onAdd.asObserver()
        
        self.disposeBag = disposeBag
    }
}

