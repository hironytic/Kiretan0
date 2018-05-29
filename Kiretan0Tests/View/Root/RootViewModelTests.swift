//
// RootViewModelTests.swift
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

import XCTest
import RxSwift
@testable import Kiretan0

class RootViewModelTests: XCTestCase {
    var disposeBag: DisposeBag!
    var resolver: MockResolver!

    class MockResolver: DefaultRootViewModel.Resolver {
        let mockUserAccountRepository = MockUserAccountRepository()
        
        init() {
        }
        
        func resolveUserAccountRepository() -> UserAccountRepository {
            return mockUserAccountRepository
        }
    }
    
    override func setUp() {
        super.setUp()

        disposeBag = DisposeBag()
        resolver = MockResolver()
    }
    
    override func tearDown() {
        disposeBag = nil
        resolver = nil
        
        super.tearDown()
    }

    func testSceneChangedToWelcomeWhenUserNotAuthenticated() {
        resolver.mockUserAccountRepository.mock.currentUser.setup() { Observable<UserAccount?>.just(nil) }
        
        let viewModel = DefaultRootViewModel(resolver: resolver)

        let observer = EventuallyFulfill(expectation(description: "Scene should be changed to 'welcome'")) { (scene: RootScene) in
            return scene == .welcome
        }
        
        viewModel.scene
            .bind(to: observer)
            .disposed(by: disposeBag)
        
        waitForExpectations(timeout: 3.0)
    }
    
    func testSceneChangedToMainWhenUserAuthenticated() {
        let currentUser = BehaviorSubject<UserAccount?>(value: nil)
        resolver.mockUserAccountRepository.mock.currentUser.setup() { currentUser }
        
        let viewModel = DefaultRootViewModel(resolver: resolver)

        let observer = EventuallyFulfill(expectation(description: "Scene should be changed to 'welcome'")) { (scene: RootScene) in
            if case .main(_) = scene {
                return true
            } else {
                return false
            }
        }
        
        viewModel.scene
            .bind(to: observer)
            .disposed(by: disposeBag)

        currentUser.onNext(UserAccount(userID: "mock_user", isAnonymous: true))
        
        waitForExpectations(timeout: 3.0)
    }
}
