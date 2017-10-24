//
// TeamRepository.swift
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
import FirebaseAuth
import RxSwift

public protocol TeamRepository {
    func team(for teamID: String) -> Observable<Team?>
    func members(in teamID: String) -> Observable<CollectionChange<TeamMember>>
    func teamList(of memberID: String) -> Observable<MemberTeam>

    func createTeam(_ team: Team, by member: TeamMember) -> Single<String>
    func join(to teamID: String, as member: TeamMember) -> Completable
    func leave(from teamID: String, as memberID: String) -> Completable
    func updateMember(_ member: TeamMember, in teamID: String) -> Completable
    func updateTeam(_ team: Team) -> Completable
}

public protocol TeamRepositoryResolver {
    func resolveTeamRepository() -> TeamRepository
}

extension DefaultResolver: TeamRepositoryResolver {
    public func resolveTeamRepository() -> TeamRepository {
        return DefaultTeamRepository(resolver: self)
    }
}

public class DefaultTeamRepository: TeamRepository {
    public typealias Resolver = DataStoreResolver

    private let _resolver: Resolver
    private let _dataStore: DataStore
    
    public init(resolver: Resolver) {
        _resolver = resolver
        _dataStore = _resolver.resolveDataStore()
    }
    
    public func team(for teamID: String) -> Observable<Team?> {
        let teamPath = _dataStore.collection("team").document(teamID)
        return _dataStore.observeDocument(at: teamPath)
    }
    
    public func members(in teamID: String) -> Observable<CollectionChange<TeamMember>> {
        let teamMemberPath = _dataStore.collection("team").document(teamID).collection("member")
        let query = teamMemberPath.order(by: "name")
        return _dataStore.observeCollection(matches: query)
    }

    public func teamList(of memberID: String) -> Observable<MemberTeam> {
        let memberTeamPath = _dataStore.collection("member_team").document(memberID)
        return _dataStore
            .observeDocument(at: memberTeamPath)
            .map { (memberTeam: MemberTeam?) in
                if let memberTeam = memberTeam {
                    return memberTeam
                } else {
                    return MemberTeam(memberID: memberID, teamIDList: [])
                }
            }
    }

    public func createTeam(_ team: Team, by member: TeamMember) -> Single<String> {
        var teamID: String = ""
        return _dataStore.write { writer in
            let teamPath = self._dataStore.collection("team").document()
            teamID = teamPath.documentID
            writer.setDocumentData(team.raw().data, at: teamPath)
            
            let memberPath = teamPath.collection("member").document(member.memberID)
            writer.setDocumentData(member.raw().data, at: memberPath)
            
            let reversePath = self._dataStore.collection("member_team").document(member.memberID)
            writer.mergeDocumentData([teamID: true], at: reversePath)
        }
        .andThen(Single.create { observer in
            observer(.success(teamID))
            return Disposables.create()
        })
    }

    public func join(to teamID: String, as member: TeamMember) -> Completable {
        return _dataStore.write { writer in
            let teamPath = self._dataStore.collection("team").document(teamID)
            let memberPath = teamPath.collection("member").document(member.memberID)
            writer.setDocumentData(member.raw().data, at: memberPath)
            
            let reversePath = self._dataStore.collection("member_team").document(member.memberID)
            writer.mergeDocumentData([teamID: true], at: reversePath)
        }
    }

    public func leave(from teamID: String, as memberID: String) -> Completable {
        return _dataStore.write { writer in
            let teamPath = self._dataStore.collection("team").document(teamID)
            let teamMemberPath = teamPath.collection("member").document(memberID)
            writer.deleteDocument(at: teamMemberPath)

            let reversePath = self._dataStore.collection("member_team").document(memberID)
            writer.updateDocumentData([teamID: self._dataStore.deletePlaceholder], at: reversePath)
        }
    }

    public func updateMember(_ member: TeamMember, in teamID: String) -> Completable {
        return _dataStore.write { writer in
            let teamPath = self._dataStore.collection("team").document(teamID)
            let teamMemberPath = teamPath.collection("member").document(member.memberID)
            writer.updateDocumentData(member.raw().data, at: teamMemberPath)
        }
    }

    public func updateTeam(_ team: Team) -> Completable {
        return _dataStore.write { writer in
            let teamPath = self._dataStore.collection("team").document(team.teamID)
            writer.updateDocumentData(team.raw().data, at: teamPath)
        }
    }
}
