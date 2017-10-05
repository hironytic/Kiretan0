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
import FirebaseFirestore
import RxSwift

public enum TeamRepositoryError: Error {
    case notAuthenticated
    case teamNotFound
    case notInTeam
}

public protocol TeamRepository {
    func team(for teamID: String) -> Observable<Team?>
    func members(in teamID: String) -> Observable<CollectionChange<TeamMember>>
//    func teams(of memberID: String) -> Observable<CollectionEvent<MemberTeam>>
//    
    func createTeam(_ team: Team, by member: TeamMember) -> Single<String>
//    func join(to teamID: String, as member: TeamMember) -> Completable
//    func leave(from teamID: String) -> Completable
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
    public typealias Resolver = NullResolver

    private let _resolver: Resolver
    
    public init(resolver: Resolver) {
        _resolver = resolver
    }
    
    public func team(for teamID: String) -> Observable<Team?> {
        return Observable.create { observer in
            let teamRef = Firestore.firestore().collection("team").document(teamID)
            let listener = teamRef.addSnapshotListener { (documentSnapshot, error) in
                if let error = error {
                    observer.onError(error)
                } else {
                    let dSnapshot = documentSnapshot!
                    if dSnapshot.exists {
                        do {
                            let entity = try Team(documentID: dSnapshot.documentID, data: dSnapshot.data())
                            observer.onNext(entity)
                        } catch let error {
                            observer.onError(error)
                        }
                    } else {
                        observer.onNext(nil)
                    }
                }
            }
            return Disposables.create {
                listener.remove()
            }
        }
    }
    
    public func members(in teamID: String) -> Observable<CollectionChange<TeamMember>> {
        return Observable.create { observer in
            let teamMemberRef = Firestore.firestore().collection("team").document(teamID).collection("member")
            let listener = teamMemberRef.addSnapshotListener{ (querySnapshot, error) in
                if let error = error {
                    observer.onError(error)
                } else {
                    do {
                        let qSnapshot = querySnapshot!
                        let result = try qSnapshot.documents.map { try TeamMember(documentID: $0.documentID, data: $0.data()) }
                        let deletions = qSnapshot.documentChanges.filter({ $0.type == .removed }).map({ Int($0.oldIndex) })
                        let modifications = qSnapshot.documentChanges.filter({ $0.type == .modified }).map({ Int($0.oldIndex) })
                        let insertions = qSnapshot.documentChanges.filter({ $0.type == .added }).map({ Int($0.newIndex) })
                        observer.onNext(CollectionChange(result: result, deletions: deletions, insertions: insertions, modifications: modifications))
                    } catch let error {
                        observer.onError(error)
                    }
                }
            }
            return Disposables.create {
                listener.remove()
            }
        }
    }

//    public func teams(of memberID: String) -> Observable<CollectionEvent<MemberTeam>> {
//        let memberTeamsRef = Database.database().reference().child("member_teams").child(memberID)
//        return memberTeamsRef.createChildCollectionObservable()
//    }
//
    public func createTeam(_ team: Team, by member: TeamMember) -> Single<String> {
        return Single.create { observer in
            guard let currentUser = Auth.auth().currentUser else {
                observer(.error(TeamRepositoryError.notAuthenticated))
                return Disposables.create()
            }
            
            let db = Firestore.firestore()
            let batch = db.batch()
            
            let teamRef = db.collection("team").document()
            let teamID = teamRef.documentID
            batch.setData(team.data, forDocument: teamRef)
            
            let memberID = currentUser.uid
            let memberRef = teamRef.collection("member").document(memberID)
            batch.setData(member.data, forDocument: memberRef)
            
            let reverseRef = db.collection("member_team").document(memberID)
            batch.setData([teamID: true], forDocument: reverseRef, options: SetOptions.merge())
            
            batch.commit { error in
                if let error = error {
                    observer(.error(error))
                } else {
                    observer(.success(teamID))
                }
            }
            
            return Disposables.create()
        }
    }

//    public func join(to teamID: String, as member: TeamMember) -> Completable {
//        guard let currentUser = Auth.auth().currentUser else {
//            return Completable.error(TeamRepositoryError.notAuthenticated)
//        }
//        let memberID = currentUser.uid
//
//        return team(for: teamID)
//            .take(1)
//            .flatMap { team -> Observable<Never> in
//                guard team != nil else { return Observable.error(TeamRepositoryError.teamNotFound) }
//                return Observable.create { observer in
//                    let rootRef = Database.database().reference()
//
//                    let childUpdates: [String: Any] = [
//                        "/team_members/\(teamID)/\(memberID)": member.value,
//                        "/member_teams/\(memberID)/\(teamID)": true,
//                        ]
//                    rootRef.updateChildValues(childUpdates) { (error, ref) in
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
//
//    public func leave(from teamID: String) -> Completable {
//        guard let currentUser = Auth.auth().currentUser else {
//            return Completable.error(TeamRepositoryError.notAuthenticated)
//        }
//        let memberID = currentUser.uid
//
//        return Completable.create { observer in
//            let rootRef = Database.database().reference()
//
//            let childUpdates: [String: Any] = [
//                "/team_members/\(teamID)/\(memberID)": NSNull(),
//                "/member_teams/\(memberID)/\(teamID)": NSNull(),
//                ]
//            rootRef.updateChildValues(childUpdates) { (error, ref) in
//                if let error = error {
//                    observer(.error(error))
//                } else {
//                    observer(.completed)
//                }
//            }
//            return Disposables.create()
//        }
//    }
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
