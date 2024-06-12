//
//  APINetworking.swift
//  BankingApp
//
//  Created by Stany Bluebik on 21/05/2024.
//

import Foundation

public protocol APINetworkingProtocol: AnyObject {
    
    func callRequest(_ request: URLRequest) async throws -> Data
    
    func callRequest<T: Decodable>(_ request: URLRequest) async throws -> T
    
    func callRequest(apiUrl: String, apiMethod: APIMethod, headers: [String:String]?) async throws -> Data
    
    func callRequest<T: Decodable>(apiUrl: String, apiMethod: APIMethod, headers: [String:String]?) async throws -> T
    
}

public final class APINetworking: APINetworkingProtocol {
    
    public static let shared: APINetworkingProtocol = APINetworking()
    
    private init() {}
    
    private func createRequest(apiUrl: String, apiMethod: APIMethod, headers: [String : String]?) throws -> URLRequest {
        guard let url = URL(string: apiUrl) else { throw APIError.urlError }
        
        let reqHeaders = headers ?? ["Content-Type": "application/json"]
        
#if DEBUG
        print("API REQUEST:")
        print("URL =>", url)
        print("API Method =>", apiMethod.method)
        print("Headers =>", reqHeaders)
#endif
        
        var request = URLRequest(url: url, timeoutInterval: 30)
        request.httpMethod = apiMethod.method
        
        for (key, value) in reqHeaders {
            request.addValue(value, forHTTPHeaderField: key)
        }
        
#if DEBUG
        if let body = apiMethod.body {
            print("Body =>", String(data: body, encoding: .utf8) ?? "No Request Body")
        }
#endif
        request.httpBody = apiMethod.body
        
        return request
    }
    
    public func callRequest(
        apiUrl: String,
        apiMethod: APIMethod,
        headers: [String:String]?
    ) async throws -> Data {
        let request = try createRequest(
            apiUrl: apiUrl,
            apiMethod: apiMethod,
            headers: headers
        )
        return try await callRequest(request)
    }
    
    public func callRequest<T>(
        apiUrl: String,
        apiMethod: APIMethod,
        headers: [String : String]?
    ) async throws -> T where T : Decodable {
        let request = try createRequest(
            apiUrl: apiUrl,
            apiMethod: apiMethod,
            headers: headers
        )
        return try await callRequest<T>(request)
    }
    
    public func callRequest<T: Decodable>(
        _ request: URLRequest
    ) async throws -> T {
        let data = try await callRequest(request)
        
        do {
            let resp = try JSONDecoder().decode(T.self, from: data)
            return resp
        }
        catch{
            throw APIError.jsonDecoding
        }
    }
    
    public func callRequest(
        _ request: URLRequest
    ) async throws -> Data{
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpStatusCode = (response as? HTTPURLResponse)?.statusCode else {
#if DEBUG
            print("No httpStatusCode found")
#endif
            throw APIError.unableToProcess
        }
        
        guard (200...299).contains(httpStatusCode) else {
#if DEBUG
            print("Error Response Code =>", httpStatusCode)
#endif
            throw APIError.invalidResponse(code: httpStatusCode)
        }
#if DEBUG
        print("API response =>", String(data: data, encoding: .utf8) ?? "Unable to print response")
#endif
        return data
    }
}
