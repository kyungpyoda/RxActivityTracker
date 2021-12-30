//
//  LoadingIndicator.swift
//  RxActivityTracker
//
//  Created by 홍경표 on 2021/12/30.
//

import UIKit

public class LoadingIndicator {
    private static weak var currentIndicator: UIActivityIndicatorView?
    
    public class func showLoading() {
        // keyWindow 가져옴
        guard let window = UIApplication.shared.windows.filter({ $0.isKeyWindow }).first else { return }
        
        let loadingIndicatorView: UIActivityIndicatorView
        if let existedView = window.subviews.first(where: { $0 is UIActivityIndicatorView }) as? UIActivityIndicatorView {
            loadingIndicatorView = existedView
        } else {
            loadingIndicatorView = UIActivityIndicatorView(style: .large)
        }
        
        loadingIndicatorView.frame = window.frame
        loadingIndicatorView.color = .white
        loadingIndicatorView.backgroundColor = .black.withAlphaComponent(0.5)
        
        window.addSubview(loadingIndicatorView)
        loadingIndicatorView.startAnimating()
        
        currentIndicator = loadingIndicatorView
    }
    
    public class func hideLoading() {
        DispatchQueue.main.async {
            UIView.animate(
                withDuration: 0.3,
                delay: 0,
                options: .curveEaseInOut,
                animations: {
                    currentIndicator?.alpha = 0
                },
                completion: { _ in
                    currentIndicator?.removeFromSuperview()
                }
            )
        }
    }
}
