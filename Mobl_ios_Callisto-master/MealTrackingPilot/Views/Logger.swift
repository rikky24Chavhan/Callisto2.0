//
//  NetworkLogger.swift
//  G10_Biosensor
//
//  Created by Rikky on 12/01/19.
//  Copyright © 2019 Rikky. All rights reserved.
//

import Foundation

enum ParseResponseStatus: String, Error {
    case noData =  "Response returned with no data to decode."
    case unableToDecode = "We could not decode the response."
}

struct Logger {
    
     // MARK: - Public Methods
    
    /**
     The method provides the loging of cloud request
     - parameter request: The URLRequest sends to cloud server
     */
    static func log(request: URLRequest) {
        
        print("\n - - - - - - - - - - OUTGOING - - - - - - - - - - \n")
        defer { print("\n - - - - - - - - - -  END - - - - - - - - - - \n") }
        
        let urlAsString = request.url?.absoluteString ?? ""
        let urlComponents = NSURLComponents(string: urlAsString)
        
        let method = request.httpMethod != nil ? "\(request.httpMethod ?? "")" : ""
        let path = "\(urlComponents?.path ?? "")"
        let query = "\(urlComponents?.query ?? "")"
        let host = "\(urlComponents?.host ?? "")"
        
        var logOutput = """
                        \(urlAsString) \n\n
                        \(method) \(path)?\(query) HTTP/1.1 \n
                        HOST: \(host)\n
                        """
        for (key,value) in request.allHTTPHeaderFields ?? [:] {
            logOutput += "\(key): \(value) \n"
        }
        if let body = request.httpBody {
            logOutput += "\n \(NSString(data: body, encoding: String.Encoding.utf8.rawValue) ?? "")"
        }
        
        print(logOutput)
    }
    
    /**
     The method provides the loging of cloud response
       - parameter response: The URLResponse coming from cloud server
     */
    static func log(response: URLResponse?) {
        
        print("\n - - - - - - - - - - URL Response - - - - - - - - - - \n")
        defer { print("\n - - - - - - - - - -  END - - - - - - - - - - \n") }
        
        guard let response = response else {
            print(ParseResponseStatus.noData.rawValue)
            return
        }
        print(response.debugDescription)
    }
    
    /**
     The method provides the loging of cloud response data
     - parameter jsonData: The json data coming from cloud server
     */
    static func log(jsonData: Data) {
        
        print("\n - - - - - - - - - - JSON Data - - - - - - - - - - \n")
        defer { print("\n - - - - - - - - - -  END - - - - - - - - - - \n") }
        
        do {
            let jsonData = try JSONSerialization.jsonObject(with: jsonData, options: .mutableContainers)
            print(jsonData)
        }
        catch {
            print(ParseResponseStatus.unableToDecode.rawValue)
        }
    }
    
    /**
     The method provides the logging of message for generic type
     - parameter message: message to be passed
     */
    static func log<T>(_ message:T) {
        print(message)
    }
}
