//
// TextInputViewModel.swift
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

public protocol TextInputViewModel: ViewModel {
    var title: String? { get }
    var detailMessage: String? { get }
    var placeholder: String? { get }
    var initialText: String { get }
    var cancelButtonTitle: String { get }
    var doneButtonTitle: String { get }
    
    var onDone: AnyObserver<String> { get }
    var onCancel: AnyObserver<Void> { get }
}

public protocol TextInputViewModelResolver {
    func resolveTextInputViewModel(title: String?,
                                   detailMessage: String?,
                                   placeholder: String?,
                                   initialText: String,
                                   cancelButtonTitle: String,
                                   doneButtonTitle: String,
                                   onDone: AnyObserver<String>,
                                   onCancel: AnyObserver<Void>) -> TextInputViewModel
}

extension DefaultResolver: TextInputViewModelResolver {
    public func resolveTextInputViewModel(title: String?,
                                          detailMessage: String?,
                                          placeholder: String?,
                                          initialText: String,
                                          cancelButtonTitle: String,
                                          doneButtonTitle: String,
                                          onDone: AnyObserver<String>,
                                          onCancel: AnyObserver<Void>) -> TextInputViewModel {
        return DefaultTextInputViewModel(resolver: self,
                                         title: title,
                                         detailMessage: detailMessage,
                                         placeholder: placeholder,
                                         initialText: initialText,
                                         cancelButtonTitle: cancelButtonTitle,
                                         doneButtonTitle: doneButtonTitle,
                                         onDone: onDone,
                                         onCancel: onCancel)
    }
}

public class DefaultTextInputViewModel: TextInputViewModel {
    public typealias Resolver = NullResolver
    
    public let title: String?
    public let detailMessage: String?
    public let placeholder: String?
    public let initialText: String
    public let cancelButtonTitle: String
    public let doneButtonTitle: String
    public let onDone: AnyObserver<String>
    public let onCancel: AnyObserver<Void>

    private let _resolver: Resolver
    
    public init(resolver: Resolver,
                title: String?,
                detailMessage: String?,
                placeholder: String?,
                initialText: String,
                cancelButtonTitle: String,
                doneButtonTitle: String,
                onDone: AnyObserver<String>,
                onCancel: AnyObserver<Void>) {
        _resolver = resolver
        self.title = title
        self.detailMessage = detailMessage
        self.placeholder = placeholder
        self.initialText = initialText
        self.cancelButtonTitle = cancelButtonTitle
        self.doneButtonTitle = doneButtonTitle
        self.onDone = onDone
        self.onCancel = onCancel
    }
}
