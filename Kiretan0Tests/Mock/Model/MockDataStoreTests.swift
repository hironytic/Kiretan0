//
// MockDataStoreTests.swift
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

struct MockDocument: Entity {
    let documentID: String
    let data: [String: Any]
    
    init(documentID: String, data: [String : Any]) throws {
        self.documentID = documentID
        self.data = data
    }
}

class MockDataStoreTests: XCTestCase {
    var dataStore: MockDataStore!
    var disposeBag: DisposeBag!
    
    override func setUp() {
        super.setUp()
        
        disposeBag = DisposeBag()
        dataStore = MockDataStore(initialCollections: [
            "/collection1": [
                "document1": [
                    "string": "Foo",
                    "int": 42,
                    "double": 3.14,
                    "bool": false,
                ],
                "document2": [
                    "string": "Bar",
                    "int": 80,
                    "bool": true,
                ],
                "document3": [
                    "string": "Baz",
                    "int": 21,
                    "bool": false,
                ]
            ],
            "/collection1/document1/collection2": [
                "d1": [
                    "v1": 100
                ]
            ]
        ])
    }
    
    override func tearDown() {
        disposeBag = nil
        
        super.tearDown()
    }
    
    func testObserveExisitngDocument() {
        let docPath = dataStore.collection("collection1").document("document1")
        let docObservable: Observable<MockDocument?> = dataStore.observeDocument(at: docPath)
        
        let expectEvents = expectation(description: "One event should be occured")
        let observer = RecordThenFulfill<MockDocument?>(expectEvents, count: 1)
        docObservable.subscribe(observer).disposed(by: disposeBag)
        wait(for: [expectEvents], timeout: 3.0)

        guard case let .next(optDoc) = observer.events[0] else { XCTFail("Event 0 should be `next`"); return }
        guard let doc = optDoc else { XCTFail("Existing document should be retrieved"); return }

        XCTAssertEqual(doc.documentID, "document1")
        XCTAssertEqual(doc.data["string"] as? String ?? "", "Foo")
    }
    
    func testObserveNonExistingDocument() {
        let docPath = dataStore.collection("collection1").document("document0")
        let docObservable: Observable<MockDocument?> = dataStore.observeDocument(at: docPath)
        
        let expectEvents = expectation(description: "One event should be occured")
        let observer = RecordThenFulfill<MockDocument?>(expectEvents, count: 1)
        docObservable.subscribe(observer).disposed(by: disposeBag)
        wait(for: [expectEvents], timeout: 3.0)

        guard case let .next(optDoc) = observer.events[0] else { XCTFail("Event 0 should be `next`"); return }
        XCTAssertNil(optDoc)
    }
    
    func testObserveCollection() {
        let collectionPath = dataStore.collection("collection1")
        let collectionObservable: Observable<CollectionChange<MockDocument>> = dataStore.observeCollection(matches: collectionPath)

        let expectEvents = expectation(description: "One event should be occured")
        let observer = RecordThenFulfill<CollectionChange<MockDocument>>(expectEvents, count: 1)
        collectionObservable.subscribe(observer).disposed(by: disposeBag)
        wait(for: [expectEvents], timeout: 3.0)

        guard case let .next(change) = observer.events[0] else { XCTFail("Event 0 should be `next`"); return }

        let documents = change.result
        XCTAssertEqual(documents.count, 3)
        XCTAssertEqual(documents[0].documentID, "document1")
        XCTAssertEqual(change.insertions, [0, 1, 2])
        XCTAssertTrue(change.deletions.isEmpty)
        XCTAssertTrue(change.modifications.isEmpty)
    }
    
    func testObserveQueryEqualTo() {
        let collectionPath = dataStore.collection("collection1")
        let query = collectionPath.whereField("int", isEqualTo: 80)
        let collectionObservable: Observable<CollectionChange<MockDocument>> = dataStore.observeCollection(matches: query)

        let expectEvents = expectation(description: "One event should be occured")
        let observer = RecordThenFulfill<CollectionChange<MockDocument>>(expectEvents, count: 1)
        collectionObservable.subscribe(observer).disposed(by: disposeBag)
        wait(for: [expectEvents], timeout: 3.0)
        
        guard case let .next(change) = observer.events[0] else { XCTFail("Event 0 should be `next`"); return }
        
        let documents = change.result
        XCTAssertEqual(documents.count, 1)
        XCTAssertEqual(documents[0].documentID, "document2")
        XCTAssertEqual(change.insertions, [0])
        XCTAssertTrue(change.deletions.isEmpty)
        XCTAssertTrue(change.modifications.isEmpty)
    }
    
    func testObserveQueryLessThan() {
        let collectionPath = dataStore.collection("collection1")
        let query = collectionPath.whereField("int", isLessThan: 80)
        let collectionObservable: Observable<CollectionChange<MockDocument>> = dataStore.observeCollection(matches: query)
        
        let expectEvents = expectation(description: "One event should be occured")
        let observer = RecordThenFulfill<CollectionChange<MockDocument>>(expectEvents, count: 1)
        collectionObservable.subscribe(observer).disposed(by: disposeBag)
        wait(for: [expectEvents], timeout: 3.0)
        
        guard case let .next(change) = observer.events[0] else { XCTFail("Event 0 should be `next`"); return }
        
        let documents = change.result
        XCTAssertEqual(documents.count, 2)
        XCTAssertEqual(documents[0].documentID, "document1")
        XCTAssertEqual(documents[1].documentID, "document3")
        XCTAssertEqual(change.insertions, [0, 1])
        XCTAssertTrue(change.deletions.isEmpty)
        XCTAssertTrue(change.modifications.isEmpty)
    }

    func testObserveQueryLessThanOrEqualTo() {
        let collectionPath = dataStore.collection("collection1")
        let query = collectionPath.whereField("string", isLessThanOrEqualTo: "Baz")
        let collectionObservable: Observable<CollectionChange<MockDocument>> = dataStore.observeCollection(matches: query)
        
        let expectEvents = expectation(description: "One event should be occured")
        let observer = RecordThenFulfill<CollectionChange<MockDocument>>(expectEvents, count: 1)
        collectionObservable.subscribe(observer).disposed(by: disposeBag)
        wait(for: [expectEvents], timeout: 3.0)
        
        guard case let .next(change) = observer.events[0] else { XCTFail("Event 0 should be `next`"); return }
        
        let documents = change.result
        XCTAssertEqual(documents.count, 2)
        XCTAssertEqual(documents[0].documentID, "document2")
        XCTAssertEqual(documents[1].documentID, "document3")
        XCTAssertEqual(change.insertions, [0, 1])
        XCTAssertTrue(change.deletions.isEmpty)
        XCTAssertTrue(change.modifications.isEmpty)
    }

    func testObserveQueryGreaterThan() {
        let collectionPath = dataStore.collection("collection1")
        let query = collectionPath.whereField("int", isGreaterThan: 80)
        let collectionObservable: Observable<CollectionChange<MockDocument>> = dataStore.observeCollection(matches: query)
        
        let expectEvents = expectation(description: "One event should be occured")
        let observer = RecordThenFulfill<CollectionChange<MockDocument>>(expectEvents, count: 1)
        collectionObservable.subscribe(observer).disposed(by: disposeBag)
        wait(for: [expectEvents], timeout: 3.0)
        
        guard case let .next(change) = observer.events[0] else { XCTFail("Event 0 should be `next`"); return }
        
        let documents = change.result
        XCTAssertEqual(documents.count, 0)
        XCTAssertTrue(change.insertions.isEmpty)
        XCTAssertTrue(change.deletions.isEmpty)
        XCTAssertTrue(change.modifications.isEmpty)
    }

    func testObserveQueryGreaterThanOrEqualTo() {
        let collectionPath = dataStore.collection("collection1")
        let query = collectionPath.whereField("int", isGreaterThanOrEqualTo: 80)
        let collectionObservable: Observable<CollectionChange<MockDocument>> = dataStore.observeCollection(matches: query)
        
        let expectEvents = expectation(description: "One event should be occured")
        let observer = RecordThenFulfill<CollectionChange<MockDocument>>(expectEvents, count: 1)
        collectionObservable.subscribe(observer).disposed(by: disposeBag)
        wait(for: [expectEvents], timeout: 3.0)
        
        guard case let .next(change) = observer.events[0] else { XCTFail("Event 0 should be `next`"); return }
        
        let documents = change.result
        XCTAssertEqual(documents.count, 1)
        XCTAssertEqual(documents[0].documentID, "document2")
        XCTAssertEqual(change.insertions, [0])
        XCTAssertTrue(change.deletions.isEmpty)
        XCTAssertTrue(change.modifications.isEmpty)
    }

    func testObserveComplexQuery() {
        let collectionPath = dataStore.collection("collection1")
        let query = collectionPath.whereField("int", isGreaterThan: 30).whereField("string", isLessThan: "Car")
        let collectionObservable: Observable<CollectionChange<MockDocument>> = dataStore.observeCollection(matches: query)

        let expectEvents = expectation(description: "One event should be occured")
        let observer = RecordThenFulfill<CollectionChange<MockDocument>>(expectEvents, count: 1)
        collectionObservable.subscribe(observer).disposed(by: disposeBag)
        wait(for: [expectEvents], timeout: 3.0)
        
        guard case let .next(change) = observer.events[0] else { XCTFail("Event 0 should be `next`"); return }
        
        let documents = change.result
        XCTAssertEqual(documents.count, 1)
        XCTAssertEqual(documents[0].documentID, "document2")
        XCTAssertEqual(change.insertions, [0])
        XCTAssertTrue(change.deletions.isEmpty)
        XCTAssertTrue(change.modifications.isEmpty)
    }
    
    func testObserveOrderAscending() {
        let collectionPath = dataStore.collection("collection1")
        let query = collectionPath.order(by: "int")
        let collectionObservable: Observable<CollectionChange<MockDocument>> = dataStore.observeCollection(matches: query)

        let expectEvents = expectation(description: "One event should be occured")
        let observer = RecordThenFulfill<CollectionChange<MockDocument>>(expectEvents, count: 1)
        collectionObservable.subscribe(observer).disposed(by: disposeBag)
        wait(for: [expectEvents], timeout: 3.0)
        
        guard case let .next(change) = observer.events[0] else { XCTFail("Event 0 should be `next`"); return }
        
        let documents = change.result
        XCTAssertEqual(documents.count, 3)
        XCTAssertEqual(documents[0].documentID, "document3")
        XCTAssertEqual(documents[1].documentID, "document1")
        XCTAssertEqual(documents[2].documentID, "document2")
        XCTAssertEqual(change.insertions, [0, 1, 2])
        XCTAssertTrue(change.deletions.isEmpty)
        XCTAssertTrue(change.modifications.isEmpty)
    }

    func testObserveOrderDescending() {
        let collectionPath = dataStore.collection("collection1")
        let query = collectionPath.order(by: "int", descending: true)
        let collectionObservable: Observable<CollectionChange<MockDocument>> = dataStore.observeCollection(matches: query)
        
        let expectEvents = expectation(description: "One event should be occured")
        let observer = RecordThenFulfill<CollectionChange<MockDocument>>(expectEvents, count: 1)
        collectionObservable.subscribe(observer).disposed(by: disposeBag)
        wait(for: [expectEvents], timeout: 3.0)
        
        guard case let .next(change) = observer.events[0] else { XCTFail("Event 0 should be `next`"); return }
        
        let documents = change.result
        XCTAssertEqual(documents.count, 3)
        XCTAssertEqual(documents[0].documentID, "document2")
        XCTAssertEqual(documents[1].documentID, "document1")
        XCTAssertEqual(documents[2].documentID, "document3")
        XCTAssertEqual(change.insertions, [0, 1, 2])
        XCTAssertTrue(change.deletions.isEmpty)
        XCTAssertTrue(change.modifications.isEmpty)
    }
    
    func testObserveMultipleOrder() {
        let collectionPath = dataStore.collection("collection1")
        let query = collectionPath.order(by: "bool", descending: true).order(by: "int", descending: false)
        let collectionObservable: Observable<CollectionChange<MockDocument>> = dataStore.observeCollection(matches: query)
        
        let expectEvents = expectation(description: "One event should be occured")
        let observer = RecordThenFulfill<CollectionChange<MockDocument>>(expectEvents, count: 1)
        collectionObservable.subscribe(observer).disposed(by: disposeBag)
        wait(for: [expectEvents], timeout: 3.0)
        
        guard case let .next(change) = observer.events[0] else { XCTFail("Event 0 should be `next`"); return }
        
        let documents = change.result
        XCTAssertEqual(documents.count, 3)
        XCTAssertEqual(documents[0].documentID, "document2")
        XCTAssertEqual(documents[1].documentID, "document3")
        XCTAssertEqual(documents[2].documentID, "document1")
        XCTAssertEqual(change.insertions, [0, 1, 2])
        XCTAssertTrue(change.deletions.isEmpty)
        XCTAssertTrue(change.modifications.isEmpty)
    }
    
    func testAddDocument() {
        let collectionPath = dataStore.collection("collection1")
        let query = collectionPath.order(by: "int")
        let collectionObservable: Observable<CollectionChange<MockDocument>> = dataStore.observeCollection(matches: query)

        let expectEvents = expectation(description: "One event should be occured")
        let observer = RecordThenFulfill<CollectionChange<MockDocument>>(expectEvents, count: 1)
        collectionObservable.subscribe(observer).disposed(by: disposeBag)
        wait(for: [expectEvents], timeout: 3.0)
        
        guard case let .next(change1) = observer.events[0] else { XCTFail("Event 0 should be `next`"); return }
        
        let documents1 = change1.result
        XCTAssertEqual(documents1.count, 3)
        XCTAssertEqual(documents1[0].documentID, "document3")
        XCTAssertEqual(documents1[1].documentID, "document1")
        XCTAssertEqual(documents1[2].documentID, "document2")
        XCTAssertEqual(change1.insertions, [0, 1, 2])
        XCTAssertTrue(change1.deletions.isEmpty)
        XCTAssertTrue(change1.modifications.isEmpty)

        let expectWriting = expectation(description: "Writing result should be success")
        let expectCollectionChange = expectation(description: "Collection should be changed")
        observer.reset(expectCollectionChange, count: 1)
        
        dataStore
            .write { writer in
                let documentPath = collectionPath.document("newDocument")
                writer.setDocumentData(["int": 30], at: documentPath)
            }
            .subscribe(onCompleted: {
                expectWriting.fulfill()
            }, onError: { error in
                XCTFail("error - \(error)")
            })
            .disposed(by: disposeBag)
        
        wait(for: [expectWriting, expectCollectionChange], timeout: 3.0)
        
        guard case let .next(change2) = observer.events[0] else { XCTFail("Event 0 should be `next`"); return }
        
        let documents2 = change2.result
        XCTAssertEqual(documents2.count, 4)
        XCTAssertEqual(documents2[0].documentID, "document3")
        XCTAssertEqual(documents2[1].documentID, "newDocument")
        XCTAssertEqual(documents2[2].documentID, "document1")
        XCTAssertEqual(documents2[3].documentID, "document2")
        XCTAssertEqual(change2.insertions, [1])
        XCTAssertTrue(change2.deletions.isEmpty)
        XCTAssertTrue(change2.modifications.isEmpty)
    }

    func testDeleteDocument() {
        let collectionPath = dataStore.collection("collection1")
        let query = collectionPath.order(by: "int")
        let collectionObservable: Observable<CollectionChange<MockDocument>> = dataStore.observeCollection(matches: query)

        let expectEvents = expectation(description: "One event should be occured")
        let observer = RecordThenFulfill<CollectionChange<MockDocument>>(expectEvents, count: 1)
        collectionObservable.subscribe(observer).disposed(by: disposeBag)
        wait(for: [expectEvents], timeout: 3.0)

        guard case let .next(change1) = observer.events[0] else { XCTFail("Event 0 should be `next`"); return }
        
        let documents1 = change1.result
        XCTAssertEqual(documents1.count, 3)
        XCTAssertEqual(documents1[0].documentID, "document3")
        XCTAssertEqual(documents1[1].documentID, "document1")
        XCTAssertEqual(documents1[2].documentID, "document2")
        XCTAssertEqual(change1.insertions, [0, 1, 2])
        XCTAssertTrue(change1.deletions.isEmpty)
        XCTAssertTrue(change1.modifications.isEmpty)
        
        let expectWriting = expectation(description: "Writing result should be success")
        let expectCollectionChange = expectation(description: "Collection should be changed")
        observer.reset(expectCollectionChange, count: 1)

        dataStore
            .write { writer in
                writer.deleteDocument(at: collectionPath.document("document2"))
                writer.deleteDocument(at: collectionPath.document("document3"))
            }
            .subscribe(onCompleted: {
                expectWriting.fulfill()
            }, onError: { error in
                XCTFail("error - \(error)")
            })
            .disposed(by: disposeBag)
        
        wait(for: [expectWriting, expectCollectionChange], timeout: 3.0)

        guard case let .next(change2) = observer.events[0] else { XCTFail("Event 0 should be `next`"); return }
        
        let documents2 = change2.result
        XCTAssertEqual(documents2.count, 1)
        XCTAssertEqual(documents2[0].documentID, "document1")
        XCTAssertTrue(change2.insertions.isEmpty)
        XCTAssertEqual(change2.deletions, [0, 2])
        XCTAssertTrue(change2.modifications.isEmpty)
    }
}
