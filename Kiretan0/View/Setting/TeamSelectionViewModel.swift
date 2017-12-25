//
// TeamSelectionViewModel.swift
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

public protocol TeamSelectionViewModel: ViewModel {
    var tableData: Observable<[TableSectionViewModel]> { get }
}

public protocol TeamSelectionViewModelResolver {
    func resolveTeamSelectionViewModel() -> TeamSelectionViewModel
}

extension DefaultResolver: TeamSelectionViewModelResolver {
    public func resolveTeamSelectionViewModel() -> TeamSelectionViewModel {
        return DefaultTeamSelectionViewModel(resolver: self)
    }
}

public class DefaultTeamSelectionViewModel: TeamSelectionViewModel {
    public typealias Resolver = NullResolver

    public let tableData: Observable<[TableSectionViewModel]>
    
    private let _resolver: Resolver
    
    public init(resolver: Resolver) {
        _resolver = resolver
        
        let checkSubject = PublishSubject<String>()
        let checkedItem = checkSubject.scan("") { $1 }
        
        tableData = Observable.just([
            StaticTableSectionViewModel(cells: [
                CheckableTableCellViewModel(text: "うちのいえ", checked: checkedItem.map { $0 == "0" }, onSelect: checkSubject.mapObserver { "0" }),
                CheckableTableCellViewModel(text: "バスケ部", checked: checkedItem.map { $0 == "1" }, onSelect: checkSubject.mapObserver { "1" }),
                CheckableTableCellViewModel(text: "ほげほげ", checked: checkedItem.map { $0 == "2" }, onSelect: checkSubject.mapObserver { "2" }),
            ])
        ])
    }
}
