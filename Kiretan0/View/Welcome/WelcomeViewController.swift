//
// WelcomeViewController.swift
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

public class WelcomeViewController: UIViewController {
    public var viewModel: WelcomeViewModel?

    @IBOutlet private weak var newAnonymousUserButton: UIButton!
    
    private var _disposeBag: DisposeBag?

    public override func viewDidLoad() {
        super.viewDidLoad()
        bindViewModel()
    }
    
    private func bindViewModel() {
        _disposeBag = nil
        guard let viewModel = viewModel else { return }
        
        let disposeBag = DisposeBag()
        
        viewModel.newAnonymousUserEnabled
            .bind(to: newAnonymousUserButton.rx.isEnabled)
            .disposed(by: disposeBag)
        
        newAnonymousUserButton.rx.tap
            .bind(to: viewModel.onNewAnonymousUser)
            .disposed(by: disposeBag)
        
        _disposeBag = disposeBag
    }
}

extension DefaultWelcomeViewModel: ViewControllerCreatable {
    public func createViewController() -> UIViewController {
        let storyboard = UIStoryboard(name: "Welcome", bundle: Bundle.main)
        let viewController = storyboard.instantiateInitialViewController() as! WelcomeViewController
        viewController.viewModel = self
        return viewController
    }
}
