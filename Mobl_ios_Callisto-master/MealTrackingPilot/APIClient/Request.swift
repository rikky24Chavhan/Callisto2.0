//
//  Request.swift
//
//  Created by Mark Daigneault on 5/3/16.
//  Copyright © 2016 Intrepid Pursuits. All rights reserved.
//

import Foundation

public enum HTTPMethod: String {
    case GET
    case POST
    case PATCH
    case PUT
    case DELETE
}

public protocol Request {
    static var baseURL: String { get }
    static var acceptHeader: String? { get }
    var method: HTTPMethod { get }
    var path: String { get }
    var authenticated: Bool { get }
    var queryParameters: [String: Any]? { get }
    var bodyParameters: [String: Any]? { get }
    var contentType: String { get }
    var accessCredentials: AccessCredentials? { get }
}

public extension Request {

    var urlRequest: URLRequest {
        let baseURL = Foundation.URL(string: Self.baseURL)!
        let url = Foundation.URL(string: path, relativeTo: baseURL) ?? baseURL
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.setValue(Self.acceptHeader, forHTTPHeaderField: "Accept")
        request.setValue(contentType, forHTTPHeaderField: "Content-Type")
        
        /*
        if authenticated {
            accessCredentials?.authorize(&request)
        }
        */
        
        let value = "eyJhbGciOiJIUzUxMiIsInR5cCI6IkpXVCJ9.eyJhdWQiOiJVc2VyOmUwNTY5OTMyLTE1MDctNGNmNi05NWU2LWIyNTU0MTgwMjk4OCIsImV4cCI6MTU2ODE4MzYxNCwiaWF0IjoxNTY1NTkxNjE0LCJpc3MiOiJMaWxseUNhcmJMb2dTZXJ2ZXIiLCJqdGkiOiIwYmQxMjIxYi0zYTdhLTQyMWMtODkyOC0yNWE3YzQzN2FjNzYiLCJwZW0iOnt9LCJzdWIiOiJVc2VyOmUwNTY5OTMyLTE1MDctNGNmNi05NWU2LWIyNTU0MTgwMjk4OCIsInR5cCI6ImFjY2VzcyJ9.UxMslU0VvCO7-r_pPquH_6TcBxGzw6ZOl95x1nFFa9MSj9FmsjS7YOc-UJxj34YWKIm9V6DEi_ZXs3Uu_pFVTA"
        let formattedValue = "Bearer \(value)"
        request.setValue(formattedValue, forHTTPHeaderField: "Authorization")
        
        encodeQueryParameters(request: &request, parameters: queryParameters)
        encodeHTTPBody(request: &request, parameters: bodyParameters)
        return request as URLRequest
    }

    private func encodeQueryParameters(request: inout URLRequest, parameters: [String : Any]?) {
        guard let url = request.url,
            var components = URLComponents(url: url, resolvingAgainstBaseURL: false),
            let stringParameters = parameters as? [String : String]
            else { return }

        let queryParameterStringComponents: [String] = stringParameters.map { parameter in
            let key = parameter.0
            let value = parameter.1
            return "\(key)=\(value)"
        }
        let queryParameterString = queryParameterStringComponents.joined(separator: "&")
        let percentEncondedQuery = components.percentEncodedQuery.map { $0 + "&" } ?? "" + queryParameterString
        components.percentEncodedQuery = percentEncondedQuery
        request.url = components.url
    }

    private func encodeHTTPBody(request: inout URLRequest, parameters: [String : Any]?) {
        guard let parameters = parameters else { return }
        do {
            let data = try JSONSerialization.data(withJSONObject: parameters, options: [])
            request.httpBody = data
        } catch {
            print("Error creating JSON paramters")
        }
    }
}
