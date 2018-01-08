//
// R+String.swift
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

public extension R {
    public enum String: Swift.String {
        case cancel = "Kiretan0.cancel"
        
        case sufficient = "Kiretan0.sufficient"
        case insufficient = "Kiretan0.insufficient"
        case deselectAll = "Kiretan0.deselect_all"
        case makeInsufficient = "Kiretan0.make_insufficient"
        case makeSufficient = "Kiretan0.make_sufficient"
        case addSufficientItem = "Kiretan0.add_sufficient_item"
        case addInsufficientItem = "Kiretan0.add_insufficient_item"
        case doAddItem = "Kiretan0.do_add_item"

        case settingTitle = "Kiretan0.setting_title"
        case settingTeam = "Kiretan0.setting_team"
        case settingTeamPreferences = "Kiretan0.setting_team_preferences"
        case teamSelectionTitle = "Kiretan0.team_selection_title"
    }
    
    public enum StringFormat: Swift.String {
        case foo = "Foo"
    }
}

public extension R.String {
    public func localized() -> Swift.String {
        return NSLocalizedString(rawValue, comment: "")
    }
}

public extension R.StringFormat {
    public func localized(_ arguments: CVarArg...) -> Swift.String {
        return localized(arguments: arguments)
    }
    
    public func localized(arguments: [CVarArg]) -> Swift.String {
        let formatString = NSLocalizedString(rawValue, comment: "")
        return Swift.String(format:formatString, arguments: arguments)
    }
}
