//
// TeamSelectionViewModelTests.swift
// Kiretan0Tests
//
// Copyright (c) 2018 Hironori Ichimiya <hiron@hironytic.com>
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

class TeamSelectionViewModelTests: XCTestCase {
    var disposeBag: DisposeBag!
    var resolver: MockResolver!

    class MockResolver: DefaultTeamSelectionViewModel.Resolver, NullResolver {
        let userAccoountRepository = MockUserAccountRepository()
        let teamRepository = MockTeamRepository()

        func resolveUserAccountRepository() -> UserAccountRepository {
            return userAccoountRepository
        }

        func resolveTeamRepository() -> TeamRepository {
            return teamRepository
        }
    }
    

    override func setUp() {
        super.setUp()
        
        continueAfterFailure = false
        disposeBag = DisposeBag()
        resolver = MockResolver()
        
        resolver.userAccoountRepository.mock.currentUser.setup { Observable.just(UserAccount(userID: "testuser", isAnonymous: true)) }
        resolver.teamRepository.mock.teamList.setup { userID in
            XCTAssertEqual(userID, "testuser")
            return Observable.just(MemberTeam(memberID: "testuser", teamIDList: ["team2", "team1", "team3"]))
        }
        resolver.teamRepository.mock.team.setup { teamID in
            switch teamID {
            case "team1":
                return Observable.just(Team(teamID: teamID, name: "Team 1"))
            case "team2":
                return Observable.just(Team(teamID: teamID, name: "Team 2"))
            case "team3":
                return Observable.just(Team(teamID: teamID, name: "Team 3"))
            default:
                return Observable.just(nil)
            }
        }
    }
    
    override func tearDown() {
        disposeBag = nil
        resolver = nil

        super.tearDown()
    }

    func testTeamCount() {
        let teamSelectionViewModel = DefaultTeamSelectionViewModel(resolver: resolver)
        
        let exp = expectation(description: "Count of team list should be 3")
        let observer = EventuallyFulfill(exp) { (tableData: [TableSectionViewModel]) in
            guard tableData.count == 1 else { return false }
            let section = tableData[0]
            return section.cells.count == 3
        }

        teamSelectionViewModel.tableData
            .bind(to: observer)
            .disposed(by: disposeBag)
        
        wait(for: [exp], timeout: 3.0)
    }
    
    private func cellTexts(in tableData: [TableSectionViewModel]) -> [String] {
        guard tableData.count == 1 else { XCTFail("Only one section should exist"); fatalError() }
        let section = tableData[0]
        return section.cells.map { cell in
            return (cell as? CheckableTableCellViewModel)?.text ?? ""
        }
    }
    
    private func findCellByText(in tableData: [TableSectionViewModel], matches text: String) -> CheckableTableCellViewModel? {
        guard tableData.count == 1 else { XCTFail("Only one section should exist"); fatalError() }
        let section = tableData[0]
        let found = section.cells.first { cell in
            if let cellText = (cell as? CheckableTableCellViewModel)?.text {
                if cellText == text {
                    return true
                }
            }
            return false
        }
        if let found = found {
            return (found as! CheckableTableCellViewModel)
        } else {
            return nil
        }
    }
    
    func testTeamNames() {
        let teamSelectionViewModel = DefaultTeamSelectionViewModel(resolver: resolver)
        
        enum State {
            case waitForLoading
            case waitForTeamName
        }
        var state = State.waitForLoading
        let exp = expectation(description: "Show 'loading...' then show the team name")
        let observer = EventuallyFulfill(exp) { (tableData: [TableSectionViewModel]) in
            guard let firstText = self.cellTexts(in: tableData).first else { return false }
            if state == .waitForLoading && firstText == R.String.teamLoading.localized() {
                state = .waitForTeamName
            } else if state == .waitForTeamName && firstText == "Team 1" {   // because team names are sorted
                return true
            }
            return false
        }
        
        teamSelectionViewModel.tableData
            .bind(to: observer)
            .disposed(by: disposeBag)
        
        wait(for: [exp], timeout: 3.0)
    }

    func testShowNewTeamName() {
        let teamList = BehaviorSubject(value: MemberTeam(memberID: "testuser", teamIDList: ["team3", "team1"]))
        resolver.teamRepository.mock.teamList.setup { userID in
            return teamList
        }
        
        let teamSelectionViewModel = DefaultTeamSelectionViewModel(resolver: resolver)

        let exp1 = expectation(description: "There are two teams shown")
        let observer = EventuallyFulfill(exp1) { (tableData: [TableSectionViewModel]) in
            let texts = self.cellTexts(in: tableData)
            return texts == ["Team 1", "Team 3"]
        }
        
        teamSelectionViewModel.tableData
            .bind(to: observer)
            .disposed(by: disposeBag)

        wait(for: [exp1], timeout: 3.0)

        let exp2 = expectation(description: "New team is added to the list")
        observer.reset(exp2) { (tableData: [TableSectionViewModel]) in
            let texts = self.cellTexts(in: tableData)
            return texts == ["Team 1", "Team 2", "Team 3"]
        }

        teamList.onNext(MemberTeam(memberID: "testuser", teamIDList: ["team3", "team1", "team2"]))
        
        wait(for: [exp2], timeout: 3.0)
    }
    
    func testUpdateTeamName() {
        let team2 = BehaviorSubject<Team?>(value: Team(teamID: "team2", name: "Team 2"))
        resolver.teamRepository.mock.team.setup { teamID in
            switch teamID {
            case "team1":
                return Observable.just(Team(teamID: teamID, name: "Team 1"))
            case "team2":
                return team2
            case "team3":
                return Observable.just(Team(teamID: teamID, name: "Team 3"))
            default:
                return Observable.just(nil)
            }
        }

        let teamSelectionViewModel = DefaultTeamSelectionViewModel(resolver: resolver)

        let exp1 = expectation(description: "There is 'Team 2' in the list")
        let observer = EventuallyFulfill(exp1) { (tableData: [TableSectionViewModel]) in
            let texts = self.cellTexts(in: tableData)
            return texts == ["Team 1", "Team 2", "Team 3"]
        }
        
        teamSelectionViewModel.tableData
            .bind(to: observer)
            .disposed(by: disposeBag)

        wait(for: [exp1], timeout: 3.0)

        let exp2 = expectation(description: "New team is added to the list")
        observer.reset(exp2) { (tableData: [TableSectionViewModel]) in
            let texts = self.cellTexts(in: tableData)
            return texts == ["Team 1", "Team 3", "Team X"]
        }

        team2.onNext(Team(teamID: "team2", name: "Team X"))
        
        wait(for: [exp2], timeout: 3.0)
    }
    
}
