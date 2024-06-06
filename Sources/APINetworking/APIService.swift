//
//  APIService.swift
//  BankingApp
//
//  Created by Stany Bluebik on 21/05/2024.
//

import Foundation

public protocol APIServiceProtocol: AnyObject {
    func callRequest(_ request: URLRequest) async throws -> Data
    
    func callRequest<T: Decodable>(_ request: URLRequest) async throws -> T
    
    func callRequest(serviceUrl: String, apiMethod: APIMethod,  body: Data?, headers: [String:String]?) async throws -> Data
    
    func callRequest<T: Decodable>(serviceUrl: String, apiMethod: APIMethod,  body: Data?, headers: [String:String]?) async throws -> T
    
}

public final class APIService: APIServiceProtocol {
    
    public static let shared: APIServiceProtocol = APIService()
    
    private init() {}
    
    private func createRequest(_ serviceUrl: String, apiMethod: APIMethod, body: Data?, headers: [String : String]) throws -> URLRequest {
        guard let url = URL(string: serviceUrl) else { throw APIError.urlError }
        
        print("API REQUEST:")
        print("URL =>", url)
        
        var request = URLRequest(url: url, timeoutInterval: 30)
        request.httpMethod = apiMethod.rawValue
        print("API Method =>", apiMethod.rawValue)
        
        print("Headers =>", headers)
        for (key, value) in headers {
            request.addValue(value, forHTTPHeaderField: key)
        }
        
        guard apiMethod != .get else { return request }
        
        guard let body else { throw APIError.jsonDecoding }
        print("Body =>", String(data: body, encoding: .utf8))
        request.httpBody = body
        
        return request
    }
    
    public func callRequest(serviceUrl: String, apiMethod: APIMethod,  body: Data?, headers: [String:String]?) async throws -> Data {
        let request = try createRequest(serviceUrl, apiMethod: apiMethod, body: body, headers: headers ?? ["Content-Type": "application/json"])
        return try await callRequest(request)
    }
    
    public func callRequest<T>(serviceUrl: String, apiMethod: APIMethod, body: Data?, headers: [String : String]?) async throws -> T where T : Decodable {
        let request = try createRequest(serviceUrl, apiMethod: apiMethod, body: body, headers: headers ?? ["Content-Type": "application/json"])
        return try await callRequest<T>(request)
    }
    
    public func callRequest<T: Decodable>(_ request: URLRequest) async throws -> T {
        let data = try await callRequest(request)
        
        do {
            let resp = try JSONDecoder().decode(T.self, from: data)
            return resp
        }
        catch{
            throw APIError.jsonDecoding
        }
    }
    
    public func callRequest(_ request: URLRequest) async throws -> Data{
        generateCurlCommand(request: request)
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpStatusCode = (response as? HTTPURLResponse)?.statusCode else {
            print("No httpStatusCode found")
            throw APIError.unableToProcess
        }
        
        guard (200...299).contains(httpStatusCode) else {
            print("Error Response Code =>", httpStatusCode)
            throw APIError.invalidResponse(code: httpStatusCode)
        }
        
        print("API response =>", String(data: data, encoding: .utf8))
        
        return data
    }
    
    private func generateCurlCommand(request: URLRequest) {
        // Extract relevant information from the URLRequest
        let method = request.httpMethod ?? ""
        let url = request.url?.absoluteString ?? ""
        let headers = request.allHTTPHeaderFields ?? [:]
        let body = request.httpBody
        
        // Construct the cURL command
        var curlCommand = "curl -X \(method) '\(url)'"
        
        // Add headers to the cURL command
        for (key, value) in headers {
            let escapedValue = value.replacingOccurrences(of: "'", with: "\\'")
            curlCommand += " -H '\(key): \(escapedValue)'"
        }
        
        // Add request body to the cURL command if it exists
        if let bodyData = body, let bodyString = String(data: bodyData, encoding: .utf8) {
            let escapedBody = bodyString.replacingOccurrences(of: "'", with: "\\'")
            curlCommand += " -d '\(escapedBody)'"
        }
        
        let message = curlCommand.map { String(describing: $0) }.joined(separator: ", ")
        print("curlCommand: \n", curlCommand)
    }
}
