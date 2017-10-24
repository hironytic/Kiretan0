//
// ItemRepositoryTests.swift
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

class ItemRepositoryTests: XCTestCase {
    var disposeBag: DisposeBag!
    var itemRepository: ItemRepository!

    override func setUp() {
        super.setUp()
        
        let dataStore = MockDataStore(initialCollections: [
            "/team/aaa/item": [
                "item_aaa_1": [
                    "name": "Item 1",
                    "insufficient": false,
                    "last_change": TestUtils.makeDate(2017, 7, 10, 17, 00, 00)
                ],
                "item_aaa_2": [
                    "name": "Item 2",
                    "insufficient": false,
                    "last_change": TestUtils.makeDate(2017, 7, 12, 10, 00, 00)
                ],
                "item_aaa_3": [
                    "name": "Item 3",
                    "insufficient": true,
                    "last_change": TestUtils.makeDate(2017, 7, 08, 14, 20, 30)
                ],
            ],
            "/team/bbb_item": [
                "item_bbb_1": [
                    "name": "Item 1",
                    "insufficient": false,
                    "last_change": TestUtils.makeDate(2018, 1, 10, 3, 00, 00)
                ]
            ]
        ])
        
        disposeBag = DisposeBag()
        
        class MockResolver: DefaultItemRepository.Resolver {
            let dataStore: DataStore
            init(dataStore: DataStore) {
                self.dataStore = dataStore
            }
            func resolveDataStore() -> DataStore {
                return dataStore
            }
        }
        itemRepository = DefaultItemRepository(resolver: MockResolver(dataStore: dataStore))
    }
    
    override func tearDown() {
        disposeBag = nil
        itemRepository = nil
        
        super.tearDown()
    }
    
    func testSufficientItems() {
        var item0Opt: Item?
        let exp = expectation(description: "Two items are retrieved")
        let observer = EventuallyFulfill(exp) { (change: CollectionChange<Item>) in
            guard change.result.count == 2 else { return false }
            guard change.result[0].itemID == "item_aaa_2" else { return false }
            guard change.result[1].itemID == "item_aaa_1" else { return false }

            item0Opt = change.result[0]
            return true
        }
        
        itemRepository.items(in: "aaa", insufficient: false)
            .bind(to: observer)
            .disposed(by: disposeBag)
        
        wait(for: [exp], timeout: 3.0)
        guard let item0 = item0Opt else { return }
        
        XCTAssertEqual(item0.name, "Item 2")
        XCTAssertFalse(item0.isInsufficient)
        XCTAssertEqual(item0.lastChange, TestUtils.makeDate(2017, 7, 12, 10, 00, 00))
    }
    
    func testInsufficientItems() {
        var item0Opt: Item?
        let exp = expectation(description: "One item is retrieved")
        let observer = EventuallyFulfill(exp) { (change: CollectionChange<Item>) in
            guard change.result.count == 1 else { return false }
            guard change.result[0].itemID == "item_aaa_3" else { return false }
            
            item0Opt = change.result[0]
            return true
        }
        
        itemRepository.items(in: "aaa", insufficient: true)
            .bind(to: observer)
            .disposed(by: disposeBag)
        
        wait(for: [exp], timeout: 3.0)
        guard let item0 = item0Opt else { return }
        
        XCTAssertEqual(item0.name, "Item 3")
        XCTAssertTrue(item0.isInsufficient)
        XCTAssertEqual(item0.lastChange, TestUtils.makeDate(2017, 7, 08, 14, 20, 30))
    }
    
    func testCreateItem() {
        var newItemID: String = ""
        
        let expectSuccess = expectation(description: "createItem should succeed")
        let item = Item(name: "newItem", isInsufficient: false)
        itemRepository
            .createItem(item, in: "aaa")
            .subscribe(onSuccess: { itemID in
                newItemID = itemID
                expectSuccess.fulfill()
            }, onError: { error in
                XCTFail("error: \(error)")
            })
            .disposed(by: disposeBag)

        wait(for: [expectSuccess], timeout: 3.0)

        var newItemOpt: Item?
        let expectNewItem = expectation(description: "New item should exist")
        let observer = EventuallyFulfill(expectNewItem) { (change: CollectionChange<Item>) in
            guard change.result.count == 3 else { return false }
            for item in change.result {
                if item.itemID == newItemID {
                    newItemOpt = item
                    return true
                }
            }
            return false
        }
        
        itemRepository.items(in: "aaa", insufficient: false)
            .bind(to: observer)
            .disposed(by: disposeBag)
        
        wait(for: [expectNewItem], timeout: 3.0)
        guard let newItem = newItemOpt else { return }
        
        XCTAssertEqual(newItem.name, "newItem")
        XCTAssertFalse(newItem.isInsufficient)
    }
    
    func testUpdateItem() {
        let expectSuccess = expectation(description: "updateItem should succeed")
        let toUpdate = Item(itemID: "item_aaa_1", name: "newItem1", isInsufficient: true)
        itemRepository
            .updateItem(toUpdate, in: "aaa")
            .subscribe(onCompleted: {
                expectSuccess.fulfill()
            }, onError: { error in
                XCTFail("error: \(error)")
            })
            .disposed(by: disposeBag)
        
        wait(for: [expectSuccess], timeout: 3.0)

        var itemOpt: Item?
        let expectUpdatedItem = expectation(description: "Item should be updated")
        let observer = EventuallyFulfill(expectUpdatedItem) { (change: CollectionChange<Item>) in
            guard change.result.count == 2 else { return false }
            for item in change.result {
                if item.itemID == "item_aaa_1" {
                    itemOpt = item
                    return true
                }
            }
            return false
        }
        
        itemRepository.items(in: "aaa", insufficient: true)
            .bind(to: observer)
            .disposed(by: disposeBag)
        
        wait(for: [expectUpdatedItem], timeout: 3.0)
        guard let item = itemOpt else { return }
        
        XCTAssertEqual(item.name, "newItem1")
        XCTAssertTrue(item.isInsufficient)
    }
    
    func testRemoveItem() {
        let expectSuccess = expectation(description: "updateItem should succeed")
        itemRepository
            .removeItem("item_aaa_1", in: "aaa")
            .subscribe(onCompleted: {
                expectSuccess.fulfill()
            }, onError: { error in
                XCTFail("error: \(error)")
            })
            .disposed(by: disposeBag)
        
        wait(for: [expectSuccess], timeout: 3.0)

        let expectItemRemoved = expectation(description: "Item should be removed")
        let observer = EventuallyFulfill(expectItemRemoved) { (change: CollectionChange<Item>) in
            for item in change.result {
                if item.itemID == "item_aaa_1" {
                    return false
                }
            }
            return true
        }
        
        itemRepository.items(in: "aaa", insufficient: false)
            .bind(to: observer)
            .disposed(by: disposeBag)
        
        wait(for: [expectItemRemoved], timeout: 3.0)
    }
}
