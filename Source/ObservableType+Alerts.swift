//
//  ObservableType+Alerts.swift
//
//
//  Created by kodelit on 11.10.2018.
//

// This code is distributed under the terms and conditions of the MIT License:

// Copyright © 2019 kodelit.
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


import Foundation
import RxSwift
import RxAlertController

// MARK: - Rx alert operators

public typealias ConfirmationAlertResponse<E> = (confirmed:Bool, value:E)

extension ObservableType {
    
    // MARK: - Info alerts

    public static func stringFromTemplate(_ template:String?, data:E, tokenPrefix:String = "##", tokenSufix:String = "##", valueForToken:((String, E) -> String)? = nil) -> String?
    {
        guard var template = template else { return nil }
        guard let valueForToken = valueForToken else { return template }
        guard !tokenPrefix.isEmpty else {
            assertionFailure("tokenPrefix has to be not empty")
            return template
        }
        guard !tokenSufix.isEmpty else {
            assertionFailure("tokenSufix has to be not empty")
            return template
        }
        let pattern = "\(tokenPrefix).*?\(tokenSufix)"
        if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive)
        {
            let string = template as NSString
            let tokens = Set(regex.matches(in: template, options: [], range: NSRange(location: 0, length: template.count))
                .map({ (match:NSTextCheckingResult) -> String in
                    return string.substring(with: match.range)
                }))

            for token in tokens {
                template = template.replacingOccurrences(of: token, with: valueForToken(token, data))
            }
        }
        return template
    }

    public func notifyWithUIAlert(title:String? = nil, message:String?, buttonTitle:String = "OK", waitForUserAction:Bool = false, tokenPrefix:String = "##", tokenSufix:String = "##", valueForToken:((String, E) -> String)? = nil) -> Observable<E>
    {
        return flatMapLatest({ (data:E) -> Observable<E> in
            let message = Self.stringFromTemplate(message, data:data, tokenPrefix: tokenPrefix, tokenSufix: tokenSufix, valueForToken: valueForToken)
            let source = Observable.deferred({ () -> Observable<E> in
                if waitForUserAction {
                    let infoAlert:Observable<E> = UIAlertController.rx
                        .show(in: UIApplication.shared._topMostControllerOnWindow()!,
                              title: title, message: message,
                              buttons: [UIAlertController.AlertButton.default(buttonTitle)])
                        .asObservable()
                        .map({ _ -> E in data })
                    
                    return infoAlert
                }
                
                return Observable<E>.create({ (observer) -> Disposable in
                    let infoAlert = UIAlertController.rx
                        .show(in: UIApplication.shared._topMostControllerOnWindow()!,
                              title: title, message: message,
                              buttons: [UIAlertController.AlertButton.default(buttonTitle)])
                        .subscribe()
                    
                    observer.onNext(data)
                    
                    return Disposables.create([infoAlert])
                })
            })
            return source
        })
    }
    
    // MARK: - Confirmation alerts
    
    public func filterWithUIAlert(title:String? = nil, message:String?, confirmButton:UIAlertController.AlertButton = .default("YES"), cancelButton:UIAlertController.AlertButton = .cancel("NO"), tokenPrefix:String = "##", tokenSufix:String = "##", valueForToken:((String, E) -> String)? = nil) -> Observable<E> {
        return self.confirmWithUIAlert(title: title, message: message, confirmButton: confirmButton, cancelButton: cancelButton, tokenPrefix: tokenPrefix, tokenSufix: tokenSufix, valueForToken: valueForToken).filter({ $0.confirmed }).map({ $0.value })
    }
    
    public func confirmWithUIAlert(title:String? = nil, message:String?, confirmButton:UIAlertController.AlertButton = .default("OK"), cancelButton:UIAlertController.AlertButton = .cancel("Cancel"), tokenPrefix:String = "##", tokenSufix:String = "##", valueForToken:((String, E) -> String)? = nil) -> Observable<ConfirmationAlertResponse<E>>
    {
        return flatMapLatest({ (data:E) -> Observable<ConfirmationAlertResponse<E>> in
            let message = Self.stringFromTemplate(message, data:data, tokenPrefix: tokenPrefix, tokenSufix: tokenSufix, valueForToken: valueForToken)
            let confirmationSource:Observable<ConfirmationAlertResponse<E>> = UIAlertController.rx
                .show(in: UIApplication.shared._topMostControllerOnWindow()!,
                      title: title, message: message,
                      buttons: [confirmButton, cancelButton])
                .asObservable()
                .map({ (selectedButtonIndex:Int) -> ConfirmationAlertResponse<E> in
                    return ConfirmationAlertResponse<E>(confirmed:(selectedButtonIndex == 0), value:data)
                })
            
            return confirmationSource
        })
    }
    
    public func confirmDeleteingWithUIAlert(title:String? = "Deleting", message:String?, deleteButtonTitle:String = "Delete", cancelButtonTitle:String = "Cancel", tokenPrefix:String = "##", tokenSufix:String = "##", valueForToken:((String, E) -> String)? = nil) -> Observable<ConfirmationAlertResponse<E>> {
        return self.confirmWithUIAlert(title: title, message: message, confirmButton: .destructive(deleteButtonTitle), valueForToken: valueForToken)
    }
}

fileprivate extension UIApplication {
    fileprivate func _topMostControllerOnWindow() -> UIViewController? {
        var topController = self.keyWindow?.rootViewController
        while let presentedController = topController?.presentedViewController {
            topController = presentedController
        }
        return topController
    }
}
