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
    var resolver: MockResolver!

    class MockResolver: DefaultTeamRepository.Resolver {
        let dataStore = MockDataStore()
        func resolveDataStore() -> DataStore {
            return dataStore
        }
    }

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        
        disposeBag = DisposeBag()
        resolver = MockResolver()
    }

    override func tearDown() {
        disposeBag = nil
        resolver = nil

        super.tearDown()
    }

    func setupMockWrite(writer: DocumentWriter) {
        resolver.dataStore.mock.write.setup { (block) -> Completable in
            return Completable.create { observer in
                do {
                    try block(writer)
                    observer(.completed)
                } catch let error {
                    observer(.error(error))
                }
                return Disposables.create()
            }
        }
    }
    
    func testGetExistingTeam() {
        let mockFunctionForTeam = MockFunction<(DocumentPath) -> Observable<Team?>>("mockFunctionForTeam")
        mockFunctionForTeam.setup { (documentPath) -> Observable<Team?> in
            let mockDocumentPath = documentPath as! MockDocumentPath
            XCTAssertEqual(mockDocumentPath.path, "/team/aaa")
            
            let team = Team(teamID: "aaa", name: "Team A")
            return Observable.just(team).concat(Observable.never())
        }
        resolver.dataStore.mock.observeDocument.install(mockFunctionForTeam)
        
        let teamRepository = DefaultTeamRepository(resolver: resolver)

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
        let mockFunctionForTeam = MockFunction<(DocumentPath) -> Observable<Team?>>("mockFunctionForTeam")
        mockFunctionForTeam.setup { (documentPath) -> Observable<Team?> in
            let mockDocumentPath = documentPath as! MockDocumentPath
            XCTAssertEqual(mockDocumentPath.path, "/team/xxx")
            
            return Observable.just(nil).concat(Observable.never())
        }
        resolver.dataStore.mock.observeDocument.install(mockFunctionForTeam)

        let teamRepository = DefaultTeamRepository(resolver: resolver)

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
        let mockFunctionForTeamMember = MockFunction<(DataStoreQuery) -> Observable<CollectionChange<TeamMember>>>("mockFunctionForTeamMember")
        mockFunctionForTeamMember.setup { (query) -> Observable<CollectionChange<TeamMember>> in
            let mockQuery = query as! MockDataStoreQuery
            XCTAssertEqual(mockQuery.path, "/team/aaa/member@name:asc")
            
            let change = CollectionChange<TeamMember>(
                result: [
                    TeamMember(memberID: "user_y", name: "Jessy"),
                    TeamMember(memberID: "user_x", name: "Tom"),
                ],
                deletions: [],
                insertions: [0, 1],
                modifications: []
            )
            return Observable.just(change).concat(Observable.never())
        }
        resolver.dataStore.mock.observeCollection.install(mockFunctionForTeamMember)
        
        let teamRepository = DefaultTeamRepository(resolver: resolver)

        var member0Opt: TeamMember?
        let exp = expectation(description: "Members are retrieved")
        let observer = EventuallyFulfill(exp) { (change: CollectionChange<TeamMember>) in
            guard change.result.count == 2 else { return false }
            guard change.result[0].memberID == "user_y" else { return false }
            guard change.result[1].memberID == "user_x" else { return false }

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
        let mockFunctionForMemberTeam = MockFunction<(DocumentPath) -> Observable<MemberTeam?>>("mockFunctionForMemberTeam")
        mockFunctionForMemberTeam.setup { (documentPath) -> Observable<MemberTeam?> in
            let mockDocumentPath = documentPath as! MockDocumentPath
            XCTAssertEqual(mockDocumentPath.path, "/member_team/user_y")
            
            let memberTeam = MemberTeam(memberID: "user_y", teamIDList: ["aaa", "bbb"])
            return Observable.just(memberTeam).concat(Observable.never())
        }
        resolver.dataStore.mock.observeDocument.install(mockFunctionForMemberTeam)

        let teamRepository = DefaultTeamRepository(resolver: resolver)

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
        var newTeamID = ""
        var isTeamCreated = false
        var isTeamMemberCreated = false
        var isMemberTeamCreated = false
        
        let writer = MockDocumentWriter()
        writer.mock.setDocumentData.setup { (data, documentPath) in
            let mockDocumentPath = documentPath as! MockDocumentPath
            
            if mockDocumentPath.path == "/team/\(documentPath.documentID)" {
                isTeamCreated = true
                newTeamID = documentPath.documentID
                XCTAssertEqual(data["name"] as? String, "new team")
            } else if mockDocumentPath.path == "/team/\(newTeamID)/member/user_x" {
                isTeamMemberCreated = true
                XCTAssertEqual(data["name"] as? String, "Tom New")
            }
        }
        writer.mock.mergeDocumentData.setup { (data, documentPath) in
            let mockDocumentPath = documentPath as! MockDocumentPath
            
            if mockDocumentPath.path == "/member_team/user_x" {
                isMemberTeamCreated = true
                XCTAssertEqual(data[newTeamID] as? Bool, true)
                
            }
        }
        setupMockWrite(writer: writer)
        
        let teamRepository = DefaultTeamRepository(resolver: resolver)
        
        let newTeam = Team(name: "new team")
        let teamMember = TeamMember(memberID: "user_x", name: "Tom New")
        let expCreate = expectation(description: "Create team")
        teamRepository.createTeam(newTeam, by: teamMember)
            .subscribe(onSuccess: { teamID in
                XCTAssertEqual(teamID, newTeamID)
                expCreate.fulfill()
            }, onError: { error in
                XCTFail("error \(error)")
            })
            .disposed(by: disposeBag)

        wait(for: [expCreate], timeout: 3.0)
        XCTAssertTrue(isTeamCreated)
        XCTAssertTrue(isTeamMemberCreated)
        XCTAssertTrue(isMemberTeamCreated)
    }

    func testJoinToTeam() {
        var isTeamMemberCreated = false
        var isMemberTeamCreated = false
        
        let writer = MockDocumentWriter()
        writer.mock.setDocumentData.setup { (data, documentPath) in
            let mockDocumentPath = documentPath as! MockDocumentPath
            
            XCTAssertEqual(mockDocumentPath.path, "/team/aaa/member/user_w")
            XCTAssertEqual(data["name"] as? String, "Kate")
            isTeamMemberCreated = true
        }
        writer.mock.mergeDocumentData.setup { (data, documentPath) in
            let mockDocumentPath = documentPath as! MockDocumentPath
            
            if mockDocumentPath.path == "/member_team/user_w" {
                XCTAssertEqual(data["aaa"] as? Bool, true)
                isMemberTeamCreated = true
            }
        }
        setupMockWrite(writer: writer)

        let teamRepository = DefaultTeamRepository(resolver: resolver)

        let expectJoin = expectation(description: "Join to team")
        let teamMember = TeamMember(memberID: "user_w", name: "Kate")
        teamRepository.join(to: "aaa", as: teamMember)
            .subscribe(onCompleted: {
                expectJoin.fulfill()
            }, onError: {error in
                XCTFail("error \(error)")
            })
            .disposed(by: disposeBag)

        wait(for: [expectJoin], timeout: 3.0)
        XCTAssertTrue(isTeamMemberCreated)
        XCTAssertTrue(isMemberTeamCreated)
    }

    func testLeaveFromTeam() {
        var isTeamMemberRemoved = false
        var isMemberTeamRemoved = false
        
        let writer = MockDocumentWriter()
        writer.mock.deleteDocument.setup { (documentPath) in
            let mockDocumentPath = documentPath as! MockDocumentPath
            
            XCTAssertEqual(mockDocumentPath.path, "/team/aaa/member/user_x")
            isTeamMemberRemoved = true
        }
        writer.mock.updateDocumentData.setup { (data, documentPath) in
            let mockDocumentPath = documentPath as! MockDocumentPath
            
            XCTAssertEqual(mockDocumentPath.path, "/member_team/user_x")
            XCTAssertEqual(data["aaa"] as? MockDataStorePlaceholder, .deletePlaceholder)
            isMemberTeamRemoved = true
        }
        setupMockWrite(writer: writer)

        let teamRepository = DefaultTeamRepository(resolver: resolver)

        let expectLeave = expectation(description: "Leave from team")
        teamRepository.leave(from: "aaa", as: "user_x")
            .subscribe(onCompleted: {
                expectLeave.fulfill()
            }, onError: { error in
                XCTFail("error \(error)")
            })
            .disposed(by: disposeBag)

        wait(for: [expectLeave], timeout: 3.0)
        XCTAssertTrue(isTeamMemberRemoved)
        XCTAssertTrue(isMemberTeamRemoved)
    }

    func testUpdateMember() {
        var isTeamMemberUpdated = false
        
        let writer = MockDocumentWriter()
        writer.mock.updateDocumentData.setup { (data, documentPath) in
            let mockDocumentPath = documentPath as! MockDocumentPath
            
            XCTAssertEqual(mockDocumentPath.path, "/team/aaa/member/user_x")
            XCTAssertEqual(data["name"] as? String, "TomTom")
            isTeamMemberUpdated = true
        }
        setupMockWrite(writer: writer)

        let teamRepository = DefaultTeamRepository(resolver: resolver)

        let expectUpdate = expectation(description: "Update member")
        let teamMember = TeamMember(memberID: "user_x", name: "TomTom")
        teamRepository.updateMember(teamMember, in: "aaa")
            .subscribe(onCompleted: {
                expectUpdate.fulfill()
            }, onError: { error in
                XCTFail("error \(error)")
            })
            .disposed(by: disposeBag)

        wait(for: [expectUpdate], timeout: 3.0)
        XCTAssertTrue(isTeamMemberUpdated)
    }

    func testUpdateTeam() {
        var isTeamUpdated = false
        
        let writer = MockDocumentWriter()
        writer.mock.updateDocumentData.setup { (data, documentPath) in
            let mockDocumentPath = documentPath as! MockDocumentPath
            
            XCTAssertEqual(mockDocumentPath.path, "/team/aaa")
            XCTAssertEqual(data["name"] as? String, "Team AAA")
            isTeamUpdated = true
        }
        setupMockWrite(writer: writer)

        let expectUpdate = expectation(description: "Update team")
        let team = Team(teamID: "aaa", name: "Team AAA")
        let teamRepository = DefaultTeamRepository(resolver: resolver)
        teamRepository.updateTeam(team)
            .subscribe(onCompleted: {
                expectUpdate.fulfill()
            }, onError: { error in
                XCTFail("error \(error)")
            })
            .disposed(by: disposeBag)

        wait(for: [expectUpdate], timeout: 3.0)
        XCTAssertTrue(isTeamUpdated)
    }
}
