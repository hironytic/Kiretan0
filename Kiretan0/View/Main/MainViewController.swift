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

    private var _settingBarButtonItem: UIBarButtonItem!
    private var _segment: UISegmentedControl!
    private var _addBarButonItem: UIBarButtonItem!
    private var _segmentItems: [UIBarButtonItem] = []
    private var _disposeBag: DisposeBag?

    public override func viewDidLoad() {
        super.viewDidLoad()

        if #available(iOS 11.0, *) {
            navigationController?.navigationBar.prefersLargeTitles = true
        }
        navigationItem.rightBarButtonItem = editButtonItem
        tableView.rowHeight = 90
        
        _segment = UISegmentedControl(items: [
            R.String.sufficient.localized(),
            R.String.insufficient.localized()
        ])
        _segment.setContentPositionAdjustment(UIOffset.zero, forSegmentType: .any, barMetrics: .compact)
        
        _settingBarButtonItem = UIBarButtonItem(image: R.Image.setting.image(), style:.plain , target: nil, action: nil)
        _addBarButonItem = UIBarButtonItem(barButtonSystemItem: .add , target: nil, action: nil)
        
        _segmentItems = [
            _settingBarButtonItem,
            UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
            UIBarButtonItem(customView: _segment),
            UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
            _addBarButonItem,
        ]
        
        toolbarItems = _segmentItems
        
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
        
        viewModel.itemList
            .bind(to: tableView.rx.items(cellIdentifier: ITEM_CELL, cellType: MainItemCell.self)) { (row, element, cell) in
                cell.viewModel = element
            }
            .disposed(by: disposeBag)
        
        viewModel.displayMessage
            .bind(to: displayer)
            .disposed(by: disposeBag)
        
        _settingBarButtonItem.rx.tap
            .bind(to: viewModel.onSetting)
            .disposed(by: disposeBag)
        
        _segment.rx.selectedSegmentIndex
            .bind(to: viewModel.onSegmentSelectedIndexChange)
            .disposed(by: disposeBag)
        
        _addBarButonItem.rx.tap
            .bind(to: viewModel.onAdd)
            .disposed(by: disposeBag)
        
        _disposeBag = disposeBag
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
