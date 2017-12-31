//
// MockItemRepository.swift
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
import RxCocoa
@testable import Kiretan0

class MockItemRepository: ItemRepository {
    class Mock {
        var items = MockFunction<(String, Bool) -> Observable<CollectionChange<Item>>>("MockItemRepository.items")
        var createItem = MockFunction<(Item, String) -> Single<String>>("MockItemRepository.createItem")
        var updateItem = MockFunction<(Item, String) -> Completable>("MockItemRepository.updateItem")
        var removeItem = MockFunction<(String, String) -> Completable>("MockItemRepository.removeItem")
    }
    let mock = Mock()

    init() {
    }
    
    func items(in teamID: String, insufficient: Bool) -> Observable<CollectionChange<Item>> {
        return mock.items.call(teamID, insufficient)
    }
    
    func createItem(_ item: Item, in teamID: String) -> Single<String> {
        return mock.createItem.call(item, teamID)
    }
    
    func updateItem(_ item: Item, in teamID: String) -> Completable {
        return mock.updateItem.call(item, teamID)
    }
    
    func removeItem(_ itemID: String, in teamID: String) -> Completable {
        return mock.removeItem.call(itemID, teamID)
    }
}
