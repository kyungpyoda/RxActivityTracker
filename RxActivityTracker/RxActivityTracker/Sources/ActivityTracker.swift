//
//  ActivityTracker.swift
//  RxActivityTracker
//
//  Created by 홍경표 on 2021/12/30.
//
//  Reference: https://github.com/ReactiveX/RxSwift/blob/main/RxExample/RxExample/Services/ActivityIndicator.swift

import Foundation

import RxSwift
import RxCocoa

private struct ActivityToken<E>: ObservableConvertibleType, Disposable {
    private let _source: Observable<E>
    private let _dispose: Cancelable
    
    init(source: Observable<E>, disposeAction: @escaping () -> Void) {
        _source = source
        _dispose = Disposables.create(with: disposeAction)
    }
    
    func dispose() {
        _dispose.dispose()
    }
    
    func asObservable() -> Observable<E> {
        _source
    }
}

/**
 시퀀스를 모니터링 함
 시퀀스가 하나라도 진행중이면 true
 모든 시퀀스가 complete 되면 false
 Enables monitoring of sequence computation.
 If there is at least one sequence computation in progress, `true` will be sent.
 When all activities complete `false` will be sent.
 */
public class ActivityTracker: SharedSequenceConvertibleType {
    public typealias Element = Bool
    public typealias SharingStrategy = DriverSharingStrategy
    
    private let _lock = NSRecursiveLock()
    private let _relay = BehaviorRelay(value: 0)
    private let _loading: SharedSequence<SharingStrategy, Bool>
    
    public init() {
        _loading = _relay.asDriver()
            .map { $0 > 0 }
            .distinctUntilChanged()
    }
    deinit {
        print(type(of: self), "Deinit")
    }
    
    fileprivate func trackActivityOfObservable<Source: ObservableConvertibleType>(
        _ source: Source
    ) -> Observable<Source.Element> {
        return Observable.using({ () -> ActivityToken<Source.Element> in
            self.increment()
            return ActivityToken(source: source.asObservable(), disposeAction: self.decrement)
        }) { t in
            return t.asObservable()
        }
    }
    
    private func increment() {
        _lock.lock()
        _relay.accept(_relay.value + 1)
        _lock.unlock()
    }
    
    private func decrement() {
        _lock.lock()
        _relay.accept(_relay.value - 1)
        _lock.unlock()
    }
    
    public func asSharedSequence() -> SharedSequence<SharingStrategy, Element> {
        _loading
    }
}

extension ObservableConvertibleType {
    public func trackActivity(_ activityTracker: ActivityTracker) -> Observable<Element> {
        activityTracker.trackActivityOfObservable(self)
    }
    
    public func trackActivity(
        _ activityTracker: ActivityTracker,
        minimumDelay minDelayTime: TimeInterval
    ) -> Observable<Element> {
        let minTimeObservable = Observable<Void>.create { emitter in
            DispatchQueue.main.asyncAfter(deadline: .now() + minDelayTime) {
                emitter.onNext(())
                emitter.onCompleted()
            }
            return Disposables.create()
        }
        
        return activityTracker.trackActivityOfObservable(
            Observable.zip(
                minTimeObservable,
                self.asObservable().materialize(),
                resultSelector: { $1 }
            ).dematerialize()
        )
    }
}
