//
// MainViewController.swift
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
import RxCocoa
import RxSwift

private let ITEM_CELL = "ItemCell"

public class MainViewController: UITableViewController, Displayable {
    public var viewModel: MainViewModel?

    private var _itemListMessageLabel: UILabel!
    private var _settingBarButtonItem: UIBarButtonItem!
    private var _segment: UISegmentedControl!
    private var _addBarButtonItem: UIBarButtonItem!
    private var _segmentToolbarItems: [UIBarButtonItem] = []
    private var _checkedToolbarItems0: [UIBarButtonItem] = []
    private var _checkedToolbarItems1: [UIBarButtonItem] = []
    private var _uncheckAllBarButtonItem: UIBarButtonItem!
    private var _makeInsufficientBarButtonItem: UIBarButtonItem!
    private var _makeSufficientBarButtonItem: UIBarButtonItem!
    private var _disposeBag: DisposeBag?

    public override func viewDidLoad() {
        super.viewDidLoad()

        if #available(iOS 11.0, *) {
            navigationController?.navigationBar.prefersLargeTitles = true
        }
        navigationItem.rightBarButtonItem = editButtonItem
        tableView.rowHeight = 90
        
        let itemListMessageParent = UIView()
        tableView.backgroundView = itemListMessageParent
        _itemListMessageLabel = UILabel()
        _itemListMessageLabel.translatesAutoresizingMaskIntoConstraints = false
        itemListMessageParent.addSubview(_itemListMessageLabel)
        let horizontalConstraint = NSLayoutConstraint(item: _itemListMessageLabel, attribute: .centerX, relatedBy: .equal, toItem: itemListMessageParent, attribute: .centerX, multiplier: 1.0, constant: 0.0)
        let verticalConstraint = NSLayoutConstraint(item: _itemListMessageLabel, attribute: .centerY, relatedBy: .equal, toItem: itemListMessageParent, attribute: .centerY, multiplier: 1.0, constant: 0.0)
        itemListMessageParent.addConstraints([horizontalConstraint, verticalConstraint])
        
        _segment = UISegmentedControl(items: [
            R.String.sufficient.localized(),
            R.String.insufficient.localized()
        ])
        _segment.setContentPositionAdjustment(UIOffset.zero, forSegmentType: .any, barMetrics: .compact)
        
        _settingBarButtonItem = UIBarButtonItem(image: R.Image.setting.image(), style:.plain , target: nil, action: nil)
        _addBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add , target: nil, action: nil)
        
        _segmentToolbarItems = [
            _settingBarButtonItem,
            UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
            UIBarButtonItem(customView: _segment),
            UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
            _addBarButtonItem,
        ]
        
        _uncheckAllBarButtonItem = UIBarButtonItem(title: R.String.deselectAll.localized(), style: .plain, target: nil, action: nil)
        _makeInsufficientBarButtonItem = UIBarButtonItem(title: R.String.makeInsufficient.localized(), style: .plain, target: nil, action: nil)
        _makeSufficientBarButtonItem = UIBarButtonItem(title: R.String.makeSufficient.localized(), style: .plain, target: nil, action: nil)
        _checkedToolbarItems0 = [
            _uncheckAllBarButtonItem,
            UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
            _makeInsufficientBarButtonItem
        ]
        _checkedToolbarItems1 = [
            _uncheckAllBarButtonItem,
            UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
            _makeSufficientBarButtonItem
        ]
        
        toolbarItems = _segmentToolbarItems
        
        bindViewModel()
    }
    
    public func position(for bar: UIBarPositioning) -> UIBarPosition {
        return .topAttached
    }
    
    private func bindViewModel() {
        _disposeBag = nil

        guard let viewModel = viewModel else { return }
        
        let disposeBag = DisposeBag()

        viewModel.title
            .bind(to: rx.title)
            .disposed(by: disposeBag)
        
        viewModel.segmentSelectedIndex
            .bind(to: _segment.rx.selectedSegmentIndex)
            .disposed(by: disposeBag)

        let dataSource = MainViewDataSource()
        viewModel.itemList
            .bind(to: tableView.rx.items(dataSource: dataSource))
            .disposed(by: disposeBag)
        
        viewModel.itemListMessageText
            .bind(to: _itemListMessageLabel.rx.text)
            .disposed(by: disposeBag)
        
        viewModel.itemListMessageHidden
            .bind(to: _itemListMessageLabel.rx.isHidden)
            .disposed(by: disposeBag)
        
        let segmentToolbarItems = _segmentToolbarItems
        let checkedToolbarItems0 = _checkedToolbarItems0
        let checkedToolbarItems1 = _checkedToolbarItems1
        viewModel.mainViewToolbar
            .map { toolbar in
                switch toolbar {
                case .segment:
                    return segmentToolbarItems
                case .checked0:
                    return checkedToolbarItems0
                case .checked1:
                    return checkedToolbarItems1
                }
            }
            .bind(onNext: { items in
                self.toolbarItems = items
            })
            .disposed(by: disposeBag)
        
        viewModel.displayRequest
            .bind(to: displayer)
            .disposed(by: disposeBag)
        
        _settingBarButtonItem.rx.tap
            .bind(to: viewModel.onSetting)
            .disposed(by: disposeBag)
        
        _segment.rx.selectedSegmentIndex
            .bind(to: viewModel.onSegmentSelectedIndexChange)
            .disposed(by: disposeBag)
        
        _addBarButtonItem.rx.tap
            .bind(to: viewModel.onAdd)
            .disposed(by: disposeBag)
        
        _uncheckAllBarButtonItem.rx.tap
            .bind(to: viewModel.onUncheckAllItems)
            .disposed(by: disposeBag)

        let table = tableView
        tableView.rx.itemSelected
            .do(onNext: { indexPath in
                table?.deselectRow(at: indexPath, animated: true)
            })
            .bind(to: viewModel.onItemSelected)
            .disposed(by: disposeBag)
        
        _disposeBag = disposeBag
    }
}

private class MainViewDataSource: NSObject {
    typealias Element = MainViewItemList
    private var _itemModels = [MainItemViewModel]()
}

extension MainViewDataSource: UITableViewDataSource {
    public func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return _itemModels.count
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ITEM_CELL, for: indexPath) as! MainItemCell
        let viewModel = _itemModels[indexPath.row]
        cell.viewModel = viewModel
        return cell
    }
}

extension MainViewDataSource: RxTableViewDataSourceType {
    public func tableView(_ tableView: UITableView, observedEvent: Event<MainViewItemList>) {
        Binder(self) { dataSource, element in
            dataSource._itemModels = element.viewModels
            switch element.hint {
            case .whole:
                tableView.reloadData()
            case .partial(let diff):
                tableView.beginUpdates()
                defer { tableView.endUpdates() }
                
                if !diff.deletedRows.isEmpty {
                    tableView.deleteRows(at: diff.deletedRows, with: .fade)
                }
                if !diff.insertedRows.isEmpty {
                    tableView.insertRows(at: diff.insertedRows, with: .fade)
                }
                for (old, new) in diff.movedRows {
                    tableView.moveRow(at: old, to: new)
                }
            case .none:
                break
            }
        }
        .on(observedEvent)
    }
}

extension DefaultMainViewModel: ViewControllerCreatable {
    public func createViewController() -> UIViewController {
        let storyboard = UIStoryboard(name: "Main", bundle: Bundle.main)
        let navController = storyboard.instantiateInitialViewController() as! UINavigationController
        let viewController = navController.viewControllers[0] as! MainViewController
        viewController.viewModel = self
        return navController
    }
}
