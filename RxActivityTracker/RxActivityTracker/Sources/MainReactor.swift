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

final class MainReactor: Reactor {
    
    enum Action {
        case incrementNumber
        case changeColor
    }
    
    enum Mutation {
        case setNumber(to: Int)
        case setColor(to: RGBSet)
    }
    
    typealias RGBSet = (Float, Float, Float)
    
    struct State {
        @Pulse var number: Int
        @Pulse var color: RGBSet
    }
    
    let initialState: State
    
    let isLoading = ActivityTracker()
    
    private let errorSubject: PublishSubject<Error> = .init()
    var errorObservable: Observable<Error> { errorSubject.asObservable() }
    
    init() {
        self.initialState = State(
            number: 0,
            color: (0.5, 0.5, 0.5)
        )
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
                .debug()
            
        case .changeColor:
            return makeColorTask()
                .map { .setColor(to: $0) }
                .trackActivity(isLoading, minimumDelay: 1)
                .catch { [weak self] error in
                    self?.errorSubject.onNext(error)
                    return .empty()
                }
                .debug()
        }
    }
    
    func reduce(state: State, mutation: Mutation) -> State {
        var newState = state
        
        switch mutation {
        case .setNumber(let newNumber):
            newState.number = newNumber
            
        case .setColor(let newColor):
            newState.color = newColor
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
