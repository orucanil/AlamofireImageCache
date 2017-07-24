//
//  ImageViewCacheExtension.swift
//  Annul Mobile
//
//  Created by Anil ORUC on 14/09/16.
//  Copyright © 2016 Annul Mobile. All rights reserved.
//

import Foundation
import AlamofireImage
import Alamofire

private var urlStringAssociationKey: UInt8 = 0
private var isImageLoadingAssociationKey: UInt8 = 1

public typealias LoadImageClosure = (UIImage?, String) -> Void

extension UIImageView {

    private(set) var isImageLoading: Bool {
        get {
            if let value = objc_getAssociatedObject(self, &isImageLoadingAssociationKey) as? NSNumber {
                return value.boolValue
            }
            return false
        }
        set(newValue) {
            objc_setAssociatedObject(self, &isImageLoadingAssociationKey,
                                     NSNumber(value: newValue), objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN)
        }
    }

    private var urlString: String? {
        get {
            return objc_getAssociatedObject(self, &urlStringAssociationKey) as? String
        }
        set(newValue) {
            objc_setAssociatedObject(self, &urlStringAssociationKey, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN)
        }
    }

    func setImage(urlString: String?, closure: LoadImageClosure? = nil) {
        af_cancelImageRequest()
        guard let urlString = urlString else {
            return
        }
        if urlString.characters.count == 0 {
            return
        }
        
        self.urlString = urlString
        
        if let image = ANWCacheManager.instance.image(key: urlString) {
            
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + DispatchTimeInterval.milliseconds(1)) {
                self.image = image
                if let closure = closure {
                    closure(image, urlString)
                }
            }
            return
        }
        guard let url = URL(string: urlString) else {
            return
        }

        isImageLoading = true
        DataRequest.addAcceptableImageContentTypes(["application/octet-stream", "image/jpg", "binary/octet-stream"])
        af_setImage(withURL: url, completion: { (response) in
            if !response.result.isFailure {
                ANWCacheManager.instance.setImage(image: response.result.value, key: self.urlString!)
                if let closure = closure {
                    closure(response.result.value, urlString)
                }
            } else {
                if let closure = closure {
                    closure(nil, urlString)
                }
            }
            self.isImageLoading = false
        })
    }

}
