# RxActivityTracker
Observable 시퀀스를 추적하는 ActivityTracker

RxExample 프로젝트의 ActivityIndicator 참고하여 **최소 딜레이 시간을 부여할 수 있도록 개선**

> ActivityIndicator: https://github.com/ReactiveX/RxSwift/blob/main/RxExample/RxExample/Services/ActivityIndicator.swift

<img width="300" src="ActivityTrackerDemo.gif">

## Usage

```Swift
final class SomeReactor: Reactor {
    ...
    let isLoading = ActivityTracker()
    ...
    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case .incrementNumber:
            return incrementNumberTask(fromNumber: currentState.number)
                .map { .setNumber(to: $0) }
                .trackActivity(isLoading, minimumDelay: 1) // ActivityTracker로 이 시퀀스 추적
                .catch { [weak self] error in
                    self?.errorSubject.onNext(error)
                    return .empty()
                }
                .debug()
            
        case .changeColor:
            return makeColorTask()
                .map { .setColor(to: $0) }
                .trackActivity(isLoading, minimumDelay: 1) // ActivityTracker로 이 시퀀스 추적
                .catch { [weak self] error in
                    self?.errorSubject.onNext(error)
                    return .empty()
                }
                .debug()
        }
    }
    ...
}
```

```Swift
final class SomeViewController: UIViewController, View {
    ...
    func bind(reactor: SomeReactor) {
        reactor
            .isLoading.debug("isLoading ??")
            .drive(onNext: { isActive in
                if isActive {
                    LoadingIndicator.showLoading()
                } else {
                    LoadingIndicator.hideLoading()
                }
            })
            .disposed(by: disposeBag)
    }
    ...
}
```
