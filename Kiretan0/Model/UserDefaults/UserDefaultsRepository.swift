//
// UserDefaultsRepository.swift
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

public protocol MainUserDefaultsRepository {
    var lastMainSegment: Observable<Int> { get }
    
    func setLastMainSegment(_ segment: Int)
}

public protocol MainUserDefaultsRepositoryResolver {
    func resolveMainUserDefaultsRepository() -> MainUserDefaultsRepository
}

extension DefaultResolver: MainUserDefaultsRepositoryResolver {
    public func resolveMainUserDefaultsRepository() -> MainUserDefaultsRepository {
        return DefaultUserDefaultsRepository.instance
    }
}

public class DefaultUserDefaultsRepository: MainUserDefaultsRepository {
    public static let instance = DefaultUserDefaultsRepository()
    
    public let lastMainSegment: Observable<Int>
    private let _lastMainSegmentKey = "Kiretan0_lastMainSegment"
    
    private init() {
        let ud = UserDefaults.standard
        lastMainSegment = ud.rx.observe(Int.self, _lastMainSegmentKey)
            .map { $0 ?? 0 }
            .distinctUntilChanged()
            .share(replay: 1, scope: .whileConnected)
    }
    
    public func setLastMainSegment(_ segment: Int) {
        UserDefaults.standard.set(segment, forKey: _lastMainSegmentKey)
    }
}
