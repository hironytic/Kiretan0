//
// DataStore.swift
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
import FirebaseFirestore
import RxSwift

public protocol DataStore {
    var deletePlaceholder: Any { get }
    var serverTimestampPlaceholder: Any { get }
    
    func collection(_ collectionID: String) -> CollectionPath
    
    func observeDocument<E: Entity>(at documentPath: DocumentPath) -> Observable<E?>
    func observeCollection<E: Entity>(matches query: DataStoreQuery) -> Observable<CollectionChange<E>>
    
    func write(block: @escaping (DocumentWriter) throws -> Void) -> Completable
}

public protocol DataStoreQuery {
    func whereField(_ field: String, isEqualTo value: Any) -> DataStoreQuery
    func whereField(_ field: String, isLessThan value: Any) -> DataStoreQuery
    func whereField(_ field: String, isLessThanOrEqualTo value: Any) -> DataStoreQuery
    func whereField(_ field: String, isGreaterThan value: Any) -> DataStoreQuery
    func whereField(_ field: String, isGreaterThanOrEqualTo value: Any) -> DataStoreQuery
    
    func order(by field: String) -> DataStoreQuery
    func order(by field: String, descending: Bool) -> DataStoreQuery
}

public protocol CollectionPath: DataStoreQuery {
    var collectionID: String { get }
    func document() -> DocumentPath
    func document(_ documentID: String) -> DocumentPath
}

public protocol DocumentPath {
    var documentID: String { get }
    func collection(_ collectionID: String) -> CollectionPath
}

public protocol DocumentWriter {
    func setDocumentData(_ documentData: [String: Any], at documentPath: DocumentPath)
    func updateDocumentData(_ documentData: [String: Any], at documentPath: DocumentPath)
    func mergeDocumentData(_ documentData: [String: Any], at documentPath: DocumentPath)
    func deleteDocument(at documentPath: DocumentPath)
}

public protocol DataStoreResolver {
    func resolveDataStore() -> DataStore
}

extension DefaultResolver: DataStoreResolver {
    public func resolveDataStore() -> DataStore {
        return DefaultDataStore(resolver: self)
    }
}

public class DefaultDataStore: DataStore {
    public typealias Resolver = NullResolver

    private let _resolver: Resolver
    
    public init(resolver: Resolver) {
        _resolver = resolver
    }
    
    public var deletePlaceholder: Any {
        return FieldValue.delete()
    }
    
    public var serverTimestampPlaceholder: Any {
        return FieldValue.serverTimestamp()
    }

    public func collection(_ collectionID: String) -> CollectionPath {
        return DefaultCollectionPath(Firestore.firestore().collection(collectionID))
    }
    
    public func observeDocument<E: Entity>(at documentPath: DocumentPath) -> Observable<E?> {
        return Observable.create { observer in
            let listener = (documentPath as! DefaultDocumentPath).documentRef.addSnapshotListener { (documentSnapshot, error) in
                if let error = error {
                    observer.onError(error)
                } else {
                    let dSnapshot = documentSnapshot!
                    if dSnapshot.exists {
                        do {
                            let entity = try E.init(raw: RawEntity(documentID: dSnapshot.documentID, data: dSnapshot.data()))
                            observer.onNext(entity)
                        } catch let error {
                            observer.onError(error)
                        }
                    } else {
                        observer.onNext(nil)
                    }
                }
            }
            return Disposables.create {
                listener.remove()
            }
        }
    }

    private class ChangeTarget: Hashable {
        var prevIndex: Int = NSNotFound
        let currentIndex: Int
        init(currentIndex: Int = NSNotFound) {
            self.currentIndex = currentIndex
        }

        var hashValue: Int { return 0 }
        static func ==(lhs: ChangeTarget, rhs: ChangeTarget) -> Bool {
            return lhs === rhs
        }
    }
    
    public func observeCollection<E: Entity>(matches query: DataStoreQuery) -> Observable<CollectionChange<E>> {
        return Observable.create { observer in
            let listener = (query as! DefaultDataStoreQuery).query.addSnapshotListener{ (querySnapshot, error) in
                if let error = error {
                    observer.onError(error)
                } else {
                    do {
                        let qSnapshot = querySnapshot!
                        let result = try qSnapshot.documents.map { try E.init(raw: RawEntity(documentID: $0.documentID, data: $0.data())) }

                        // simulate targets location by applying changes in reverse order
                        // so that we get original indices in previous snapshot
                        var targets = Set<ChangeTarget>()
                        var collection = result.enumerated().map { ChangeTarget(currentIndex: $0.0) }
                        for change in qSnapshot.documentChanges.reversed() {
                            let ct: ChangeTarget
                            switch change.type {
                            case .added:
                                let nx = Int(change.newIndex)
                                ct = collection.remove(at: nx)
                                
                            case .removed:
                                let ox = Int(change.oldIndex)
                                ct = ChangeTarget()
                                collection.insert(ct, at: ox)
                                
                            case .modified:
                                let nx = Int(change.newIndex)
                                let ox = Int(change.oldIndex)
                                ct = collection.remove(at: nx)
                                collection.insert(ct, at: ox)
                            }
                            targets.insert(ct)
                        }
                        for (i, target) in collection.enumerated() {
                            target.prevIndex = i
                        }
                        
                        let deletions = targets.filter { $0.prevIndex != NSNotFound && $0.currentIndex == NSNotFound }.map { $0.prevIndex }.sorted()
                        let modifications = targets.filter { $0.prevIndex != NSNotFound && $0.currentIndex != NSNotFound }.map { ($0.prevIndex, $0.currentIndex) }.sorted { $0.0 < $1.0 }
                        let insertions = targets.filter { $0.prevIndex == NSNotFound && $0.currentIndex != NSNotFound }.map { $0.currentIndex }.sorted()
                        observer.onNext(CollectionChange(result: result, deletions: deletions, insertions: insertions, modifications: modifications))
                    } catch let error {
                        observer.onError(error)
                    }
                }
            }
            return Disposables.create {
                listener.remove()
            }
        }
    }
    
    public func write(block: @escaping (DocumentWriter) throws -> Void) -> Completable {
        return Completable.create { observer in
            let batch = Firestore.firestore().batch()
            let writer = DefaultDocumentWriter(batch)
            do {
                try block(writer)
            } catch let error {
                observer(.error(error))
            }
            batch.commit { error in
                if let error = error {
                    observer(.error(error))
                } else {
                    observer(.completed)
                }
            }
            
            return Disposables.create()
        }
    }
}

private class DefaultDataStoreQuery: DataStoreQuery {
    public let query: Query
    
    public init(_ query: Query) {
        self.query = query
    }
    
    public func whereField(_ field: String, isEqualTo value: Any) -> DataStoreQuery {
        return DefaultDataStoreQuery(query.whereField(field, isEqualTo: value))
    }
    
    public func whereField(_ field: String, isLessThan value: Any) -> DataStoreQuery {
        return DefaultDataStoreQuery(query.whereField(field, isLessThan: value))
    }
    
    public func whereField(_ field: String, isLessThanOrEqualTo value: Any) -> DataStoreQuery {
        return DefaultDataStoreQuery(query.whereField(field, isLessThanOrEqualTo: value))
    }
    
    public func whereField(_ field: String, isGreaterThan value: Any) -> DataStoreQuery {
        return DefaultDataStoreQuery(query.whereField(field, isGreaterThan: value))
    }
    
    public func whereField(_ field: String, isGreaterThanOrEqualTo value: Any) -> DataStoreQuery {
        return DefaultDataStoreQuery(query.whereField(field, isGreaterThanOrEqualTo: value))
    }
    
    public func order(by field: String) -> DataStoreQuery {
        return DefaultDataStoreQuery(query.order(by: field))
    }
    
    public func order(by field: String, descending: Bool) -> DataStoreQuery {
        return DefaultDataStoreQuery(query.order(by: field, descending: descending))
    }
}

private class DefaultCollectionPath: DefaultDataStoreQuery, CollectionPath {
    public var collectionRef: CollectionReference {
        return query as! CollectionReference
    }
    
    public init(_ collectionRef: CollectionReference) {
        super.init(collectionRef)
    }
    
    public var collectionID: String {
        return collectionRef.collectionID
    }
    
    public func document() -> DocumentPath {
        return DefaultDocumentPath(collectionRef.document())
    }
    
    func document(_ documentID: String) -> DocumentPath {
        return DefaultDocumentPath(collectionRef.document(documentID))
    }
}

private class DefaultDocumentPath: DocumentPath {
    public let documentRef: DocumentReference
    
    public init(_ documentRef: DocumentReference) {
        self.documentRef = documentRef
    }
    
    public var documentID: String {
        return documentRef.documentID
    }
    
    func collection(_ collectionID: String) -> CollectionPath {
        return DefaultCollectionPath(documentRef.collection(collectionID))
    }
}

private class DefaultDocumentWriter: DocumentWriter {
    public let writeBatch: WriteBatch
    
    public init(_ writeBatch: WriteBatch) {
        self.writeBatch = writeBatch
    }
    
    public func setDocumentData(_ documentData: [String: Any], at documentPath: DocumentPath) {
        writeBatch.setData(documentData, forDocument: (documentPath as! DefaultDocumentPath).documentRef)
    }
    
    public func updateDocumentData(_ documentData: [String: Any], at documentPath: DocumentPath) {
        writeBatch.updateData(documentData, forDocument: (documentPath as! DefaultDocumentPath).documentRef)
    }
    
    public func mergeDocumentData(_ documentData: [String: Any], at documentPath: DocumentPath) {
        writeBatch.setData(documentData, forDocument: (documentPath as! DefaultDocumentPath).documentRef, options: SetOptions.merge())
    }
    
    public func deleteDocument(at documentPath: DocumentPath) {
        writeBatch.deleteDocument((documentPath as! DefaultDocumentPath).documentRef)
    }
}
