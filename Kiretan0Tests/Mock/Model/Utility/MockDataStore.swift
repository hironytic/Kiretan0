//
// MockDataStore.swift
// Kiretan0Tests
//
// Copyright (c) 2018 Hironori Ichimiya <hiron@hironytic.com>
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
import XCTest
import RxSwift
@testable import Kiretan0

class MockDataStore: DataStore {
    class MockFunctionsForObserveDocument {
        var typeMap = [String: Any]()
        func install<E: Entity>(_ mockFunction: MockFunction<(DocumentPath) -> Observable<E?>>) {
            let typeString = String(describing: E.self)
            typeMap[typeString] = mockFunction
        }
    }
    
    class MockFunctionsForObserveCollection {
        var typeMap = [String: Any]()
        func install<E: Entity>(_ mockFunction: MockFunction<(DataStoreQuery) -> Observable<CollectionChange<E>>>) {
            let typeString = String(describing: E.self)
            typeMap[typeString] = mockFunction
        }
    }
    
    class Mock {
        var deletePlaceholder = MockFunction<() -> Any>("MockDataStore.deletePlaceholder")
        var serverTimestampPlaceholder = MockFunction<() -> Any>("MockDataStore.serverTimestampPlaceholder")
        var collection = MockFunction<(String) -> CollectionPath>("MockDataStore.collection")
        var observeDocument = MockFunctionsForObserveDocument()
        var observeCollection = MockFunctionsForObserveCollection()
        var write = MockFunction<(@escaping (DocumentWriter) throws -> Void) -> Completable>("MockDataStore.write")
        
        init() {
            deletePlaceholder.setup { return MockDataStorePlaceholder.deletePlaceholder }
            serverTimestampPlaceholder.setup { return MockDataStorePlaceholder.serverTimestampPlaceholder }
            collection.setup { return MockCollectionPath(path: "/\($0)")}
        }
    }
    let mock = Mock()

    var deletePlaceholder: Any {
        return mock.deletePlaceholder.call()
    }
    
    var serverTimestampPlaceholder: Any {
        return mock.serverTimestampPlaceholder.call()
    }
    
    func collection(_ collectionID: String) -> CollectionPath {
        return mock.collection.call(collectionID)
    }
    
    func observeDocument<E: Entity>(at documentPath: DocumentPath) -> Observable<E?> {
        let typeString = String(describing: E.self)
        guard let mockFunction = mock.observeDocument.typeMap[typeString] as? MockFunction<(DocumentPath) -> Observable<E?>> else {
            XCTFail("mock for observeDocument is not installed")
            fatalError()
        }
        return mockFunction.call(documentPath)
    }
    
    func observeCollection<E: Entity>(matches query: DataStoreQuery) -> Observable<CollectionChange<E>> {
        let typeString = String(describing: E.self)
        guard let mockFunction = mock.observeCollection.typeMap[typeString] as? MockFunction<(DataStoreQuery) -> Observable<CollectionChange<E>>> else {
            XCTFail("mock for observeCollection is not installed")
            fatalError()
        }
        return mockFunction.call(query)
    }
    
    func write(block: @escaping (DocumentWriter) throws -> Void) -> Completable {
        return mock.write.call(block)
    }
}

enum MockDataStorePlaceholder {
    case deletePlaceholder
    case serverTimestampPlaceholder
}

class MockDataStoreQuery: DataStoreQuery {
    class Mock {
        var whereFieldIsEqualTo = MockFunction<(String, Any) -> DataStoreQuery>("MockDataStoreQuery.whereFieldIsEqualTo")
        var whereFieldIsLessThan = MockFunction<(String, Any) -> DataStoreQuery>("MockDataStoreQuery.whereFieldIsLessThan")
        var whereFieldIsLessThanOrEqualTo = MockFunction<(String, Any) -> DataStoreQuery>("MockDataStoreQuery.whereFieldIsLessThanOrEqualTo")
        var whereFieldIsGreaterThan = MockFunction<(String, Any) -> DataStoreQuery>("MockDataStoreQuery.whereFieldIsGreaterThan")
        var whereFieldIsGreaterThanOrEqualTo = MockFunction<(String, Any) -> DataStoreQuery>("MockDataStoreQuery.whereFieldIsGreaterThanOrEqualTo")
        var orderBy = MockFunction<(String) -> DataStoreQuery>("MockDataStoreQuery.orderBy")
        var orderByDescending = MockFunction<(String, Bool) -> DataStoreQuery>("MockDataStoreQuery.orderByDescending")
        
        init(path: String) {
            whereFieldIsEqualTo.setup { (field, value) in return MockDataStoreQuery(path: path + "?\(field)=={\(value)}") }
            whereFieldIsLessThan.setup { (field, value) in return MockDataStoreQuery(path: path + "?\(field)<{\(value)}") }
            whereFieldIsLessThanOrEqualTo.setup { (field, value) in return MockDataStoreQuery(path: path + "?\(field)<={\(value)}") }
            whereFieldIsGreaterThan.setup { (field, value) in return MockDataStoreQuery(path: path + "?\(field)>{\(value)}") }
            whereFieldIsGreaterThanOrEqualTo.setup { (field, value) in return MockDataStoreQuery(path: path + "?\(field)>={\(value)}") }
            orderBy.setup { (field) in return MockDataStoreQuery(path: path + "@\(field):asc") }
            orderByDescending.setup { (field, isDescending) in
                let direction = isDescending ? "desc" : "asc"
                return MockDataStoreQuery(path: path + "@\(field):\(direction)")
            }
        }
    }
    let mock: Mock
    let path: String
    init(path: String = "") {
        mock = Mock(path: path)
        self.path = path
    }

    func whereField(_ field: String, isEqualTo value: Any) -> DataStoreQuery {
        return mock.whereFieldIsEqualTo.call(field, value)
    }
    func whereField(_ field: String, isLessThan value: Any) -> DataStoreQuery {
        return mock.whereFieldIsLessThan.call(field, value)
    }
    func whereField(_ field: String, isLessThanOrEqualTo value: Any) -> DataStoreQuery {
        return mock.whereFieldIsLessThanOrEqualTo.call(field, value)
    }
    func whereField(_ field: String, isGreaterThan value: Any) -> DataStoreQuery {
        return mock.whereFieldIsGreaterThan.call(field, value)
    }
    func whereField(_ field: String, isGreaterThanOrEqualTo value: Any) -> DataStoreQuery {
        return mock.whereFieldIsGreaterThanOrEqualTo.call(field, value)
    }

    func order(by field: String) -> DataStoreQuery {
        return mock.orderBy.call(field)
    }
    func order(by field: String, descending: Bool) -> DataStoreQuery {
        return mock.orderByDescending.call(field, descending)
    }
}

class MockCollectionPath: CollectionPath {
    class Mock: MockDataStoreQuery.Mock {
        var collectionID = MockFunction<() -> String>("MockCollectionPath.collectionID")
        var document = MockFunction<() -> DocumentPath>("MockCollectionPath.document")
        var documentForID = MockFunction<(String) -> DocumentPath>("MockCollectionPath.documentForID")
        
        override init(path: String) {
            collectionID.setup { return String(path.split(separator: "/", omittingEmptySubsequences: false).last!) }
            document.setup { return MockDocumentPath(path: path + "/\(UUID().uuidString)") }
            documentForID.setup { return MockDocumentPath(path: path + "/\($0)") }
            super.init(path: path)
        }
    }
    let mock: Mock
    let path: String
    init(path: String) {
        mock = Mock(path: path)
        self.path = path
    }

    func whereField(_ field: String, isEqualTo value: Any) -> DataStoreQuery {
        return mock.whereFieldIsEqualTo.call(field, value)
    }
    func whereField(_ field: String, isLessThan value: Any) -> DataStoreQuery {
        return mock.whereFieldIsLessThan.call(field, value)
    }
    func whereField(_ field: String, isLessThanOrEqualTo value: Any) -> DataStoreQuery {
        return mock.whereFieldIsLessThanOrEqualTo.call(field, value)
    }
    func whereField(_ field: String, isGreaterThan value: Any) -> DataStoreQuery {
        return mock.whereFieldIsGreaterThan.call(field, value)
    }
    func whereField(_ field: String, isGreaterThanOrEqualTo value: Any) -> DataStoreQuery {
        return mock.whereFieldIsGreaterThanOrEqualTo.call(field, value)
    }
    
    func order(by field: String) -> DataStoreQuery {
        return mock.orderBy.call(field)
    }
    func order(by field: String, descending: Bool) -> DataStoreQuery {
        return mock.orderByDescending.call(field, descending)
    }

    var collectionID: String {
        return mock.collectionID.call()
    }
    func document() -> DocumentPath {
        return mock.document.call()
    }
    func document(_ documentID: String) -> DocumentPath {
        return mock.documentForID.call(documentID)
    }
}

class MockDocumentPath: DocumentPath {
    class Mock {
        var documentID = MockFunction<() -> String>("MockDocumentPath.documentID")
        var collection = MockFunction<(String) -> CollectionPath>("MockDocumentPath.collection")

        init(path: String) {
            documentID.setup { return String(path.split(separator: "/", omittingEmptySubsequences: false).last!) }
            collection.setup { return MockCollectionPath(path: path + "/\($0)") }
        }
    }
    let mock: Mock
    let path: String
    init(path: String) {
        mock = Mock(path: path)
        self.path = path
    }

    var documentID: String {
        return mock.documentID.call()
    }
    func collection(_ collectionID: String) -> CollectionPath {
        return mock.collection.call(collectionID)
    }
}

class MockDocumentWriter: DocumentWriter {
    class Mock {
        var setDocumentData = MockFunction<([String: Any], DocumentPath) -> Void>("MockDocumentWriter.setDocumentData")
        var updateDocumentData = MockFunction<([String: Any], DocumentPath) -> Void>("MockDocumentWriter.updateDocumentData")
        var mergeDocumentData = MockFunction<([String: Any], DocumentPath) -> Void>("MockDocumentWriter.mergeDocumentData")
        var deleteDocument = MockFunction<(DocumentPath) -> Void>("MockDocumentWriter.deleteDocument")
    }
    let mock = Mock()

    func setDocumentData(_ documentData: [String: Any], at documentPath: DocumentPath) {
        mock.setDocumentData.call(documentData, documentPath)
    }
    func updateDocumentData(_ documentData: [String: Any], at documentPath: DocumentPath) {
        mock.updateDocumentData.call(documentData, documentPath)
    }
    func mergeDocumentData(_ documentData: [String: Any], at documentPath: DocumentPath) {
        mock.mergeDocumentData.call(documentData, documentPath)
    }
    func deleteDocument(at documentPath: DocumentPath) {
        mock.deleteDocument.call(documentPath)
    }
}
