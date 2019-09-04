//
//  APIClient.swift
//  APIClient
//
//  Created by Mark Daigneault on 2/16/17.
//  Copyright © 2017 Mark Daigneault. All rights reserved.
//

import Foundation
import Alamofire

public enum APIClientError: Error {
    case httpError(statusCode: Int, response: HTTPURLResponse, data: Data?)
    case dataTaskError(error: Error)
    case unableToMapResult
    case unknown
}

public class APIClient {

    public var decoder = JSONDecoder()
    
    // MARK: - Private Methods
    
    private func sendRequest(_ request: URLRequest, completion: defaultRequestCompletion?) {
        Logger.log(request: request)
        AF.request(request).response { response in
            guard let completion = completion, let httpResponse = response.response else {
                return
            }
            Logger.log(response: httpResponse)
            let statusCode = httpResponse.statusCode
            switch statusCode {
                case 200..<300:
                    return completion(.success(response.data))
                default:
                    let error = APIClientError.httpError(statusCode: statusCode, response: httpResponse, data: response.data)
                    return completion(.failure(error))
            }
        }
    }
    
    private func parseNetworkResponse<T: Codable>(keyPath: String?, dataResult: Result<Data?,Error>) -> Result<T,Error> {
        switch dataResult {
            case .success(let value):
                guard let data = value else {
                    return .failure(APIClientError.unableToMapResult)
                }
                Logger.log(jsonData: data)
                do {
                    let object = try T(data: data, keyPath: keyPath, decoder: decoder)
                    return .success(object)
                } catch {
                    print("Error creating and mapping node: \(error)")
                    return .failure(APIClientError.unableToMapResult)
                }
            case .failure(let error):
                return .failure(error)
        }
    }
    
    // MARK: - Public Methods
    
   func sendRequest(_ request: URLRequest, completion: voidRequestCompletion?) {
        let dataRequestCompletion: defaultRequestCompletion = { dataResult in
            guard let result = dataResult else { return }
            DispatchQueue.main.async {
                switch result {
                    case .success(_):
                        completion?(.success(nil))
                    case .failure(let error):
                        completion?(.failure(error))
                }
            }
        }
        sendRequest(request, completion: dataRequestCompletion)
    }
    
    func sendRequest<T: Codable>(_ request: URLRequest, keyPath: String? = nil, completion: genericCompletion<T>?) {
        let dataRequestCompletion: defaultRequestCompletion = { dataResult in
            guard let result = dataResult else { return }
            DispatchQueue.main.async {
                completion?(self.parseNetworkResponse(keyPath: keyPath, dataResult: result))
            }
        }
        sendRequest(request, completion: dataRequestCompletion)
    }
    
    
    
}
