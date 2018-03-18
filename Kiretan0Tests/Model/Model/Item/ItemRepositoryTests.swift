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
    var resolver: MockResolver!

    class MockResolver: DefaultItemRepository.Resolver {
        let dataStore = MockDataStore()
        func resolveDataStore() -> DataStore {
            return dataStore
        }
    }

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        
        disposeBag = DisposeBag()
        resolver = MockResolver()
    }
    
    override func tearDown() {
        disposeBag = nil
        resolver = nil
        
        super.tearDown()
    }
    
    func setupMockWrite(writer: DocumentWriter) {
        resolver.dataStore.mock.write.setup { (block) -> Completable in
            return Completable.create { observer in
                do {
                    try block(writer)
                    observer(.completed)
                } catch let error {
                    observer(.error(error))
                }
                return Disposables.create()
            }
        }
    }
    
    func testSufficientItems() {
        let observeCollectionForItem = MockFunction<(DataStoreQuery) -> Observable<CollectionChange<Item>>>("observeCollection for Item")
        observeCollectionForItem.setup { (query) -> Observable<CollectionChange<Item>> in
            let mockQuery = query as! MockDataStoreQuery
            XCTAssertEqual(mockQuery.path, "/team/aaa/item?insufficient=={false}@last_change:asc")
            
            let item1 = Item(itemID: "item_aaa_1", name: "Item 1", isInsufficient: false, lastChange: TestUtils.makeDate(2017, 7, 10, 17, 00, 00))
            let item2 = Item(itemID: "item_aaa_2", name: "Item 2", isInsufficient: false, lastChange: TestUtils.makeDate(2017, 7, 12, 10, 00, 00))
            let change = CollectionChange(
                result: [
                    item1,
                    item2,
                ],
                events: [
                    .inserted(0, item1),
                    .inserted(1, item2),
                ]
            )
            return Observable.just(change).concat(Observable.never())
        }
        resolver.dataStore.mock.observeCollection.install(observeCollectionForItem)
        
        let itemRepository = DefaultItemRepository(resolver: resolver)

        var item0Opt: Item?
        let exp = expectation(description: "Two items are retrieved")
        let observer = EventuallyFulfill(exp) { (change: CollectionChange<Item>) in
            guard change.result.count == 2 else { return false }
            guard change.result[0].itemID == "item_aaa_1" else { return false }
            guard change.result[1].itemID == "item_aaa_2" else { return false }

            item0Opt = change.result[0]
            return true
        }

        itemRepository.items(in: "aaa", insufficient: false)
            .bind(to: observer)
            .disposed(by: disposeBag)
        
        wait(for: [exp], timeout: 3.0)
        guard let item0 = item0Opt else { return }
        
        XCTAssertEqual(item0.name, "Item 1")
        XCTAssertFalse(item0.isInsufficient)
        XCTAssertEqual(item0.lastChange, TestUtils.makeDate(2017, 7, 10, 17, 00, 00))
    }
    
    func testInsufficientItems() {
        let observeCollectionForItem = MockFunction<(DataStoreQuery) -> Observable<CollectionChange<Item>>>("observeCollection for Item")
        observeCollectionForItem.setup { (query) -> Observable<CollectionChange<Item>> in
            let mockQuery = query as! MockDataStoreQuery
            XCTAssertEqual(mockQuery.path, "/team/aaa/item?insufficient=={true}@last_change:asc")
            
            let item3 = Item(itemID: "item_aaa_3", name: "Item 3", isInsufficient: true, lastChange: TestUtils.makeDate(2017, 7, 08, 14, 20, 30))
            let change = CollectionChange(
                result: [
                    item3,
                ],
                events: [
                    .inserted(0, item3)
                ]
            )
            return Observable.just(change).concat(Observable.never())
        }
        resolver.dataStore.mock.observeCollection.install(observeCollectionForItem)

        let itemRepository = DefaultItemRepository(resolver: resolver)

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
        var isTeamCreated = false

        let writer = MockDocumentWriter()
        writer.mock.setDocumentData.setup { (data, documentPath) in
            newItemID = documentPath.documentID
            let mockDocumentPath = documentPath as! MockDocumentPath
            XCTAssertEqual(mockDocumentPath.path, "/team/aaa/item/\(newItemID)")

            isTeamCreated = true
            XCTAssertEqual(data["name"] as? String, "newItem")
            XCTAssertEqual(data["insufficient"] as? Bool, false)
            XCTAssertEqual(data["last_change"] as? MockDataStorePlaceholder, .serverTimestampPlaceholder)
        }
        setupMockWrite(writer: writer)

        let itemRepository = DefaultItemRepository(resolver: resolver)

        let expectSuccess = expectation(description: "createItem should succeed")
        let item = Item(name: "newItem", isInsufficient: false)
        itemRepository
            .createItem(item, in: "aaa")
            .subscribe(onSuccess: { itemID in
                XCTAssertEqual(itemID, newItemID)
                expectSuccess.fulfill()
            }, onError: { error in
                XCTFail("error: \(error)")
            })
            .disposed(by: disposeBag)

        wait(for: [expectSuccess], timeout: 3.0)
        XCTAssertTrue(isTeamCreated)
    }
    
    func testUpdateItem() {
        var isTeamUpdated = false
        let writer = MockDocumentWriter()
        writer.mock.updateDocumentData.setup { (data, documentPath) in
            let mockDocumentPath = documentPath as! MockDocumentPath
            XCTAssertEqual(mockDocumentPath.path, "/team/aaa/item/item_aaa_1")
            
            isTeamUpdated = true
            XCTAssertEqual(data["name"] as? String, "newItem1")
            XCTAssertEqual(data["insufficient"] as? Bool, true)
            XCTAssertEqual(data["last_change"] as? MockDataStorePlaceholder, .serverTimestampPlaceholder)
        }
        setupMockWrite(writer: writer)
        
        let itemRepository = DefaultItemRepository(resolver: resolver)

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
        XCTAssertTrue(isTeamUpdated)
    }
    
    func testRemoveItem() {
        var isTeamRemoved = false
        let writer = MockDocumentWriter()
        writer.mock.deleteDocument.setup { documentPath in
            let mockDocumentPath = documentPath as! MockDocumentPath
            
            isTeamRemoved = true
            XCTAssertEqual(mockDocumentPath.path, "/team/aaa/item/item_aaa_1")
        }
        setupMockWrite(writer: writer)

        let itemRepository = DefaultItemRepository(resolver: resolver)

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
        XCTAssertTrue(isTeamRemoved)
    }
}
