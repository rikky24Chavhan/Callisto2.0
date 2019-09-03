//
//  MockImageDownloader.swift
//  MealTrackingPilot
//
//  Created by Mark Daigneault on 5/24/17.
//  Copyright © 2017 Intrepid. All rights reserved.
//

import Alamofire
import AlamofireImage

class MockImageDownloader: ImageDownloader {
    override func download(
        _ urlRequest: URLRequestConvertible,
        receiptID: String,
        filter: ImageFilter?,
        progress: ImageDownloader.ProgressHandler?,
        progressQueue: DispatchQueue,
        completion: ImageDownloader.CompletionHandler?) -> RequestReceipt? {

        completion?(DataResponse(request: urlRequest.urlRequest, response: nil, data: nil, result: .success(#imageLiteral(resourceName: "buttonBackarrow")))) // Random test image
        return nil
    }
}
