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
        
        let expectDocument = expectation(description: "Existing document should be retrieved")
        let observer = FulfillObserver(expectDocument) { (doc: MockDocument?) in
            guard let doc = doc else { return false }
            guard doc.documentID == "document1" else { return false }
            guard (doc.data["string"] as? String ?? "") == "Foo" else { return false }
            return true
        }
        
        docObservable.subscribe(observer).disposed(by: disposeBag)
        wait(for: [expectDocument], timeout: 3.0)
    }
    
    func testObserveNonExistingDocument() {
        let docPath = dataStore.collection("collection1").document("document0")
        let docObservable: Observable<MockDocument?> = dataStore.observeDocument(at: docPath)
        
        let expectNil = expectation(description: "Nil should be retrieved instead of the entity")
        let observer = FulfillObserver(expectNil) { (doc: MockDocument?) in
            return doc == nil
        }
        
        docObservable.subscribe(observer).disposed(by: disposeBag)
        wait(for: [expectNil], timeout: 3.0)
    }
    
    func testObserveCollection() {
        let collectionPath = dataStore.collection("collection1")
        let collectionObservable: Observable<CollectionChange<MockDocument>> = dataStore.observeCollection(matches: collectionPath)
        
        let expectCollection = expectation(description: "Documents should be retrieved")
        let observer = FulfillObserver(expectCollection) { (change: CollectionChange<MockDocument>) in
            let documents = change.result
            guard documents.count == 3 else { return false }
            guard documents[0].documentID == "document1" else { return false }
            guard change.insertions == [0, 1, 2] else { return false }
            guard change.deletions.isEmpty else { return false }
            guard change.modifications.isEmpty else { return false }
            return true
        }
        
        collectionObservable.subscribe(observer).disposed(by: disposeBag)
        wait(for: [expectCollection], timeout: 3.0)
    }
    
    func testObserveQueryEqualTo() {
        let collectionPath = dataStore.collection("collection1")
        let query = collectionPath.whereField("int", isEqualTo: 80)
        let collectionObservable: Observable<CollectionChange<MockDocument>> = dataStore.observeCollection(matches: query)
        
        let expectCollection = expectation(description: "A document should be retrieved")
        let observer = FulfillObserver(expectCollection) { (change: CollectionChange<MockDocument>) in
            let documents = change.result
            guard documents.count == 1 else { return false }
            guard documents[0].documentID == "document2" else { return false }
            guard change.insertions == [0] else { return false }
            guard change.deletions.isEmpty else { return false }
            guard change.modifications.isEmpty else { return false }
            return true
        }

        collectionObservable.subscribe(observer).disposed(by: disposeBag)
        wait(for: [expectCollection], timeout: 3.0)
    }
    
    func testObserveQueryLessThan() {
        let collectionPath = dataStore.collection("collection1")
        let query = collectionPath.whereField("int", isLessThan: 80)
        let collectionObservable: Observable<CollectionChange<MockDocument>> = dataStore.observeCollection(matches: query)
        
        let expectCollection = expectation(description: "Two documents should be retrieved")
        let observer = FulfillObserver(expectCollection) { (change: CollectionChange<MockDocument>) in
            let documents = change.result
            guard documents.count == 2 else { return false }
            guard documents[0].documentID == "document1" else { return false }
            guard documents[1].documentID == "document3" else { return false }
            guard change.insertions == [0, 1] else { return false }
            guard change.deletions.isEmpty else { return false }
            guard change.modifications.isEmpty else { return false }
            return true
        }
        
        collectionObservable.subscribe(observer).disposed(by: disposeBag)
        wait(for: [expectCollection], timeout: 3.0)
    }

    func testObserveQueryLessThanOrEqualTo() {
        let collectionPath = dataStore.collection("collection1")
        let query = collectionPath.whereField("string", isLessThanOrEqualTo: "Baz")
        let collectionObservable: Observable<CollectionChange<MockDocument>> = dataStore.observeCollection(matches: query)
        
        let expectCollection = expectation(description: "Two documents should be retrieved")
        let observer = FulfillObserver(expectCollection) { (change: CollectionChange<MockDocument>) in
            let documents = change.result
            guard documents.count == 2 else { return false }
            guard documents[0].documentID == "document2" else { return false }
            guard documents[1].documentID == "document3" else { return false }
            guard change.insertions == [0, 1] else { return false }
            guard change.deletions.isEmpty else { return false }
            guard change.modifications.isEmpty else { return false }
            return true
        }
        
        collectionObservable.subscribe(observer).disposed(by: disposeBag)
        wait(for: [expectCollection], timeout: 3.0)
    }

    func testObserveQueryGreaterThan() {
        let collectionPath = dataStore.collection("collection1")
        let query = collectionPath.whereField("int", isGreaterThan: 80)
        let collectionObservable: Observable<CollectionChange<MockDocument>> = dataStore.observeCollection(matches: query)
        
        let expectCollection = expectation(description: "No documents should be retrieved")
        let observer = FulfillObserver(expectCollection) { (change: CollectionChange<MockDocument>) in
            let documents = change.result
            guard documents.count == 0 else { return false }
            guard change.insertions.isEmpty else { return false }
            guard change.deletions.isEmpty else { return false }
            guard change.modifications.isEmpty else { return false }
            return true
        }
        
        collectionObservable.subscribe(observer).disposed(by: disposeBag)
        wait(for: [expectCollection], timeout: 3.0)
    }

    func testObserveQueryGreaterThanOrEqualTo() {
        let collectionPath = dataStore.collection("collection1")
        let query = collectionPath.whereField("int", isGreaterThanOrEqualTo: 80)
        let collectionObservable: Observable<CollectionChange<MockDocument>> = dataStore.observeCollection(matches: query)
        
        let expectCollection = expectation(description: "A document should be retrieved")
        let observer = FulfillObserver(expectCollection) { (change: CollectionChange<MockDocument>) in
            let documents = change.result
            guard documents.count == 1 else { return false }
            guard documents[0].documentID == "document2" else { return false }
            guard change.insertions == [0] else { return false }
            guard change.deletions.isEmpty else { return false }
            guard change.modifications.isEmpty else { return false }
            return true
        }
        
        collectionObservable.subscribe(observer).disposed(by: disposeBag)
        wait(for: [expectCollection], timeout: 3.0)
    }

    func testObserveComplexQuery() {
        let collectionPath = dataStore.collection("collection1")
        let query = collectionPath.whereField("int", isGreaterThan: 30).whereField("string", isLessThan: "Car")
        let collectionObservable: Observable<CollectionChange<MockDocument>> = dataStore.observeCollection(matches: query)
        
        let expectCollection = expectation(description: "A document should be retrieved")
        let observer = FulfillObserver(expectCollection) { (change: CollectionChange<MockDocument>) in
            let documents = change.result
            guard documents.count == 1 else { return false }
            guard documents[0].documentID == "document2" else { return false }
            guard change.insertions == [0] else { return false }
            guard change.deletions.isEmpty else { return false }
            guard change.modifications.isEmpty else { return false }
            return true
        }
        
        collectionObservable.subscribe(observer).disposed(by: disposeBag)
        wait(for: [expectCollection], timeout: 3.0)
    }
    
    func testObserveOrderAscending() {
        let collectionPath = dataStore.collection("collection1")
        let query = collectionPath.order(by: "int")

        let collectionObservable: Observable<CollectionChange<MockDocument>> = dataStore.observeCollection(matches: query)
        
        let expectCollection = expectation(description: "Three documents should be retrieved")
        let observer = FulfillObserver(expectCollection) { (change: CollectionChange<MockDocument>) in
            let documents = change.result
            guard documents.count == 3 else { return false }
            guard documents[0].documentID == "document3" else { return false }
            guard documents[1].documentID == "document1" else { return false }
            guard documents[2].documentID == "document2" else { return false }
            guard change.insertions == [0, 1, 2] else { return false }
            guard change.deletions.isEmpty else { return false }
            guard change.modifications.isEmpty else { return false }
            return true
        }
        
        collectionObservable.subscribe(observer).disposed(by: disposeBag)
        wait(for: [expectCollection], timeout: 3.0)
    }

    func testObserveOrderDescending() {
        let collectionPath = dataStore.collection("collection1")
        let query = collectionPath.order(by: "int", descending: true)
        
        let collectionObservable: Observable<CollectionChange<MockDocument>> = dataStore.observeCollection(matches: query)
        
        let expectCollection = expectation(description: "Three documents should be retrieved")
        let observer = FulfillObserver(expectCollection) { (change: CollectionChange<MockDocument>) in
            let documents = change.result
            guard documents.count == 3 else { return false }
            guard documents[0].documentID == "document2" else { return false }
            guard documents[1].documentID == "document1" else { return false }
            guard documents[2].documentID == "document3" else { return false }
            guard change.insertions == [0, 1, 2] else { return false }
            guard change.deletions.isEmpty else { return false }
            guard change.modifications.isEmpty else { return false }
            return true
        }
        
        collectionObservable.subscribe(observer).disposed(by: disposeBag)
        wait(for: [expectCollection], timeout: 3.0)
    }
    
    func testObserveMultipleOrder() {
        let collectionPath = dataStore.collection("collection1")
        let query = collectionPath.order(by: "bool", descending: true).order(by: "int", descending: false)
        
        let collectionObservable: Observable<CollectionChange<MockDocument>> = dataStore.observeCollection(matches: query)
        
        let expectCollection = expectation(description: "Three documents should be retrieved")
        let observer = FulfillObserver(expectCollection) { (change: CollectionChange<MockDocument>) in
            let documents = change.result
            guard documents.count == 3 else { return false }
            guard documents[0].documentID == "document2" else { return false }
            guard documents[1].documentID == "document3" else { return false }
            guard documents[2].documentID == "document1" else { return false }
            guard change.insertions == [0, 1, 2] else { return false }
            guard change.deletions.isEmpty else { return false }
            guard change.modifications.isEmpty else { return false }
            return true
        }
        
        collectionObservable.subscribe(observer).disposed(by: disposeBag)
        wait(for: [expectCollection], timeout: 3.0)
    }
    
    func testAddDocument() {
        let collectionPath = dataStore.collection("collection1")
        let query = collectionPath.order(by: "int")
        let collectionObservable: Observable<CollectionChange<MockDocument>> = dataStore.observeCollection(matches: query)
        
        let expectCollection = expectation(description: "Three documents should be retrieved")
        let collectionObserver = FulfillObserver(expectCollection) { (change: CollectionChange<MockDocument>) in
            let documents = change.result
            guard documents.count == 3 else { return false }
            guard documents[0].documentID == "document3" else { return false }
            guard documents[1].documentID == "document1" else { return false }
            guard documents[2].documentID == "document2" else { return false }
            guard change.insertions == [0, 1, 2] else { return false }
            guard change.deletions.isEmpty else { return false }
            guard change.modifications.isEmpty else { return false }
            return true
        }
        
        collectionObservable.subscribe(collectionObserver).disposed(by: disposeBag)
        wait(for: [expectCollection], timeout: 3.0)

        let expectWriting = expectation(description: "Writing result should be success")
        let expectCollectionChange = expectation(description: "Collection should be changed")
        collectionObserver.reset(expectCollectionChange) { (change: CollectionChange<MockDocument>) in
            let documents = change.result
            guard documents.count == 4 else { return false }
            guard documents[0].documentID == "document3" else { return false }
            guard documents[1].documentID == "newDocument" else { return false }
            guard documents[2].documentID == "document1" else { return false }
            guard documents[3].documentID == "document2" else { return false }
            guard change.insertions == [1] else { return false }
            guard change.deletions.isEmpty else { return false }
            guard change.modifications.isEmpty else { return false }
            return true
        }
        
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
    }

    func testDeleteDocument() {
        let collectionPath = dataStore.collection("collection1")
        let query = collectionPath.order(by: "int")
        let collectionObservable: Observable<CollectionChange<MockDocument>> = dataStore.observeCollection(matches: query)
        
        let expectCollection = expectation(description: "Three documents should be retrieved")
        let collectionObserver = FulfillObserver(expectCollection) { (change: CollectionChange<MockDocument>) in
            let documents = change.result
            guard documents.count == 3 else { return false }
            guard documents[0].documentID == "document3" else { return false }
            guard documents[1].documentID == "document1" else { return false }
            guard documents[2].documentID == "document2" else { return false }
            guard change.insertions == [0, 1, 2] else { return false }
            guard change.deletions.isEmpty else { return false }
            guard change.modifications.isEmpty else { return false }
            return true
        }
        
        collectionObservable.subscribe(collectionObserver).disposed(by: disposeBag)
        wait(for: [expectCollection], timeout: 3.0)

        let expectWriting = expectation(description: "Writing result should be success")
        let expectCollectionChange = expectation(description: "Collection should be changed")
        collectionObserver.reset(expectCollectionChange) { (change: CollectionChange<MockDocument>) in
            let documents = change.result
            guard documents.count == 1 else { return false }
            guard documents[0].documentID == "document1" else { return false }
            guard change.insertions.isEmpty else { return false }
            guard change.deletions == [0, 2] else { return false }
            guard change.modifications.isEmpty else { return false }
            return true
        }
        
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
    }
}
