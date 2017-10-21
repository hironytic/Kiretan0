//
// TeamRepositoryTests.swift
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

class TeamRepositoryTests: XCTestCase {
    var disposeBag: DisposeBag!
    var teamRepository: TeamRepository!

    override func setUp() {
        super.setUp()

        let dataStore = MockDataStore(initialCollections: [
            "/team": [
                "aaa": [
                    "name": "Team A"
                ],
                "bbb": [
                    "name": "Team B"
                ],
            ],
            "/team/aaa/member": [
                "user_x": [
                    "name": "Tom"
                ],
                "user_y": [
                    "name": "Jessy"
                ],
            ],
            "/team/bbb/member": [
                "user_y": [
                    "name": "JessyB"
                ],
                "user_z": [
                    "name": "Mark"
                ],
            ],
            "/member_team": [
                "user_x": [
                    "aaa": true,
                ],
                "user_y": [
                    "aaa": true,
                    "bbb": true,
                ],
                "user_z": [
                    "bbb": true,
                ],
            ],
        ])
        
        disposeBag = DisposeBag()
        
        class MockResolver: DefaultTeamRepository.Resolver {
            let dataStore: DataStore
            init(dataStore: DataStore) {
                self.dataStore = dataStore
            }
            func resolveDataStore() -> DataStore {
                return dataStore
            }
        }
        teamRepository = DefaultTeamRepository(resolver: MockResolver(dataStore: dataStore))
    }
    
    override func tearDown() {
        disposeBag = nil
        teamRepository = nil

        super.tearDown()
    }

    func testGetExistingTeam() {
        var teamOpt: Team?
        let exp = expectation(description: "Existing team is retrieved")
        let observer = EventuallyFulfill(exp) { (team: Team?) in
            if let team = team {
                teamOpt = team
                return true
            } else {
                return false
            }
        }
        
        teamRepository.team(for: "aaa")
            .bind(to: observer)
            .disposed(by: disposeBag)
        
        wait(for: [exp], timeout: 3.0)
        guard let team = teamOpt else { return }
        
        XCTAssertEqual(team.teamID, "aaa")
        XCTAssertEqual(team.name, "Team A")
    }
    
    func testGetNonexistingTeam() {
        let exp = expectation(description: "Non-existing team is not retrieved")
        let observer = EventuallyFulfill(exp) { (team: Team?) in
            return team == nil
        }
        
        teamRepository.team(for: "xxx")
            .bind(to: observer)
            .disposed(by: disposeBag)
        
        wait(for: [exp], timeout: 3.0)
    }
    
    func testTeamMembers() {
        var member0Opt: TeamMember?
        let exp = expectation(description: "Members are retrieved")
        let observer = EventuallyFulfill(exp) { (change: CollectionChange<TeamMember>) in
            guard change.result.count == 2 else { return false }
            guard change.result[0].documentID == "user_y" else { return false }
            guard change.result[1].documentID == "user_x" else { return false }
            
            member0Opt = change.result[0]
            return true
        }
        
        teamRepository.members(in: "aaa")
            .bind(to: observer)
            .disposed(by: disposeBag)
        
        wait(for: [exp], timeout: 3.0)
        guard let member0 = member0Opt else { return }
        
        XCTAssertEqual(member0.memberID, "user_y")
        XCTAssertEqual(member0.name, "Jessy")
    }
    
    func testMemberTeams() {
        var teamsOpt: MemberTeam?
        let exp = expectation(description: "Teams are retrieved")
        let observer = EventuallyFulfill(exp) { (teams: MemberTeam) in
            teamsOpt = teams
            return true
        }
        
        teamRepository.teamList(of: "user_y")
            .bind(to: observer)
            .disposed(by: disposeBag)
        
        wait(for: [exp], timeout: 3.0)
        guard let teams = teamsOpt else { return }
        
        XCTAssertEqual(teams.memberID, "user_y")
        XCTAssertEqual(teams.teamIDList, ["aaa", "bbb"])
    }
    
    func testCreateTeam() {
        var newTeamIDOpt: String?
        let newTeam = Team(name: "new team")
        let teamMember = TeamMember(memberID: "user_x", name: "Tom New")
        let expCreate = expectation(description: "Create team")
        teamRepository.createTeam(newTeam, by: teamMember)
            .subscribe(onSuccess: { teamID in
                newTeamIDOpt = teamID
                expCreate.fulfill()
            }, onError: { error in
                XCTFail("error \(error)")
            })
            .disposed(by: disposeBag)
        
        wait(for: [expCreate], timeout: 3.0)
        guard let newTeamID = newTeamIDOpt else { return }
        
        XCTAssertFalse(newTeamID.isEmpty)
        
        // Confirm that team exists
        let expGet = expectation(description: "Get created team")
        let teamObserver = EventuallyFulfill(expGet) { (team: Team?) in
            guard let team = team else { return false }
            guard team.name == "new team" else { return false }
            return true
        }
        
        teamRepository.team(for: newTeamID)
            .bind(to: teamObserver)
            .disposed(by: disposeBag)
        
        wait(for: [expGet], timeout: 3.0)
        
        // Confirm that team has a team member
        let expMember = expectation(description: "Get members")
        let memberObserver = EventuallyFulfill(expMember) { (change: CollectionChange<TeamMember>) in
            guard change.result.count == 1 else { return false }
            guard change.result[0].memberID == "user_x" else { return false }
            guard change.result[0].name == "Tom New" else { return false }
            return true
        }
        
        teamRepository.members(in: newTeamID)
            .bind(to: memberObserver)
            .disposed(by: disposeBag)
        
        wait(for: [expMember], timeout: 3.0)

        // Confirm that member that creates new team joins the team
        let expMemberTeam = expectation(description: "Get member's team")
        let memberTeamObserver = EventuallyFulfill(expMemberTeam) { (teams: MemberTeam) in
            guard teams.teamIDList.contains(newTeamID) else { return false }
            return true
        }
        
        teamRepository.teamList(of: "user_x")
            .bind(to: memberTeamObserver)
            .disposed(by: disposeBag)
        
        wait(for: [expMemberTeam], timeout: 3.0)
    }
}
