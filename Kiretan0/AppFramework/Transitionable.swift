//
// Transitionable.swift
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

public protocol Transitionable {
    func transitioner(_ observable: Observable<Message>) -> Disposable
}

public extension Transitionable where Self: UIViewController {
    public func transitioner(_ observable: Observable<Message>) -> Disposable {
        return observable
            .subscribe(onNext: { [unowned self] message in
                switch message {
                case let message as TransitionMessage:
                    if let viewModel = message.viewModel as? ViewControllerCreatable {
                        let viewController = viewModel.createViewController()
                        switch message.type {
                        case .present:
                            viewController.modalTransitionStyle = message.modalTransitionStyle
                            self.present(viewController, animated: message.animated, completion: nil)
                        case .push:
                            var vc = viewController
                            if let navvc = vc as? UINavigationController {
                                vc = navvc.viewControllers[0]
                            }
                            self.navigationController?.pushViewController(vc, animated: message.animated)
                        }
                    }
                
                case let message as DismissingMessage:
                    switch message.type {
                    case .dismiss:
                        self.dismiss(animated: message.animated, completion: nil)
                    case .pop:
                        _ = self.navigationController?.popViewController(animated: message.animated)
                    }
                    
                default:
                    break
                }
            })
    }
}
