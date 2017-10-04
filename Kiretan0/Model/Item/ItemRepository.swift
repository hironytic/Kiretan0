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
import FirebaseAuth
import FirebaseDatabase
import RxSwift

public protocol ItemRepository {
//    func items(in teamID: String) -> Observable<CollectionEvent<Item>>
//
//    func createItem(_ item: Item, in teamID: String) -> Single<String>
//    func updateItem(_ item: Item, in teamID: String) -> Completable
//    func removeItem(_ itemID: String, in teamID: String) -> Completable
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
    public typealias Resolver = NullResolver

    private let _resolver: Resolver
    
    public init(resolver: Resolver) {
        _resolver = resolver
    }
    
//    public func items(in teamID: String) -> Observable<CollectionEvent<Item>> {
//        let itemsRef = Database.database().reference().child("items").child(teamID)
//        let query = itemsRef.queryOrdered(byChild: "last_change")
//        return query.createChildCollectionObservable()
//    }
//
//    public func createItem(_ item: Item, in teamID: String) -> Single<String> {
//        guard Auth.auth().currentUser != nil else {
//            return Single.error(TeamRepositoryError.notAuthenticated)
//        }
//        return Single.create { observer in
//            let itemsRef = Database.database().reference().child("items").child(teamID)
//            let itemID = itemsRef.childByAutoId().key
//
//            itemsRef.child(itemID).setValue(item.value) { (error, _) in
//                if let error = error {
//                    observer(.error(error))
//                } else {
//                    observer(.success(itemID))
//                }
//            }
//            return Disposables.create()
//        }
//    }
//
//    public func updateItem(_ item: Item, in teamID: String) -> Completable {
//        guard Auth.auth().currentUser != nil else {
//            return Completable.error(TeamRepositoryError.notAuthenticated)
//        }
//        return Completable.create { observer in
//            let itemRef = Database.database().reference().child("items").child(teamID).child(item.itemID)
//            itemRef.setValue(item.value) { (error, _) in
//                if let error = error {
//                    observer(.error(error))
//                } else {
//                    observer(.completed)
//                }
//            }
//            return Disposables.create()
//        }
//    }
//
//    public func removeItem(_ itemID: String, in teamID: String) -> Completable {
//        guard Auth.auth().currentUser != nil else {
//            return Completable.error(TeamRepositoryError.notAuthenticated)
//        }
//        return Completable.create { observer in
//            let itemRef = Database.database().reference().child("items").child(teamID).child(itemID)
//            itemRef.removeValue { (error, _) in
//                if let error = error {
//                    observer(.error(error))
//                } else {
//                    observer(.completed)
//                }
//            }
//            return Disposables.create()
//        }
//    }
}
