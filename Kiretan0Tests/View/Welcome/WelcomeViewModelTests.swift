//
// WelcomeViewModelTests.swift
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

class WelcomeViewModelTests: XCTestCase {
    var viewModel: WelcomeViewModel!
    var disposeBag: DisposeBag!
    var resolver: MockResolver!
    
    class MockResolver: DefaultWelcomeViewModel.Resolver {
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
        viewModel = DefaultWelcomeViewModel(resolver: resolver)
    }
    
    override func tearDown() {
        disposeBag = nil
        resolver = nil
        viewModel = nil
        
        super.tearDown()
    }

    func testSignInAnonymousThenSucceed() {
        var signInObserver: PrimitiveSequenceType.CompletableObserver!
        let expect1 = expectation(description: "signInAnonymously should be called")
        resolver.mockUserAccountRepository.mockSignInAnonymously = { observer in
            expect1.fulfill()
            signInObserver = observer
        }
        
        let newAnonymousUserEnabledObserver = EventuallyObserver(expectation(description: "newAnonymousUser button should be disabled")) { (isEnabled: Bool) in
            return !isEnabled
        }
        viewModel.newAnonymousUserEnabled
            .bind(to: newAnonymousUserEnabledObserver)
            .disposed(by: disposeBag)

        viewModel.onNewAnonymousUser.onNext(())
        self.waitForExpectations(timeout: 3.0)

        newAnonymousUserEnabledObserver.reset(self.expectation(description: "newAnonymousUser button should be enabled again")) { (isEnabled: Bool) in
            return isEnabled
        }
        signInObserver(.completed)
        self.waitForExpectations(timeout: 3.0)
    }
    
    func testSignInAnonymousThenFailed() {
        enum TestError: Error {
            case failed
        }
        let expect = expectation(description: "signInAnonymously should be called")
        resolver.mockUserAccountRepository.mockSignInAnonymously = { observer in
            expect.fulfill()
            observer(.error(TestError.failed))
        }
        
        viewModel.onNewAnonymousUser.onNext(())
        waitForExpectations(timeout: 3.0)
    }
}
