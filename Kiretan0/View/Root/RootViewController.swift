//
// RootViewController.swift
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

public class RootViewController: UIViewController {
    private let resolver: DefaultResolver
    private let viewModel: RootViewModel
    private var currentViewController: UIViewController? = nil

    private var _disposeBag: DisposeBag?

    public required init?(coder aDecoder: NSCoder) {
        let resolver = DefaultResolver()
        self.resolver = resolver
        viewModel = DefaultRootViewModel(resolver: resolver)

        super.init(coder: aDecoder)
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        bindViewModel()
    }
    
    private func bindViewModel() {
        _disposeBag = nil
        
        let disposeBag = DisposeBag()

        viewModel.scene
            .bind(to: sceneChanger)
            .disposed(by: disposeBag)
        
        _disposeBag = disposeBag
    }
    
    private func sceneChanger(_ observable: Observable<RootScene>) -> Disposable {
        return observable
            .subscribe(onNext: { [unowned self] (scene) in
                self.changeScene(scene)
            })
    }
    
    private func changeScene(_ scene: RootScene) {
        let nextViewController: UIViewController
        switch scene {
        case .welcome:
            let welcomeViewModel = resolver.resolveWelcomeViewModel()
            guard let vcCreator = welcomeViewModel as? ViewControllerCreatable else { return }
            nextViewController = vcCreator.createViewController()
            
        case .main:
            let mainViewModel = resolver.resolveMainViewModel()
            guard let vcCreator = mainViewModel as? ViewControllerCreatable else { return }
            nextViewController = vcCreator.createViewController()
        }

        if let currentVC = currentViewController {
            currentVC.willMove(toParentViewController: nil)
            addChildViewController(nextViewController)
            nextViewController.view.frame = view.bounds
            transition(from: currentVC, to: nextViewController, duration: 0.3, options: [], animations: {
                self.view.sendSubview(toBack: nextViewController.view)
                currentVC.view.frame = CGRect(x: -currentVC.view.bounds.width, y: 0, width: currentVC.view.bounds.width, height: currentVC.view.bounds.height)
            }, completion: { _ in
                currentVC.removeFromParentViewController()
                currentVC.view.removeFromSuperview()
                nextViewController.didMove(toParentViewController: self)
            })
        } else {
            addChildViewController(nextViewController)
            view.addSubview(nextViewController.view)
            nextViewController.view.frame = self.view.bounds
            nextViewController.didMove(toParentViewController: self)
        }

        currentViewController = nextViewController
    }
}
