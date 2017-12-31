//
// MockTeamRepository.swift
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

import Foundation
import RxSwift
import RxCocoa
@testable import Kiretan0

class MockTeamRepository: TeamRepository {
    class Mock {
        var team = MockFunction<(String) -> Observable<Team?>>("MockTeamRepository.team")
        var members = MockFunction<(String) -> Observable<CollectionChange<TeamMember>>>("MockTeamRepository.members")
        var teamList = MockFunction<(String) -> Observable<MemberTeam>>("MockTeamRepository.teamList")
        
        var createTeam = MockFunction<(Team, TeamMember) -> Single<String>>("MockTeamRepository.createTeam")
        var join = MockFunction<(String, TeamMember) -> Completable>("MockTeamRepository.join")
        var leave = MockFunction<(String, String) -> Completable>("MockTeamRepository.leave")
        var updateMember = MockFunction<(TeamMember, String) -> Completable>("MockTeamRepository.updateMember")
        var updateTeam = MockFunction<(Team) -> Completable>("MockTeamRepository.updateTeam")
    }
    let mock = Mock()

    func team(for teamID: String) -> Observable<Team?> {
        return mock.team.call(teamID)
    }
    
    func members(in teamID: String) -> Observable<CollectionChange<TeamMember>> {
        return mock.members.call(teamID)
    }
    
    func teamList(of memberID: String) -> Observable<MemberTeam> {
        return mock.teamList.call(memberID)
    }
    
    func createTeam(_ team: Team, by member: TeamMember) -> Single<String> {
        return mock.createTeam.call(team, member)
    }
    
    func join(to teamID: String, as member: TeamMember) -> Completable {
        return mock.join.call(teamID, member)
    }
    
    func leave(from teamID: String, as memberID: String) -> Completable {
        return mock.leave.call(teamID, memberID)
    }
    
    func updateMember(_ member: TeamMember, in teamID: String) -> Completable {
        return mock.updateMember.call(member, teamID)
    }
    
    func updateTeam(_ team: Team) -> Completable {
        return mock.updateTeam.call(team)
    }
}
