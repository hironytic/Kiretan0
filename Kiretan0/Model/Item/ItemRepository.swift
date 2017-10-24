//
// ItemRepository.swift
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

public protocol ItemRepository {
    func items(in teamID: String, insufficient: Bool) -> Observable<CollectionChange<Item>>
    
    func createItem(_ item: Item, in teamID: String) -> Single<String>
    func updateItem(_ item: Item, in teamID: String) -> Completable
    func removeItem(_ itemID: String, in teamID: String) -> Completable
}

public protocol ItemRepositoryResolver {
    func resolveItemRepository() -> ItemRepository
}

extension DefaultResolver: ItemRepositoryResolver {
    public func resolveItemRepository() -> ItemRepository {
        return DefaultItemRepository(resolver: self)
    }
}

public class DefaultItemRepository: ItemRepository {
    public typealias Resolver = DataStoreResolver

    private let _resolver: Resolver
    private let _dataStore: DataStore

    public init(resolver: Resolver) {
        _resolver = resolver
        _dataStore = _resolver.resolveDataStore()
    }
    
    public func items(in teamID: String, insufficient: Bool) -> Observable<CollectionChange<Item>> {
        let itemPath = _dataStore.collection("team").document(teamID).collection("item")
        let itemQuery = itemPath
            .whereField("insufficient", isEqualTo: insufficient)
            .order(by: "last_change", descending: true)
        return _dataStore.observeCollection(matches: itemQuery)
    }
    
    private func updateLastChange(_ data: [String: Any]) -> [String: Any] {
        var data = data
        data["last_change"] = _dataStore.serverTimestampPlaceholder
        return data
    }
    
    public func createItem(_ item: Item, in teamID: String) -> Single<String> {
        let itemPath = _dataStore.collection("team").document(teamID).collection("item").document()
        let itemID = itemPath.documentID
        return _dataStore.write { writer in
            writer.setDocumentData(self.updateLastChange(item.rawEntity.data), at: itemPath)
        }.andThen(Single.just(itemID))
    }
    
    public func updateItem(_ item: Item, in teamID: String) -> Completable {
        let itemPath = _dataStore.collection("team").document(teamID).collection("item").document(item.itemID)
        return _dataStore.write { writer in
            writer.updateDocumentData(self.updateLastChange(item.rawEntity.data), at: itemPath)
        }
    }

    public func removeItem(_ itemID: String, in teamID: String) -> Completable {
        let itemPath = _dataStore.collection("team").document(teamID).collection("item").document(itemID)
        return _dataStore.write { writer in
            writer.deleteDocument(at: itemPath)
        }
    }
}
