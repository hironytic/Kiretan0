//
// TableUI.swift
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

import UIKit
import RxSwift
import RxCocoa

public class TableUI: NSObject {
    public typealias Element = [TableSectionViewModel]
    private var _itemModels: Element = []
}

extension TableUI: UITableViewDataSource {
    public func numberOfSections(in tableView: UITableView) -> Int {
        return _itemModels.count
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return _itemModels[section].cells.count
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellViewModel = _itemModels[indexPath.section].cells[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: cellViewModel.identifier, for: indexPath)
        if let tableCell = cell as? TableCell {
            tableCell.setCellViewModel(cellViewModel)
        }
        return cell
    }
    
    public func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return _itemModels[section].titleForHeader
    }
    
    public func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        return _itemModels[section].titleForFooter
    }
}

extension TableUI: RxTableViewDataSourceType {
    public func tableView(_ tableView: UITableView, observedEvent: Event<Element>) {
        Binder(self) { dataSource, element in
            dataSource._itemModels = element
            tableView.reloadData()
        }
        .on(observedEvent)
    }
}

extension TableUI: SectionedViewDataSourceType {
    public func model(at indexPath: IndexPath) throws -> Any {
        return _itemModels[indexPath.section].cells[indexPath.row]
    }
}

extension TableUI {
    public func bind(_ tableData: Observable<[TableSectionViewModel]>, to tableView: UITableView) -> Disposable {
        let itemsDisposable = tableData.bind(to: tableView.rx.items(dataSource: self))
        let modelSelectedDisposable = tableView.rx.modelSelected(TableCellViewModel.self).bind(to: onModelSelected)
        return Disposables.create(itemsDisposable, modelSelectedDisposable)
    }
    
    public var onModelSelected: AnyObserver<TableCellViewModel> {
        return Binder(self) { this, cellViewModel in
            cellViewModel.onSelect.onNext(())
        }.asObserver()
    }
}
