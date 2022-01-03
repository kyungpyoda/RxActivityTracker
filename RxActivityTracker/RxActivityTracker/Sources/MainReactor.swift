//
//  MainReactor.swift
//  RxActivityTracker
//
//  Created by 홍경표 on 2021/12/30.
//

import Foundation

import ReactorKit
import RxSwift

enum TempError: Error {
    case ErrorA
}
extension TempError: LocalizedError {
    var errorDescription: String? {
        return "오류 띠용"
    }
}

final class SomeService {
    private let msgSubject: BehaviorSubject<String?> = .init(value: nil)
    
    func getMessageTask() -> Observable<String> {
        makeMessage()
        return msgSubject.asObservable()
            .observe(on: MainScheduler.asyncInstance)
            .compactMap { $0 }
            .take(1) // take(1) 꼭 붙여야함!!! 안붙이면 onCompleted() 방출안됨!
            .do(onNext: { [weak self] _ in
                self?.clearMessageStream()
            })
    }
    
    private func makeMessage() {
        DispatchQueue.global().asyncAfter(deadline: .now() + Double.random(in: 0...1)) { [weak self] in
            self?.msgSubject.onNext("Hello!\n(Random Code: \(Int.random(in: 0...9)))")
        }
    }
    
    private func clearMessageStream() {
        msgSubject.onNext(nil)
    }
}

final class MainReactor: Reactor {
    
    enum Action {
        case incrementNumber
        case changeColor
        case getMessage
    }
    
    enum Mutation {
        case setNumber(to: Int)
        case setColor(to: RGBSet)
        case setMessage(to: String)
    }
    
    typealias RGBSet = (Float, Float, Float)
    
    struct State {
        @Pulse var number: Int
        @Pulse var color: RGBSet
        @Pulse var message: String?
    }
    
    let initialState: State
    
    let isLoading = ActivityTracker()
    
    private let errorSubject: PublishSubject<Error> = .init()
    var errorObservable: Observable<Error> { errorSubject.asObservable() }
    
    private let someService: SomeService
    
    init(someService: SomeService) {
        self.initialState = State(
            number: 0,
            color: (0.5, 0.5, 0.5)
        )
        self.someService = someService
    }
    deinit {
        print(type(of: self), "Deinit")
    }
    
    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case .incrementNumber:
            return incrementNumberTask(fromNumber: currentState.number)
                .map { .setNumber(to: $0) }
                .trackActivity(isLoading, minimumDelay: 1)
                .catch { [weak self] error in
                    self?.errorSubject.onNext(error)
                    return .empty()
                }
            
        case .changeColor:
            return makeColorTask()
                .map { .setColor(to: $0) }
                .trackActivity(isLoading)
                .catch { [weak self] error in
                    self?.errorSubject.onNext(error)
                    return .empty()
                }
            
        case .getMessage:
            return someService.getMessageTask()
                .map { .setMessage(to: $0) }
                .trackActivity(isLoading)
        }
    }
    
    func reduce(state: State, mutation: Mutation) -> State {
        var newState = state
        
        switch mutation {
        case .setNumber(let newNumber):
            newState.number = newNumber
            
        case .setColor(let newColor):
            newState.color = newColor
            
        case .setMessage(let newMessage):
            newState.message = newMessage
        }
        
        return newState
    }
    
}

extension MainReactor {
    private func incrementNumberTask(fromNumber number: Int) -> Observable<Int> {
        return Observable.create { emitter in
            let isError = Int.random(in: 1...3) == 1
            
            if isError {
                emitter.onError(TempError.ErrorA)
            } else {
                DispatchQueue.main.asyncAfter(deadline: .now() + Double.random(in: 0...1)) {
                    emitter.onNext(number + 1)
                    emitter.onCompleted()
                }
            }
            
            return Disposables.create()
        }
    }
    
    private func makeColorTask() -> Observable<RGBSet> {
        return Observable.create { emitter in
            let isError = Int.random(in: 1...3) == 1
            
            if isError {
                emitter.onError(TempError.ErrorA)
            } else {
                DispatchQueue.main.asyncAfter(deadline: .now() + Double.random(in: 1...3)) {
                    let randomColor: RGBSet = (Float.random(in: 0...1), Float.random(in: 0...1), Float.random(in: 0...1))
                    emitter.onNext(randomColor)
                    emitter.onCompleted()
                }
            }
            
            return Disposables.create()
        }
    }
}
