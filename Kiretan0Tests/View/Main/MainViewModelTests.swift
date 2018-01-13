//
// MainViewModelTests.swift
// Kiretan0Tests
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

import XCTest
import RxSwift
@testable import Kiretan0

private let TEAM_ID = Config.bundled.teamID

class MainViewModelTests: XCTestCase {
    var disposeBag: DisposeBag!
    var resolver: MockResolver!

    class NullSettingViewModel: SettingViewModel {
        let displayRequest = Observable<DisplayRequest>.never()
        var dismissalRequest = Observable<DismissalRequest>.never()
        var tableData = Observable<[TableSectionViewModel]>.never()
        
        let onDone = ActionObserver<Void>().asObserver()
    }
    
    class MockResolver: DefaultMainViewModel.Resolver, NullResolver {
        let itemRepository = MockItemRepository()
        let mainUserDefaultsRepository = MockMainUserDefaultsRepository()
        let teamRepository = MockTeamRepository()

        init() {
        }

        func resolveMainItemViewModel(name: Observable<String>, isChecked: Observable<Bool>) -> MainItemViewModel {
            return DefaultMainItemViewModel(resolver: self, name: name, isChecked: isChecked)
        }
        
        func resolveSettingViewModel() -> SettingViewModel {
            return NullSettingViewModel()
        }
        
        func resolveTextInputViewModel(title: String?, detailMessage: String?, placeholder: String?, initialText: String, cancelButtonTitle: String, doneButtonTitle: String, onDone: AnyObserver<String>, onCancel: AnyObserver<Void>) -> TextInputViewModel {
            return DefaultTextInputViewModel(resolver: self, title: title, detailMessage: detailMessage, placeholder: placeholder, initialText: initialText, cancelButtonTitle: cancelButtonTitle, doneButtonTitle: doneButtonTitle, onDone: onDone, onCancel: onCancel)
        }

        func resolveItemRepository() -> ItemRepository {
            return itemRepository
        }

        func resolveMainUserDefaultsRepository() -> MainUserDefaultsRepository {
            return mainUserDefaultsRepository
        }
        
        func resolveTeamRepository() -> TeamRepository {
            return teamRepository
        }
    }

    override func setUp() {
        super.setUp()

        continueAfterFailure = false
        disposeBag = DisposeBag()
        resolver = MockResolver()
        
        resolver.teamRepository.mock.team.setup { teamID in
            XCTAssertEqual(teamID, TEAM_ID)
            return Observable.just(Team(teamID: TEAM_ID, name: "My Team"))
        }
        
        let segment = BehaviorSubject(value: 0)
        resolver.mainUserDefaultsRepository.mock.lastMainSegment.setup { segment }
        resolver.mainUserDefaultsRepository.mock.setLastMainSegment.setup { index in
            segment.onNext(index)
        }
        
        resolver.itemRepository.mock.items.setup { (teamID, insufficient) in
            XCTAssertEqual(teamID, TEAM_ID)
            return Observable.just(CollectionChange(result: [], deletions: [], insertions: [], modifications: []))
        }
    }
    
    override func tearDown() {
        disposeBag = nil
        resolver = nil

        super.tearDown()
    }

    // MARK: - normal scinarios
    
    func testTitle() {
        let viewModel: MainViewModel = DefaultMainViewModel(resolver: resolver)
        let expect = expectation(description: "title")
        let observer = EventuallyFulfill(expect) { (title: String) in
            if title == "My Team" {
                return true
            }
            return false
        }
        viewModel.title
            .bind(to: observer)
            .disposed(by: disposeBag)
        
        wait(for: [expect], timeout: 3.0)
    }
    
    func testSegment() {
        let viewModel: MainViewModel = DefaultMainViewModel(resolver: resolver)

        let expect1 = expectation(description: "segment 0 is selected")
        let segmentSelectedIndexObserver = EventuallyFulfill(expect1) { (index: Int) in
            return index == 0
        }
        
        viewModel.segmentSelectedIndex
            .bind(to: segmentSelectedIndexObserver)
            .disposed(by: disposeBag)
        
        wait(for: [expect1], timeout: 3.0)
        
        let expect2 = expectation(description: "segument 1 is selected")
        segmentSelectedIndexObserver.reset(expect2) { (index: Int) in
            return index == 1
        }
        
        viewModel.onSegmentSelectedIndexChange.onNext(1)
        wait(for: [expect2], timeout: 3.0)
    }
    
    func testInitialItemList() {
        resolver.itemRepository.mock.items.setup { (teamID, insufficient) in
            XCTAssertEqual(teamID, TEAM_ID)
            XCTAssertEqual(insufficient, false)
            
            return Observable.just(CollectionChange(result: [
                Item(itemID: "item0", name: "Item 0", isInsufficient: false, lastChange: TestUtils.makeDate(2017, 7, 10, 17, 00, 00)),
                Item(itemID: "item1", name: "Item 1", isInsufficient: false, lastChange: TestUtils.makeDate(2017, 9, 10, 14, 30, 20)),
            ], deletions: [], insertions: [0, 1], modifications: []))
        }
        
        let viewModel: MainViewModel = DefaultMainViewModel(resolver: resolver)

        var itemVM0Opt: MainItemViewModel?
        var itemVM1Opt: MainItemViewModel?
        
        let expect = expectation(description: "items")
        let observer = EventuallyFulfill(expect) { (list: MainViewItemList) in
            guard list.viewModels.count == 2 else { return false }
            itemVM0Opt = list.viewModels[0]
            itemVM1Opt = list.viewModels[1]
            return true
        }
        
        viewModel.itemList
            .bind(to: observer)
            .disposed(by: disposeBag)
        wait(for: [expect], timeout: 3.0)
        guard let itemVM0 = itemVM0Opt else { return }
        guard let itemVM1 = itemVM1Opt else { return }

        let nameExpect0 = expectation(description: "name 0")
        let name0Observer = EventuallyFulfill(nameExpect0) { (name: String) in
            return name == "Item 0"
        }
        itemVM0.name
            .bind(to: name0Observer)
            .disposed(by: disposeBag)
        
        let nameExpect1 = expectation(description: "name 1")
        let name1Observer = EventuallyFulfill(nameExpect1) { (name: String) in
            return name == "Item 1"
        }
        itemVM1.name
            .bind(to: name1Observer)
            .disposed(by: disposeBag)

        wait(for: [nameExpect0, nameExpect1], timeout: 3.0)
    }
    
    func testItemListChangedBySelectingSegmentControl() {
        resolver.itemRepository.mock.items.setup { (teamID, insufficient) in
            if (!insufficient) {
                return Observable.just(CollectionChange(result: [
                    Item(itemID: "item0", name: "Item 0", isInsufficient: false, lastChange: TestUtils.makeDate(2017, 7, 10, 17, 00, 00)),
                    Item(itemID: "item1", name: "Item 1", isInsufficient: false, lastChange: TestUtils.makeDate(2017, 9, 10, 14, 30, 20)),
                ], deletions: [], insertions: [0, 1], modifications: []))
            } else {
                return Observable.just(CollectionChange(result: [
                    Item(itemID: "item2", name: "Item 2", isInsufficient: true, lastChange: TestUtils.makeDate(2017, 11, 20, 3, 40, 50)),
                    Item(itemID: "item3", name: "Item 3", isInsufficient: true, lastChange: TestUtils.makeDate(2017, 12, 31, 20, 11, 22)),
                    Item(itemID: "item4", name: "Item 4", isInsufficient: true, lastChange: TestUtils.makeDate(2018, 1, 1, 9, 00, 00)),
                ], deletions: [], insertions: [0, 1, 2], modifications: []))
            }
        }

        let viewModel: MainViewModel = DefaultMainViewModel(resolver: resolver)
        
        let expectSufficient = expectation(description: "sufficient items")
        let observer = EventuallyFulfill(expectSufficient) { (list: MainViewItemList) in
            return list.viewModels.count == 2
        }
        
        viewModel.itemList
            .bind(to: observer)
            .disposed(by: disposeBag)

        wait(for: [expectSufficient], timeout: 3.0)

        var itemVM0Opt: MainItemViewModel?

        let expectInsufficient = expectation(description: "insufficient items")
        observer.reset(expectInsufficient) { (list: MainViewItemList) in
            guard list.viewModels.count == 3 else { return false }
            itemVM0Opt = list.viewModels[0]
            return true
        }
        
        viewModel.onSegmentSelectedIndexChange.onNext(1)

        wait(for: [expectInsufficient], timeout: 3.0)
        guard let itemVM0 = itemVM0Opt else { return }

        let nameExpect0 = expectation(description: "name 0")
        let name0Observer = EventuallyFulfill(nameExpect0) { (name: String) in
            return name == "Item 2"
        }
        itemVM0.name
            .bind(to: name0Observer)
            .disposed(by: disposeBag)

        wait(for: [nameExpect0], timeout: 3.0)
    }
    
    func testItemListChangedByInsertion() {
        let itemsSubject = PublishSubject<CollectionChange<Item>>()
        resolver.itemRepository.mock.items.setup { (teamID, insufficient) in
            return itemsSubject
        }

        let viewModel: MainViewModel = DefaultMainViewModel(resolver: resolver)
        
        let expectItems = expectation(description: "items")
        let observer = EventuallyFulfill(expectItems) { (list: MainViewItemList) in
            return list.viewModels.count == 2
        }
        
        viewModel.itemList
            .bind(to: observer)
            .disposed(by: disposeBag)

        itemsSubject.onNext(CollectionChange(result: [
            Item(itemID: "item0", name: "Item 0", isInsufficient: false, lastChange: TestUtils.makeDate(2017, 7, 10, 17, 00, 00)),
            Item(itemID: "item1", name: "Item 1", isInsufficient: false, lastChange: TestUtils.makeDate(2017, 9, 10, 14, 30, 20)),
        ], deletions: [], insertions: [0, 1], modifications: []))
        
        wait(for: [expectItems], timeout: 3.0)
        
        var itemVM1Opt: MainItemViewModel?
        
        let expectItemInserted = expectation(description: "item is inserted")
        observer.reset(expectItemInserted) { (list: MainViewItemList) in
            guard list.viewModels.count == 3 else { return false }
            itemVM1Opt = list.viewModels[1]
            return true
        }

        itemsSubject.onNext(CollectionChange(result: [
            Item(itemID: "item0", name: "Item 0", isInsufficient: false, lastChange: TestUtils.makeDate(2017, 7, 10, 17, 00, 00)),
            Item(itemID: "itemN", name: "New Item", isInsufficient: false, lastChange: TestUtils.makeDate(2017, 8, 23, 10, 20, 40)),
            Item(itemID: "item1", name: "Item 1", isInsufficient: false, lastChange: TestUtils.makeDate(2017, 9, 10, 14, 30, 20)),
        ], deletions: [], insertions: [1], modifications: []))
        
        wait(for: [expectItemInserted], timeout: 3.0)
        guard let itemVM1 = itemVM1Opt else { return }
        
        let nameExpect1 = expectation(description: "name 1")
        let name1Observer = EventuallyFulfill(nameExpect1) { (name: String) in
            return name == "New Item"
        }
        itemVM1.name
            .bind(to: name1Observer)
            .disposed(by: disposeBag)
        
        wait(for: [nameExpect1], timeout: 3.0)
    }
    
    func testItemListChangedByDeletion() {
        let itemsSubject = PublishSubject<CollectionChange<Item>>()
        resolver.itemRepository.mock.items.setup { (teamID, insufficient) in
            return itemsSubject
        }
        
        let viewModel: MainViewModel = DefaultMainViewModel(resolver: resolver)
        
        let expectItems = expectation(description: "items")
        let observer = EventuallyFulfill(expectItems) { (list: MainViewItemList) in
            return list.viewModels.count == 2
        }
        
        viewModel.itemList
            .bind(to: observer)
            .disposed(by: disposeBag)
        
        itemsSubject.onNext(CollectionChange(result: [
            Item(itemID: "item0", name: "Item 0", isInsufficient: false, lastChange: TestUtils.makeDate(2017, 7, 10, 17, 00, 00)),
            Item(itemID: "item1", name: "Item 1", isInsufficient: false, lastChange: TestUtils.makeDate(2017, 9, 10, 14, 30, 20)),
        ], deletions: [], insertions: [0, 1], modifications: []))
        
        wait(for: [expectItems], timeout: 3.0)
        
        var itemVM0Opt: MainItemViewModel?

        let expectItemDeleted = expectation(description: "item is deleted")
        observer.reset(expectItemDeleted) { (list: MainViewItemList) in
            guard list.viewModels.count == 1 else { return false }
            itemVM0Opt = list.viewModels[0]
            return true
        }
        
        itemsSubject.onNext(CollectionChange(result: [
            Item(itemID: "item1", name: "Item 1", isInsufficient: false, lastChange: TestUtils.makeDate(2017, 9, 10, 14, 30, 20)),
        ], deletions: [0], insertions: [], modifications: []))
        
        wait(for: [expectItemDeleted], timeout: 3.0)
        guard let itemVM0 = itemVM0Opt else { return }
        
        let nameExpect0 = expectation(description: "name 0")
        let name0Observer = EventuallyFulfill(nameExpect0) { (name: String) in
            return name == "Item 1"
        }
        itemVM0.name
            .bind(to: name0Observer)
            .disposed(by: disposeBag)
        
        wait(for: [nameExpect0], timeout: 3.0)
    }

    func testItemListChangedByReordering() {
        let itemsSubject = PublishSubject<CollectionChange<Item>>()
        resolver.itemRepository.mock.items.setup { (teamID, insufficient) in
            return itemsSubject
        }

        let viewModel: MainViewModel = DefaultMainViewModel(resolver: resolver)
        
        let expectItems = expectation(description: "items")
        let observer = EventuallyFulfill(expectItems) { (list: MainViewItemList) in
            return list.viewModels.count == 3
        }
        
        viewModel.itemList
            .bind(to: observer)
            .disposed(by: disposeBag)

        itemsSubject.onNext(CollectionChange(result: [
            Item(itemID: "item0", name: "Item 0", isInsufficient: false, lastChange: TestUtils.makeDate(2017, 7, 10, 17, 00, 00)),
            Item(itemID: "item1", name: "Item 1", isInsufficient: false, lastChange: TestUtils.makeDate(2017, 9, 10, 14, 30, 20)),
            Item(itemID: "item2", name: "Item 2", isInsufficient: false, lastChange: TestUtils.makeDate(2017, 11, 10, 8, 10, 05)),
        ], deletions: [], insertions: [0, 1, 2], modifications: []))
        
        wait(for: [expectItems], timeout: 3.0)
        
        var itemVM1Opt: MainItemViewModel?
        
        let expectItemReordered = expectation(description: "item is inserted")
        observer.reset(expectItemReordered) { (list: MainViewItemList) in
            guard list.viewModels.count == 3 else { return false }
            itemVM1Opt = list.viewModels[1]
            return true
        }

        itemsSubject.onNext(CollectionChange(result: [
            Item(itemID: "item1", name: "Item 1", isInsufficient: false, lastChange: TestUtils.makeDate(2017, 9, 10, 14, 30, 20)),
            Item(itemID: "item2", name: "Item 2", isInsufficient: false, lastChange: TestUtils.makeDate(2017, 11, 10, 8, 10, 05)),
            Item(itemID: "item0", name: "Item 0", isInsufficient: false, lastChange: TestUtils.makeDate(2018, 1, 3, 16, 20, 00)),
        ], deletions: [], insertions: [], modifications: [(0, 2)]))
        
        wait(for: [expectItemReordered], timeout: 3.0)
        guard let itemVM1 = itemVM1Opt else { return }
        
        let nameExpect1 = expectation(description: "name 1")
        let name1Observer = EventuallyFulfill(nameExpect1) { (name: String) in
            return name == "Item 2"
        }
        itemVM1.name
            .bind(to: name1Observer)
            .disposed(by: disposeBag)
        
        wait(for: [nameExpect1], timeout: 3.0)
    }
    
    func testToolbarChangedBySelection() {
        resolver.itemRepository.mock.items.setup { (teamID, insufficient) in
            if (!insufficient) {
                return Observable.just(CollectionChange(result: [
                    Item(itemID: "item0", name: "Item 0", isInsufficient: false, lastChange: TestUtils.makeDate(2017, 7, 10, 17, 00, 00)),
                    Item(itemID: "item1", name: "Item 1", isInsufficient: false, lastChange: TestUtils.makeDate(2017, 9, 10, 14, 30, 20)),
                ], deletions: [], insertions: [0, 1], modifications: []))
            } else {
                return Observable.just(CollectionChange(result: [
                    Item(itemID: "item2", name: "Item 2", isInsufficient: true, lastChange: TestUtils.makeDate(2017, 11, 20, 3, 40, 50)),
                    Item(itemID: "item3", name: "Item 3", isInsufficient: true, lastChange: TestUtils.makeDate(2017, 12, 31, 20, 11, 22)),
                    Item(itemID: "item4", name: "Item 4", isInsufficient: true, lastChange: TestUtils.makeDate(2018, 1, 1, 9, 00, 00)),
                ], deletions: [], insertions: [0, 1, 2], modifications: []))
            }
        }
        
        let viewModel: MainViewModel = DefaultMainViewModel(resolver: resolver)
        
        let expectSegmentToolbar = expectation(description: "segment toolbar")
        let observer = EventuallyFulfill(expectSegmentToolbar) { (toolbar: MainViewToolbar) in
            return toolbar == .segment
        }

        viewModel.mainViewToolbar
            .bind(to: observer)
            .disposed(by: disposeBag)
        
        wait(for: [expectSegmentToolbar], timeout: 3.0)
        
        
        let expectSufficientSelectionToolbar = expectation(description: "sufficient selection toolbar")
        observer.reset(expectSufficientSelectionToolbar) { (toolbar: MainViewToolbar) in
            return toolbar == .checked0
        }
        
        // change segment to sufficient items
        viewModel.onSegmentSelectedIndexChange.onNext(0)
        
        // select first item
        viewModel.onItemSelected.onNext(IndexPath(row: 0, section: 0))
        wait(for: [expectSufficientSelectionToolbar], timeout: 3.0)

        let expectInsufficientSelectionToolbar = expectation(description: "insufficient selection toolbar")
        observer.reset(expectInsufficientSelectionToolbar) { (toolbar: MainViewToolbar) in
            return toolbar == .checked1
        }

        // change segment to insufficient items
        viewModel.onSegmentSelectedIndexChange.onNext(1)
        
        // select first item
        viewModel.onItemSelected.onNext(IndexPath(row: 0, section: 0))
        wait(for: [expectInsufficientSelectionToolbar], timeout: 3.0)

        let expectSegmentToolbarAgain = expectation(description: "segment toolbar again")
        observer.reset(expectSegmentToolbarAgain) { (toolbar: MainViewToolbar) in
            return toolbar == .segment
        }
        
        // deselect first item
        viewModel.onItemSelected.onNext(IndexPath(row: 0, section: 0))
        wait(for: [expectSegmentToolbarAgain], timeout: 3.0)
    }
    
    func testUncheckAllItems() {
        resolver.itemRepository.mock.items.setup { (teamID, insufficient) in
            return Observable.just(CollectionChange(result: [
                Item(itemID: "item0", name: "Item 0", isInsufficient: false, lastChange: TestUtils.makeDate(2017, 7, 10, 17, 00, 00)),
                Item(itemID: "item1", name: "Item 1", isInsufficient: false, lastChange: TestUtils.makeDate(2017, 9, 10, 14, 30, 20)),
                Item(itemID: "item2", name: "Item 2", isInsufficient: true, lastChange: TestUtils.makeDate(2017, 11, 20, 3, 40, 50)),
                Item(itemID: "item3", name: "Item 3", isInsufficient: true, lastChange: TestUtils.makeDate(2017, 12, 31, 20, 11, 22)),
                ], deletions: [], insertions: [0, 1, 2, 3], modifications: []))
        }
        
        let viewModel: MainViewModel = DefaultMainViewModel(resolver: resolver)
        let expectNoItemsAreChecked = expectation(description: "No items are checked")
        let observer = EventuallyFulfill(expectNoItemsAreChecked) { (checkList: [Bool]) in
            guard checkList.count == 4 else { return false }
            return !checkList.contains(true)
        }

        viewModel.itemList
            .flatMapLatest { itemList -> Observable<[Bool]> in
                let isCheckedList = itemList.viewModels.map { $0.isChecked }
                return Observable.combineLatest(isCheckedList) { $0 }
            }
            .bind(to: observer)
            .disposed(by: disposeBag)
        
        wait(for: [expectNoItemsAreChecked], timeout: 3.0)

        // select row 0 and row 2
        let expectTwoItemsAreChecked = expectation(description: "Row 0 and row 2 are checked")
        observer.reset(expectTwoItemsAreChecked) { (checkList: [Bool]) in
            guard checkList.count == 4 else { return false }
            return checkList[0] && !checkList[1] && checkList[2] && !checkList[3]
        }
        viewModel.onItemSelected.onNext(IndexPath(row: 0, section: 0))
        viewModel.onItemSelected.onNext(IndexPath(row: 2, section: 0))
        wait(for: [expectTwoItemsAreChecked], timeout: 3.0)
        
        // uncheck all
        let expectNoItemsAreCheckedAnymore = expectation(description: "No items are checked anymore")
        observer.reset(expectNoItemsAreCheckedAnymore) { (checkList: [Bool]) in
            guard checkList.count == 4 else { return false }
            return !checkList.contains(true)
        }
        viewModel.onUncheckAllItems.onNext(())
        wait(for: [expectNoItemsAreCheckedAnymore], timeout: 3.0)
    }
    
    // MARK: - error handling scinarios
    
    func testItemListError() {
        enum TestError: Error { case error }
        
        resolver.itemRepository.mock.items.setup { teamID, insufficient in
            if (!insufficient) {
                return Observable.just(CollectionChange(result: [
                    Item(itemID: "item0", name: "Item 0", isInsufficient: false, lastChange: TestUtils.makeDate(2017, 7, 10, 17, 00, 00)),
                    Item(itemID: "item1", name: "Item 1", isInsufficient: false, lastChange: TestUtils.makeDate(2017, 9, 10, 14, 30, 20)),
                ], deletions: [], insertions: [0, 1], modifications: []))
            } else {
                return Observable.error(TestError.error)
            }
        }
        
        let viewModel: MainViewModel = DefaultMainViewModel(resolver: resolver)

        let expectItems = expectation(description: "item list can loaded")
        let itemListObserver = EventuallyFulfill(expectItems) { (list: MainViewItemList) in
            return list.viewModels.count == 2
        }
        viewModel.itemList
            .bind(to: itemListObserver)
            .disposed(by: disposeBag)
        
        let expectNoMessage = expectation(description: "message does not exist")
        let itemListMessageTextObserver = EventuallyFulfill(expectNoMessage) { (text: String) in
            return text == ""
        }
        viewModel.itemListMessageText
            .bind(to: itemListMessageTextObserver)
            .disposed(by: disposeBag)
        
        let expectMessageHidden = expectation(description: "message is hidden")
        let itemListMessageHiddenObserver = EventuallyFulfill(expectMessageHidden) { (isHidden: Bool) in
            return isHidden
        }
        viewModel.itemListMessageHidden
            .bind(to: itemListMessageHiddenObserver)
            .disposed(by: disposeBag)

        wait(for: [expectItems, expectNoMessage, expectMessageHidden], timeout: 3.0)
        
        let expectEmptyList = expectation(description: "item list become empty")
        itemListObserver.reset(expectEmptyList) { (list: MainViewItemList) in
            return list.viewModels.count == 0
        }
        
        let expectErrorMessage = expectation(description: "error message is shown")
        itemListMessageTextObserver.reset(expectErrorMessage) { (text: String) in
            return text == R.String.errorItemList.localized()
        }
        
        let expectMessageVisible = expectation(description: "message is visible")
        itemListMessageHiddenObserver.reset(expectMessageVisible) { (isHidden: Bool) in
            return !isHidden
        }
        
        // change segment to insufficient items
        viewModel.onSegmentSelectedIndexChange.onNext(1)
        wait(for: [expectEmptyList, expectErrorMessage, expectMessageVisible], timeout: 3.0)

        let expectItemsAgain = expectation(description: "item list can loaded again")
        itemListObserver.reset(expectItemsAgain) { (list: MainViewItemList) in
            return list.viewModels.count == 2
        }
        
        let expectNoMessageAgain = expectation(description: "message does not exist again")
        itemListMessageTextObserver.reset(expectNoMessageAgain)  { (text: String) in
            return text == ""
        }
        
        let expectMessageHiddenAgain = expectation(description: "message is hidden again")
        itemListMessageHiddenObserver.reset(expectMessageHiddenAgain) { (isHidden: Bool) in
            return isHidden
        }

        // change segment to sufficient items again
        viewModel.onSegmentSelectedIndexChange.onNext(0)
        wait(for: [expectItemsAgain, expectNoMessageAgain, expectMessageHiddenAgain], timeout: 3.0)
    }
    
    func testItemError() {
        enum TestError: Error { case error }
        resolver.itemRepository.mock.items.setup { _, _ in
            return Observable.just(CollectionChange(result: [
                Item(itemID: "item0", name: "Item 0", isInsufficient: false, lastChange: TestUtils.makeDate(2017, 7, 10, 17, 00, 00)),
                Item(itemID: "item1", error: TestError.error, name: "Item 1", isInsufficient: false, lastChange: TestUtils.makeDate(2017, 9, 10, 14, 30, 20)),
            ], deletions: [], insertions: [0, 1], modifications: []))
        }

        let viewModel: MainViewModel = DefaultMainViewModel(resolver: resolver)

        var item1Opt: MainItemViewModel? = nil
        let expectItems = expectation(description: "item list can loaded")
        let itemListObserver = EventuallyFulfill(expectItems) { (list: MainViewItemList) in
            guard list.viewModels.count == 2 else { return false }
            
            item1Opt = list.viewModels[1]
            return true
        }
        viewModel.itemList
            .bind(to: itemListObserver)
            .disposed(by: disposeBag)
        
        wait(for: [expectItems], timeout: 3.0)
        guard let item1 = item1Opt else { return }
        
        let expectName = expectation(description: "item's name is ERROR")
        let nameObserver = EventuallyFulfill(expectName) { (name: String) in
            return name == R.String.errorItem.localized()
        }
        item1.name
            .bind(to: nameObserver)
            .disposed(by: disposeBag)
        
        wait(for: [expectName], timeout: 3.0)
    }
    
    func testErrorItemShouldNotBeChecked() {
        enum TestError: Error { case error }
        resolver.itemRepository.mock.items.setup { _, _ in
            return Observable.just(CollectionChange(result: [
                Item(itemID: "item0", name: "Item 0", isInsufficient: false, lastChange: TestUtils.makeDate(2017, 7, 10, 17, 00, 00)),
                Item(itemID: "item1", error: TestError.error, name: "Item 1", isInsufficient: false, lastChange: TestUtils.makeDate(2017, 9, 10, 14, 30, 20)),
            ], deletions: [], insertions: [0, 1], modifications: []))
        }
        
        let viewModel: MainViewModel = DefaultMainViewModel(resolver: resolver)
        
        var item1Opt: MainItemViewModel? = nil
        let expectItems = expectation(description: "item list can loaded")
        let itemListObserver = EventuallyFulfill(expectItems) { (list: MainViewItemList) in
            guard list.viewModels.count == 2 else { return false }
            
            item1Opt = list.viewModels[1]
            return true
        }
        viewModel.itemList
            .bind(to: itemListObserver)
            .disposed(by: disposeBag)
        wait(for: [expectItems], timeout: 3.0)
        guard let item1 = item1Opt else { return }

        let expectChecked = expectation(description: "checked")
        expectChecked.isInverted = true
        let checkedObserver = EventuallyFulfill(expectChecked) { (isChecked: Bool) in
            return isChecked
        }
        item1.isChecked
            .bind(to: checkedObserver)
            .disposed(by: disposeBag)

        viewModel.onItemSelected.onNext(IndexPath(row: 1, section: 0))
        wait(for: [expectChecked], timeout: 0.3)
    }

    func testErrorItemShouldBeUnchecked() {
        enum TestError: Error { case error }
        let itemsSubject = PublishSubject<CollectionChange<Item>>()
        resolver.itemRepository.mock.items.setup { _, _ in
            return itemsSubject
        }
        
        let viewModel: MainViewModel = DefaultMainViewModel(resolver: resolver)
        
        var item1Opt: MainItemViewModel? = nil
        let expectItems = expectation(description: "item list can loaded")
        let itemListObserver = EventuallyFulfill(expectItems) { (list: MainViewItemList) in
            guard list.viewModels.count == 2 else { return false }
            
            item1Opt = list.viewModels[1]
            return true
        }
        viewModel.itemList
            .bind(to: itemListObserver)
            .disposed(by: disposeBag)
        
        itemsSubject.onNext(CollectionChange(result: [
            Item(itemID: "item0", name: "Item 0", isInsufficient: false, lastChange: TestUtils.makeDate(2017, 7, 10, 17, 00, 00)),
            Item(itemID: "item1", name: "Item 1", isInsufficient: false, lastChange: TestUtils.makeDate(2017, 9, 10, 14, 30, 20)),
        ], deletions: [], insertions: [0, 1], modifications: []))
        
        wait(for: [expectItems], timeout: 3.0)
        guard let item1 = item1Opt else { return }
        
        let expectChecked = expectation(description: "checked")
        let checkedObserver = EventuallyFulfill(expectChecked) { (isChecked: Bool) in
            return isChecked
        }
        item1.isChecked
            .bind(to: checkedObserver)
            .disposed(by: disposeBag)
        
        viewModel.onItemSelected.onNext(IndexPath(row: 1, section: 0))
        wait(for: [expectChecked], timeout: 3.0)

        let expectUnchecked = expectation(description: "unchecked")
        checkedObserver.reset(expectUnchecked) { (isChecked: Bool) in
            return !isChecked
        }

        itemsSubject.onNext(CollectionChange(result: [
            Item(itemID: "item0", name: "Item 0", isInsufficient: false, lastChange: TestUtils.makeDate(2017, 7, 10, 17, 00, 00)),
            Item(itemID: "item1", error: TestError.error, name: "Item 1", isInsufficient: false, lastChange: TestUtils.makeDate(2017, 9, 10, 14, 30, 20)),
        ], deletions: [], insertions: [], modifications: [(1, 1)]))

        wait(for: [expectUnchecked], timeout: 3.0)
    }
}
