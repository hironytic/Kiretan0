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
    var displayRequest: Observable<DisplayRequest> { get }
    var dismissalRequest: Observable<DismissalRequest> { get }
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
    public typealias Resolver = TeamSelectionViewModelResolver

    public let displayRequest: Observable<DisplayRequest>
    public let dismissalRequest: Observable<DismissalRequest>
    public let tableData: Observable<[TableSectionViewModel]>
    
    public let onDone: AnyObserver<Void>

    private let _resolver: Resolver
    private let _displayRequestSlot = PublishSubject<DisplayRequest>()
    private let _dismissalRequestSlot = PublishSubject<DismissalRequest>()
    
    public init(resolver: Resolver) {
        _resolver = resolver

        displayRequest = _displayRequestSlot.observeOn(MainScheduler.instance)
        dismissalRequest = _dismissalRequestSlot.observeOn(MainScheduler.instance)
        onDone = _dismissalRequestSlot.mapObserver { DismissalRequest(type: .dismiss, animated: true) }
        
        let teamObserver = ActionObserver<Void>()
        tableData = Observable.just([
            StaticTableSectionViewModel(cells: [
                DisclosureTableCellViewModel(text: R.String.settingTeam.localized(), detailText: Observable.just("うちのいえ"), onSelect: teamObserver.asObserver()),
                DisclosureTableCellViewModel(text: R.String.settingTeamPreferences.localized(), onSelect: AnyObserver(eventHandler: { _ in print("せってい") })),
            ])
        ])
        
        teamObserver.handler = { [weak self] _ in self?.handleTeam() }
    }
    
    private func handleTeam() {
        let teamSelectionViewModel = _resolver.resolveTeamSelectionViewModel()
        let message = DisplayRequest(viewModel: teamSelectionViewModel, type: .push, animated: true)
        _displayRequestSlot.onNext(message)
    }
}
