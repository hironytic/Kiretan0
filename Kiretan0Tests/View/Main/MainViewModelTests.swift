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

class MainViewModelTests: XCTestCase {
    var disposeBag: DisposeBag!
    var resolver: MockResolver!

    class NullSettingViewModel: SettingViewModel {
        let displayMessage = Observable<DisplayMessage>.never()
        var dismissalMessage = Observable<DismissalMessage>.never()
        var tableData = Observable<[TableSectionViewModel]>.never()
        
        let onDone = ActionObserver<Void>().asObserver()
    }
    
    class MockResolver: DefaultMainViewModel.Resolver, NullResolver {
        let itemRepository = MockItemRepository()
        let mainUserDefaultsRepository = MockMainUserDefaultsRepository()
        let teamRepository = MockTeamRepository()

        init() {
        }

        func resolveMainItemViewModel(selected: Observable<Bool>, onSelected: AnyObserver<Void>) -> MainItemViewModel {
            return DefaultMainItemViewModel(resolver: self, selected: selected, onSelected: onSelected)
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
            XCTAssertEqual(teamID, "TEST_TEAM_ID")
            return Observable.just(Team(teamID: "TEST_TEAM_ID", name: "My Team"))
        }
        resolver.mainUserDefaultsRepository.mock.lastMainSegment.setup {
            return Observable.just(0)
        }
        resolver.itemRepository.mock.items.setup { (teamID, insufficient) in
            XCTAssertEqual(teamID, "TEST_TEAM_ID")
            return Observable.just(CollectionChange(result: [], deletions: [], insertions: [], modifications: []))
        }
    }
    
    override func tearDown() {
        disposeBag = nil
        resolver = nil

        super.tearDown()
    }
    
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
        let segment = BehaviorSubject(value: 1)
        resolver.mainUserDefaultsRepository.mock.lastMainSegment.setup { segment }
        resolver.mainUserDefaultsRepository.mock.setLastMainSegment.setup { index in
            segment.onNext(index)
        }
        
        let viewModel: MainViewModel = DefaultMainViewModel(resolver: resolver)

        let expect1 = expectation(description: "segment 1 is selected")
        let segmentSelectedIndexObserver = EventuallyFulfill(expect1) { (index: Int) in
            return index == 1
        }
        
        viewModel.segmentSelectedIndex
            .bind(to: segmentSelectedIndexObserver)
            .disposed(by: disposeBag)
        
        wait(for: [expect1], timeout: 3.0)
        
        let expect2 = expectation(description: "segument 0 is selected")
        segmentSelectedIndexObserver.reset(expect2) { (index: Int) in
            return index == 0
        }
        
        viewModel.onSegmentSelectedIndexChange.onNext(0)
        wait(for: [expect2], timeout: 3.0)
    }
    
    func testItemList() {
        resolver.itemRepository.mock.items.setup { (teamID, insufficient) in
            XCTAssertEqual(teamID, "TEST_TEAM_ID")
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
        let observer = EventuallyFulfill(expect) { (change: [MainItemViewModel]) in
            guard change.count == 2 else { return false }
            itemVM0Opt = change[0]
            itemVM1Opt = change[1]
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
}
