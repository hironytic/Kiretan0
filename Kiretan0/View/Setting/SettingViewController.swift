//
// SettingViewController.swift
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

public class SettingViewController: UITableViewController, Dismissable {
    public var viewModel: SettingViewModel?

    private var _disposeBag: DisposeBag?
    private weak var _doneButton: UIBarButtonItem!

    public init() {
        super.init(style: .grouped)
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()

        title = R.String.settingTitle.localized()
        
        let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: nil, action: nil)
        navigationItem.rightBarButtonItem = doneButton
        _doneButton = doneButton
        
        tableView.register(DisclosureTableCell.self, forCellReuseIdentifier: DisclosureTableCellViewModel.typeIdentifier)
        bindViewModel()
    }

    private func bindViewModel() {
        _disposeBag = nil
        
        guard let viewModel = viewModel else { return }
        
        let disposeBag = DisposeBag()
        
        viewModel.tableData
            .bind(to: tableView.rx.items(dataSource: TableDataSource()))
            .disposed(by: disposeBag)
        
        viewModel.dismissalMessage
            .bind(to: dismisser)
            .disposed(by: disposeBag)
        
        _doneButton.rx.tap
            .bind(to: viewModel.onDone)
            .disposed(by: disposeBag)
        
        tableView.rx.modelSelected(TableCellViewModel.self)
            .subscribe(onNext: { cellViewModel in
                cellViewModel.selectAction()
            })
            .disposed(by: disposeBag)
        
        _disposeBag = disposeBag
    }

}

extension DefaultSettingViewModel: ViewControllerCreatable {
    public func createViewController() -> UIViewController {
        let viewController = SettingViewController()
        viewController.viewModel = self
        return UINavigationController(rootViewController: viewController)
    }
}
