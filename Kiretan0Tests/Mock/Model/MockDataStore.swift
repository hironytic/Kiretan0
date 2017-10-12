//
// MockDataStore.swift
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

import Foundation
import RxSwift
import Diffitic
@testable import Kiretan0

public enum MockDataStoreError: Error {
    case documentNotFound(documentPathString: String)
}

public class MockDataStore: DataStore {
    private var result: [String: MockResultCollection]
    
    public init(initialCollections: [String: [String: [String:Any]]]) {
        result = [:]
        for collection in initialCollections {
            result[collection.key] = MockResultCollection(collectionPathString: collection.key,
                                                          initialDocuments: collection.value)
        }
    }
    
    public var deletePlaceholder: Any { return MockDataStorePlaceholder.deletePlaceholder }
    public var serverTimestampPlaceholder: Any { return MockDataStorePlaceholder.serverTimestampPlaceholder }
    
    public func collection(_ collectionID: String) -> CollectionPath {
        return MockRootCollectionPath(collectionID: collectionID)
    }

    public func observeDocument<E: Entity>(at documentPath: DocumentPath) -> Observable<E?> {
        let mockDocumentPath = documentPath as! MockDocumentPath
        let collectionPathString = mockDocumentPath.basePath.pathString()
        let rc = resultCollection(for: collectionPathString)
        return rc.result
            .map { documents in
                return try documents[mockDocumentPath.documentID]
                    .map { try E.init(documentID: mockDocumentPath.documentID, data: $0) }
            }
    }
    
    public func observeCollection<E: Entity>(matches query: DataStoreQuery) -> Observable<CollectionChange<E>> {
        let mockQuery = query as! MockDataStoreQuery
        let areInIncreasingOrder = { (result1: MockResultDocument, result2: MockResultDocument) -> Bool in
            return result1.documentID < result2.documentID
        }
        let isIncluded = { (_: MockResultDocument) -> Bool in return true }
        return mockQuery.observe(dataStore: self, sortedBy: areInIncreasingOrder, filteredBy: isIncluded)
            .scan(CollectionChange<MockResultDocument>(result: [], deletions:[], insertions:[], modifications:[])) { acc, result in
                return self.detectChanges(prev: acc.result, next: result)
            }
            .map { change in
                let mockResultDocuments = change.result
                let entities = try mockResultDocuments.map { doc in try E.init(documentID: doc.documentID, data: doc.data) }
                return CollectionChange(result: entities, deletions: change.deletions, insertions: change.insertions, modifications: change.modifications)
            }
    }
    
    private func detectChanges(prev: [MockResultDocument], next: [MockResultDocument]) -> CollectionChange<MockResultDocument> {
        let diffResult = diff(leftCount: prev.count, rightCount: next.count) { prevIndex, nextIndex in
            return prev[prevIndex].documentID == next[nextIndex].documentID
        }
        var deletions = [Int]()
        var insertions = [Int]()
        var modifications = [Int]()
        for (type, prevIndex, prevCount, nextIndex, nextCount) in diffResult {
            switch type {
            case .inserted:
                insertions.append(contentsOf: nextIndex ..< nextIndex + nextCount)
            case .deleted:
                deletions.append(contentsOf: prevIndex ..< prevIndex + prevCount)
            case .replaced:
                insertions.append(contentsOf: nextIndex ..< nextIndex + nextCount)
                deletions.append(contentsOf: prevIndex ..< prevIndex + prevCount)
            case .identical:
                break   // FIXME:
            }
        }
        return CollectionChange(result: next, deletions: deletions, insertions: insertions, modifications: modifications)
    }
    
    public func write(block: @escaping (DocumentWriter) throws -> Void) -> Completable {
        return Completable.create { observer in
            let writer = MockDocumentWriter(dataStore: self)
            do {
                try block(writer)
            } catch let error {
                observer(.error(error))
            }
            writer.execute()
            observer(.completed)
            
            return Disposables.create()
        }
    }
    
    fileprivate func resultCollection(for collectionPathString: String) -> MockResultCollection {
        if let resultCollection = result[collectionPathString] {
            return resultCollection
        } else {
            let newCollection = MockResultCollection(collectionPathString: collectionPathString,
                                                     initialDocuments: [:])
            result[collectionPathString] = newCollection
            return newCollection
        }
    }
}

private enum MockDataStorePlaceholder {
    case deletePlaceholder
    case serverTimestampPlaceholder
}

private class MockDataStoreQuery: DataStoreQuery {
    public func whereField(_ field: String, isEqualTo value: Any) -> DataStoreQuery {
        return MockFilterQuery(baseQuery: self, field: field, op: .equalTo, operand: value)
    }
    
    public func whereField(_ field: String, isLessThan value: Any) -> DataStoreQuery {
        return MockFilterQuery(baseQuery: self, field: field, op: .lessThan, operand: value)
    }
    
    public func whereField(_ field: String, isLessThanOrEqualTo value: Any) -> DataStoreQuery {
        return MockFilterQuery(baseQuery: self, field: field, op: .lessThanOrEqualTo, operand: value)
    }
    
    public func whereField(_ field: String, isGreaterThan value: Any) -> DataStoreQuery {
        return MockFilterQuery(baseQuery: self, field: field, op: .greaterThan, operand: value)
    }
    
    public func whereField(_ field: String, isGreaterThanOrEqualTo value: Any) -> DataStoreQuery {
        return MockFilterQuery(baseQuery: self, field: field, op: .greaterThanOrEqualTo, operand: value)
    }
    
    public func order(by field: String) -> DataStoreQuery {
        return MockOrderQuery(baseQuery: self, field: field, isDescending: false)
    }
    
    public func order(by field: String, descending: Bool) -> DataStoreQuery {
        return MockOrderQuery(baseQuery: self, field: field, isDescending: descending)
    }
    
    public func observe(dataStore: MockDataStore,
                        sortedBy areInIncreasingOrder: @escaping (MockResultDocument, MockResultDocument) -> Bool,
                        filteredBy isIncluded: @escaping (MockResultDocument) -> Bool) -> Observable<[MockResultDocument]> {
        fatalError("method should be overriden")
    }
}

private func compareValues(_ value1: Any, _ value2: Any) -> ComparisonResult {
    let typeOrder = { (value: Any) -> Int in
        switch value {
        case is NSNull:
            return 0
        case is Int:
            return 1
        case is Date:
            return 2
        case is Bool:
            return 3
        case is String:
            return 4
        case is Double:
            return 5
        default:
            return 100
        }
    }

    let typeOrder1 = typeOrder(value1)
    let typeOrder2 = typeOrder(value2)
    if typeOrder1 < typeOrder2 {
        return .orderedAscending
    } else if typeOrder1 > typeOrder2 {
        return .orderedDescending
    } else {
        switch value1 {
        case is NSNull:
            return .orderedSame
            
        case is Int:
            let v1 = value1 as! Int
            let v2 = value2 as! Int
            if v1 < v2 {
                return .orderedAscending
            } else if v1 > v2 {
                return .orderedDescending
            } else {
                return .orderedSame
            }
            
        case is Date:
            let v1 = value1 as! Date
            let v2 = value2 as! Date
            if v1 < v2 {
                return .orderedAscending
            } else if v1 > v2 {
                return .orderedDescending
            } else {
                return .orderedSame
            }
        case is Bool:
            let v1 = value1 as! Bool
            let v2 = value2 as! Bool
            if v1 == v2 {
                return .orderedSame
            } else if !v1 {
                return .orderedAscending
            } else {
                return .orderedDescending
            }

        case is String:
            let v1 = value1 as! String
            let v2 = value2 as! String
            if v1 < v2 {
                return .orderedAscending
            } else if v1 > v2 {
                return .orderedDescending
            } else {
                return .orderedSame
            }

        case is Double:
            let v1 = value1 as! Double
            let v2 = value2 as! Double
            if v1 < v2 {
                return .orderedAscending
            } else if v1 > v2 {
                return .orderedDescending
            } else {
                return .orderedSame
            }

        default:
            return .orderedSame
        }
    }
    
}

private enum FilterOperator {
    case equalTo
    case lessThan
    case lessThanOrEqualTo
    case greaterThan
    case greaterThanOrEqualTo
}

private class MockFilterQuery: MockDataStoreQuery {
    private let baseQuery: MockDataStoreQuery
    private let field: String
    private let op: FilterOperator
    private let operand: Any
    
    public init(baseQuery: MockDataStoreQuery, field: String, op: FilterOperator, operand: Any) {
        self.baseQuery = baseQuery
        self.field = field
        self.op = op
        self.operand = operand
    }
    
    public override func observe(dataStore: MockDataStore,
                                 sortedBy areInIncreasingOrder: @escaping (MockResultDocument, MockResultDocument) -> Bool,
                                 filteredBy isIncluded: @escaping (MockResultDocument) -> Bool) -> Observable<[MockResultDocument]> {
        return baseQuery.observe(dataStore: dataStore, sortedBy: areInIncreasingOrder, filteredBy: { document in
            return self.filterResultDocument(document) && isIncluded(document)
        })
    }
    
    private func filterResultDocument(_ document: MockResultDocument) -> Bool {
        let value = document.data[field] ?? NSNull()
        let cr = compareValues(value, operand)
        switch op {
        case .equalTo:
            return cr == .orderedSame
        case .lessThan:
            return cr == .orderedAscending
        case .lessThanOrEqualTo:
            return cr == .orderedAscending || cr == .orderedSame
        case .greaterThan:
            return cr == .orderedDescending
        case .greaterThanOrEqualTo:
            return cr == .orderedDescending || cr == .orderedSame
        }
    }
}

private class MockOrderQuery: MockDataStoreQuery {
    private let baseQuery: MockDataStoreQuery
    private let field: String
    private let isDescending: Bool
    
    public init(baseQuery: MockDataStoreQuery, field: String, isDescending: Bool) {
        self.baseQuery = baseQuery
        self.field = field
        self.isDescending = isDescending
    }
    
    public override func observe(dataStore: MockDataStore,
                                 sortedBy areInIncreasingOrder: @escaping (MockResultDocument, MockResultDocument) -> Bool,
                                 filteredBy isIncluded: @escaping (MockResultDocument) -> Bool) -> Observable<[MockResultDocument]> {
        return baseQuery.observe(dataStore: dataStore, sortedBy: { document1, document2 in
            let cr = self.compareResultDocuments(document1, document2)
            switch cr {
            case .orderedAscending:
                return true
            case .orderedDescending:
                return false
            case .orderedSame:
                return areInIncreasingOrder(document1, document2)
            }
        }, filteredBy: isIncluded)
    }
    
    private func compareResultDocuments(_ document1: MockResultDocument, _ document2: MockResultDocument) -> ComparisonResult {
        let value1 = document1.data[field] ?? NSNull()
        let value2 = document2.data[field] ?? NSNull()
        let cr = compareValues(value1, value2)
        if isDescending {
            switch cr {
            case .orderedAscending:
                return .orderedDescending
            case .orderedDescending:
                return .orderedAscending
            case .orderedSame:
                return .orderedSame
            }
        } else {
            return cr
        }
    }
}

private protocol MockCollectionPath: CollectionPath {
    func pathString() -> String
}

private extension MockCollectionPath {
    func document() -> DocumentPath {
        return document(UUID().uuidString)
    }
    
    func document(_ documentID: String) -> DocumentPath {
        return MockDocumentPath(basePath: self, documentID: documentID)
    }
}

private class MockCollectionPathBase: MockDataStoreQuery, MockCollectionPath {
    public let collectionID: String

    public init(collectionID: String) {
        self.collectionID = collectionID
    }
    
    public func pathString() -> String {
        fatalError("method should be overriden")
    }
    
    public override func observe(dataStore: MockDataStore,
                                 sortedBy areInIncreasingOrder: @escaping (MockResultDocument, MockResultDocument) -> Bool,
                                 filteredBy isIncluded: @escaping (MockResultDocument) -> Bool) -> Observable<[MockResultDocument]> {
        let resultCollection = dataStore.resultCollection(for: pathString())
        return resultCollection.result
            .map { result in
                let filtered: [String: [String: Any]] = result.filter { isIncluded(MockResultDocument(documentID: $0.key, data: $0.value)) }
                return filtered
                    .sorted { keyValue1, keyValue2 in
                        return areInIncreasingOrder(MockResultDocument(documentID: keyValue1.key, data: keyValue1.value),
                                                    MockResultDocument(documentID: keyValue2.key, data: keyValue2.value))
                    }
                    .map { MockResultDocument(documentID: $0.key, data: $0.value) }
            }
    }
}

private class MockRootCollectionPath: MockCollectionPathBase {
    public override func pathString() -> String {
        return "/\(collectionID)"
    }
}

private class MockSubcollectionPath: MockCollectionPathBase {
    private let basePath: MockDocumentPath
    public init(basePath: MockDocumentPath, collectionID: String) {
        self.basePath = basePath
        super.init(collectionID: collectionID)
    }
    
    public override func pathString() -> String {
        return "\(basePath.pathString())/\(collectionID)"
    }
}

private class MockDocumentPath: DocumentPath {
    public let basePath: MockCollectionPath
    public let documentID: String
    
    public init(basePath: MockCollectionPath, documentID: String) {
        self.basePath = basePath
        self.documentID = documentID
    }
    
    public func collection(_ collectionID: String) -> CollectionPath {
        return MockSubcollectionPath(basePath: self, collectionID: collectionID)
    }
    
    public func pathString() -> String {
        return "\(basePath.pathString())/\(documentID)"
    }
}

private class MockDocumentWriter: DocumentWriter {
    private let dataStore: MockDataStore
    private var actionsForCollection: [String: [MockDocumentWritingAction]] = [:]

    public init(dataStore: MockDataStore) {
        self.dataStore = dataStore
    }
    
    private func appendAction(_ action: MockDocumentWritingAction, for collectionPath: MockCollectionPath) {
        let pathString = collectionPath.pathString()
        var actions = actionsForCollection[pathString] ?? []
        actions.append(action)
        actionsForCollection[pathString] = actions
    }
    
    public func setDocumentData(_ documentData: [String: Any], at documentPath: DocumentPath) {
        let documentPath = documentPath as! MockDocumentPath
        appendAction(.set(documentID: documentPath.documentID, data: documentData),
                     for: documentPath.basePath)
    }
    
    public func updateDocumentData(_ documentData: [String: Any], at documentPath: DocumentPath) {
        let documentPath = documentPath as! MockDocumentPath
        appendAction(.update(documentID: documentPath.documentID, fields: documentData),
                     for: documentPath.basePath)
    }
    
    public func mergeDocumentData(_ documentData: [String: Any], at documentPath: DocumentPath) {
        let documentPath = documentPath as! MockDocumentPath
        appendAction(.merge(documentID: documentPath.documentID, fields: documentData),
                     for: documentPath.basePath)
    }
    
    public func deleteDocument(at documentPath: DocumentPath) {
        let documentPath = documentPath as! MockDocumentPath
        appendAction(.delete(documentID: documentPath.documentID),
                     for: documentPath.basePath)
    }

    public func execute() {
        for (collectionPathString, actions) in actionsForCollection {
            let resultCollection = dataStore.resultCollection(for: collectionPathString)
            resultCollection.executeActions(actions)
        }
    }
}

private enum MockDocumentWritingAction {
    case set(documentID: String, data: [String: Any])
    case update(documentID: String, fields: [String: Any])
    case merge(documentID: String, fields: [String: Any])
    case delete(documentID: String)
}

private class MockResultCollection {
    private let collectionPathString: String
    private let actionSubject = PublishSubject<[MockDocumentWritingAction]>()
    public let result: Observable<[String: [String: Any]]>
    
    public init(collectionPathString: String, initialDocuments: [String: [String: Any]]) {
        self.collectionPathString = collectionPathString
        result = actionSubject
            .scan(initialDocuments) { (acc, actions) -> [String: [String: Any]] in
                var acc = acc
                for action in actions {
                    switch action {
                    case .set(let documentID, let data):
                        acc[documentID] = data
                    case .update(let documentID, let fields):
                        if let old = acc[documentID] {
                            let merged = old.merging(fields) { (_, new) in new }
                            acc[documentID] = merged
                        } else {
                            throw MockDataStoreError.documentNotFound(documentPathString: "\(collectionPathString)/\(documentID)")
                        }
                    case .merge(let documentID, let fields):
                        if let old = acc[documentID] {
                            let merged = old.merging(fields) { (_, new) in new }
                            acc[documentID] = merged
                        } else {
                            acc[documentID] = fields
                        }
                    case .delete(let documentID):
                        acc.removeValue(forKey: documentID)
                    }
                }
                return acc
            }
            .startWith(initialDocuments)
            .share(replay: 1, scope: .forever)
    }
    
    public func executeActions(_ actions: [MockDocumentWritingAction]) {
        actionSubject.onNext(actions)
    }
}

private struct MockResultDocument {
    public let documentID: String
    public let data: [String: Any]
}
