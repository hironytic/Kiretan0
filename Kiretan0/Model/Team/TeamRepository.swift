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

public enum TeamRepositoryError: Error {
    case teamNotFound
    case notInTeam
}

public protocol TeamRepository {
    func team(for teamID: String) -> Observable<Team?>
    func members(in teamID: String) -> Observable<CollectionChange<TeamMember>>
    func teamList(of memberID: String) -> Observable<MemberTeam>

    func createTeam(_ team: Team, by member: TeamMember) -> Single<String>
    func join(to teamID: String, as member: TeamMember) -> Completable
    func leave(from teamID: String, as memberID: String) -> Completable
//    func updateMember(_ member: TeamMember, in teamID: String) -> Completable
//    func updateTeam(_ team: Team) -> Completable
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
    
    public init(resolver: Resolver) {
        _resolver = resolver
    }
    
    public func team(for teamID: String) -> Observable<Team?> {
        let dataStore = _resolver.resolveDataStore()
        return team(for: teamID, dataStore: dataStore)
    }
    
    private func team(for teamID: String, dataStore: DataStore) -> Observable<Team?> {
        let teamPath = dataStore.collection("team").document(teamID)
        return dataStore.observeDocument(at: teamPath)
    }
    
    public func members(in teamID: String) -> Observable<CollectionChange<TeamMember>> {
        let dataStore = _resolver.resolveDataStore()
        return members(in: teamID, dataStore: dataStore)
    }
    
    private func members(in teamID: String, dataStore: DataStore) -> Observable<CollectionChange<TeamMember>> {
        let teamMemberPath = dataStore.collection("team").document(teamID).collection("member")
        return dataStore.observeCollection(matches: teamMemberPath)
    }

    public func teamList(of memberID: String) -> Observable<MemberTeam> {
        let dataStore = _resolver.resolveDataStore()
        return teamList(of: memberID, dataStore: dataStore)
    }
    
    private func teamList(of memberID: String, dataStore: DataStore) -> Observable<MemberTeam> {
        let memberTeamPath = dataStore.collection("member_team").document(memberID)
        return dataStore
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
        let dataStore = _resolver.resolveDataStore()
        return dataStore.write { writer in
            let teamPath = dataStore.collection("team").document()
            teamID = teamPath.documentID
            writer.setDocumentData(team.data, at: teamPath)
            
            let memberPath = teamPath.collection("member").document(member.memberID)
            writer.setDocumentData(member.data, at: memberPath)
            
            let reversePath = dataStore.collection("member_team").document(member.memberID)
            writer.mergeDocumentData([teamID: true], at: reversePath)
        }.andThen(Single.just(teamID))
    }

    public func join(to teamID: String, as member: TeamMember) -> Completable {
        let dataStore = self._resolver.resolveDataStore()
        return team(for: teamID, dataStore: dataStore)
            .take(1)
            .flatMap { team -> Observable<Never> in
                guard team != nil else { return Observable.error(TeamRepositoryError.teamNotFound) }
                return dataStore.write { writer in
                    let teamPath = dataStore.collection("team").document(teamID)
                    let memberPath = teamPath.collection("member").document(member.memberID)
                    writer.setDocumentData(member.data, at: memberPath)

                    let reversePath = dataStore.collection("member_team").document(member.memberID)
                    writer.mergeDocumentData([teamID: true], at: reversePath)
                }.asObservable()
            }
            .asCompletable()
    }

    public func leave(from teamID: String, as memberID: String) -> Completable {
        let dataStore = self._resolver.resolveDataStore()

        return dataStore.write { writer in
            let teamPath = dataStore.collection("team").document()
            let teamMemberPath = teamPath.collection("member").document(memberID)
            writer.deleteDocument(at: teamMemberPath)

            let reversePath = dataStore.collection("member_team").document(memberID)
            writer.updateDocumentData([teamID: dataStore.deletePlaceholder], at: reversePath)
        }
    }

//
//    public func updateMember(_ member: TeamMember, in teamID: String) -> Completable {
//        guard let currentUser = Auth.auth().currentUser else {
//            return Completable.error(TeamRepositoryError.notAuthenticated)
//        }
//        let memberID = currentUser.uid
//
//        return Completable.create { observer in
//            let memberRef = Database.database().reference().child("team_members").child(teamID).child(memberID)
//            memberRef.observeSingleEvent(of: .value, with: { snapshot in
//                if !snapshot.exists() {
//                    observer(.error(TeamRepositoryError.notInTeam))
//                } else {
//                    memberRef.setValue(member.value) { (error, _) in
//                        if let error = error {
//                            observer(.error(error))
//                        } else {
//                            observer(.completed)
//                        }
//                    }
//                }
//            }, withCancel: { error in
//                observer(.error(error))
//            })
//            return Disposables.create()
//        }
//    }
//
//    public func updateTeam(_ newTeam: Team) -> Completable {
//        guard Auth.auth().currentUser != nil else {
//            return Completable.error(TeamRepositoryError.notAuthenticated)
//        }
//
//        return team(for: newTeam.teamID)
//            .take(1)
//            .flatMap { team -> Observable<Never> in
//                guard team != nil else { return Observable.error(TeamRepositoryError.teamNotFound) }
//                return Observable.create { observer in
//                    let teamRef = Database.database().reference().child("teams").child(newTeam.teamID)
//                    teamRef.setValue(newTeam.value) { (error, _) in
//                        if let error = error {
//                            observer.onError(error)
//                        } else {
//                            observer.onCompleted()
//                        }
//                    }
//                    return Disposables.create()
//                }
//            }
//            .asCompletable()
//    }
}
