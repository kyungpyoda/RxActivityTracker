//
//  MainVC.swift
//  RxActivityTracker
//
//  Created by 홍경표 on 2021/12/30.
//

import UIKit

import RxSwift
import RxCocoa
import ReactorKit

final class MainVC: UIViewController {
    
    var disposeBag = DisposeBag()
    
    private let incrementNumberButton: UIButton = .init(type: .system).then {
        $0.setImage(.init(systemName: "plus.circle.fill"), for: .normal)
    }
    private let numberLabel: UILabel = .init().then {
        $0.font = .preferredFont(forTextStyle: .largeTitle)
        $0.textAlignment = .center
    }
    private let changeRandomColorButton: UIButton = .init(type: .system).then {
        $0.setImage(.init(systemName: "arrow.triangle.2.circlepath.circle.fill"), for: .normal)
    }
    private let randomColorView: UILabel = .init().then {
        $0.text = "🎨"
        $0.font = .preferredFont(forTextStyle: .largeTitle)
        $0.textAlignment = .center
    }
    
    init(reactor: MainReactor) {
        super.init(nibName: nil, bundle: nil)
        self.reactor = reactor
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    deinit {
        print(type(of: self), "Deinit")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUp()
    }
    
    private func setUp() {
        view.backgroundColor = .systemBackground
        
        let topView = UIView().then {
            $0.backgroundColor = .systemGray5
            
            let label = UILabel().then { $0.text = "Increment Number" }
            $0.addSubview(label)
            $0.addSubview(numberLabel)
            $0.addSubview(incrementNumberButton)
            
            numberLabel.snp.makeConstraints {
                $0.center.equalToSuperview()
                $0.leading.trailing.equalToSuperview()
                $0.height.equalTo(50)
            }
            label.snp.makeConstraints {
                $0.centerX.equalToSuperview()
                $0.bottom.equalTo(numberLabel.snp.top).offset(-10)
            }
            incrementNumberButton.snp.makeConstraints {
                $0.centerX.equalToSuperview()
                $0.top.equalTo(numberLabel.snp.bottom).offset(10)
            }
        }
        
        let bottomView = UIView().then {
            $0.backgroundColor = .systemGray5
            
            let label = UILabel().then { $0.text = "Random Color" }
            $0.addSubview(label)
            $0.addSubview(randomColorView)
            $0.addSubview(changeRandomColorButton)
            
            randomColorView.snp.makeConstraints {
                $0.center.equalToSuperview()
                $0.leading.trailing.equalToSuperview()
                $0.height.equalTo(50)
            }
            label.snp.makeConstraints {
                $0.centerX.equalToSuperview()
                $0.bottom.equalTo(randomColorView.snp.top).offset(-10)
            }
            changeRandomColorButton.snp.makeConstraints {
                $0.centerX.equalToSuperview()
                $0.top.equalTo(randomColorView.snp.bottom).offset(10)
            }
        }
        
        let containerView = UIStackView().then {
            $0.axis = .vertical
            $0.distribution = .fillEqually
            $0.alignment = .fill
            $0.spacing = 40
            
            $0.isLayoutMarginsRelativeArrangement = true
            $0.directionalLayoutMargins = .init(top: 40, leading: 40, bottom: 40, trailing: 40)
            
            $0.addArrangedSubview(topView)
            $0.addArrangedSubview(bottomView)
        }
        view.addSubview(containerView)
        containerView.snp.makeConstraints { $0.edges.equalTo(view.safeAreaLayoutGuide) }
    }
    
}

extension MainVC: View {
    func bind(reactor: MainReactor) {
        bindAction(reactor: reactor)
        bindState(reactor: reactor)
    }
    
    private func bindAction(reactor: MainReactor) {
        incrementNumberButton.rx.tap
            .map { Reactor.Action.incrementNumber }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        changeRandomColorButton.rx.tap
            .map { Reactor.Action.changeColor }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
    }
    
    private func bindState(reactor: MainReactor) {
        reactor
            .pulse(\.$number)
            .observe(on: MainScheduler.instance)
            .map { "\($0)"}
            .bind(to: numberLabel.rx.text)
            .disposed(by: disposeBag)
        
        reactor
            .pulse(\.$color)
            .observe(on: MainScheduler.instance)
            .map { UIColor(red: CGFloat($0.0), green: CGFloat($0.1), blue: CGFloat($0.2), alpha: 1) }
            .bind(to: randomColorView.rx.backgroundColor)
            .disposed(by: disposeBag)
        
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
        
        reactor
            .errorObservable
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] error in
                let alert = UIAlertController(title: "\(error)", message: error.localizedDescription, preferredStyle: .alert)
                let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                alert.addAction(okAction)
                self?.present(alert, animated: true, completion: nil)
            })
            .disposed(by: disposeBag)
    }
}
