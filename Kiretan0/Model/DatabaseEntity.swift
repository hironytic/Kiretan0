//
// DatabaseEntity.swift
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
import FirebaseDatabase
import RxSwift

public protocol DatabaseEntity {
    init(key: String, value: Any) throws
    
    var key: String { get }
    var value: Any { get }
}

public extension DatabaseQuery {
    func createObservable<Entity: DatabaseEntity>() -> Observable<Entity?> {
        return Observable.create { observer in
            let handle = self.observe(.value) { snapshot in
                if !snapshot.exists() {
                    observer.onNext(nil)
                } else {
                    do {
                        let entity = try Entity.init(key: snapshot.key, value: snapshot.value!)
                        observer.onNext(entity)
                    } catch (let error) {
                        observer.onError(error)
                    }
                }
            }
            return Disposables.create {
                self.removeObserver(withHandle: handle)
            }
        }
    }
    
    func createChildCollectionObservable<Entity: DatabaseEntity>() -> Observable<CollectionEvent<Entity>> {
        return Observable.create { observer in
            let addedHandle = self.observe(.childAdded) { (snapshot, prevKey) in
                do {
                    let entity = try Entity.init(key: snapshot.key, value: snapshot.value!)
                    observer.onNext(.added(entity, prevKey))
                } catch (let error) {
                    observer.onError(error)
                }
            }
            let removedHandle = self.observe(.childRemoved) { snapshot in
                do {
                    let entity = try Entity.init(key: snapshot.key, value: snapshot.value!)
                    observer.onNext(.removed(entity))
                } catch (let error) {
                    observer.onError(error)
                }
            }
            let changedHandle = self.observe(.childChanged) { snapshot in
                do {
                    let entity = try Entity.init(key: snapshot.key, value: snapshot.value!)
                    observer.onNext(.changed(entity))
                } catch (let error) {
                    observer.onError(error)
                }
            }
            return Disposables.create {
                self.removeObserver(withHandle: addedHandle)
                self.removeObserver(withHandle: removedHandle)
                self.removeObserver(withHandle: changedHandle)
            }
        }
    }
}
