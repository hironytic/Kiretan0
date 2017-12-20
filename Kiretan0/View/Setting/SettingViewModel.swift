//
// SettingViewModel.swift
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

public protocol SettingViewModel: ViewModel {
    var dismissalMessage: Observable<DismissalMessage> { get }
    var tableData: Observable<[TableSectionViewModel]> { get }
    
    var onDone: AnyObserver<Void> { get }
}

public protocol SettingViewModelResolver {
    func resolveSettingViewModel() -> SettingViewModel
}

extension DefaultResolver: SettingViewModelResolver {
    public func resolveSettingViewModel() -> SettingViewModel {
        return DefaultSettingViewModel(resolver: self)
    }
}

public class DefaultSettingViewModel: SettingViewModel {
    public typealias Resolver = NullResolver

    public let dismissalMessage: Observable<DismissalMessage>
    public let tableData: Observable<[TableSectionViewModel]>
    
    public let onDone: AnyObserver<Void>

    private let _resolver: Resolver
    private let _dismissalMessageSlot = PublishSubject<DismissalMessage>()
    
    public init(resolver: Resolver) {
        _resolver = resolver

        dismissalMessage = _dismissalMessageSlot.observeOn(MainScheduler.instance)
        onDone = _dismissalMessageSlot.mapObserver { DismissalMessage(type: .dismiss, animated: true) }
        
        tableData = Observable.just([
            StaticTableSectionViewModel(cells: [
                DisclosureTableCellViewModel(text: R.String.settingTeam.localized(), detailText: Observable.just("うちのいえ")) { print("ちーむせってい") },
                DisclosureTableCellViewModel(text: R.String.settingTeamPreferences.localized()) { print("せってい") },
            ])
        ])
    }
}
