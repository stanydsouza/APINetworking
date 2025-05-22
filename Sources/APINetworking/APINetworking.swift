//
//  APINetworking.swift
//  BankingApp
//
//  Created by Stany Bluebik on 21/05/2024.
//

import Foundation

public protocol APINetworkingProtocol: AnyObject {
    
    func sendRequest(_ request: URLRequest) async throws -> Data
    
    func sendRequest<T: Decodable>(_ request: URLRequest, decoder: JSONDecoder) async throws -> T
    
    func sendRequest(apiUrl: String, apiMethod: APIMethod, headers: [String:String]?) async throws -> Data
    
    func sendRequest<T: Decodable>(apiUrl: String, apiMethod: APIMethod, headers: [String:String]?, decoder: JSONDecoder) async throws -> T
    
    func sendRequest(url: URL, apiMethod: APIMethod, headers: [String:String]?) async throws -> Data
    
    func sendRequest<T: Decodable>(url: URL, apiMethod: APIMethod, headers: [String:String]?, decoder: JSONDecoder) async throws -> T
    
}

public final class APINetworking: APINetworkingProtocol {
    
    public static let shared: APINetworkingProtocol = APINetworking()
    
    private init() {}
    
    private func createRequest(url: URL, apiMethod: APIMethod, headers: [String : String]?) throws -> URLRequest {
        
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
    
    private func createRequest(apiUrl: String, apiMethod: APIMethod, headers: [String : String]?) throws -> URLRequest {
        guard let url = URL(string: apiUrl) else { throw APIError.urlError }
        return try createRequest(url: url, apiMethod: apiMethod, headers: headers)
    }
    
    public func sendRequest(url: URL, apiMethod: APIMethod, headers: [String : String]?) async throws -> Data {
        let request = try createRequest(
            url: url,
            apiMethod: apiMethod,
            headers: headers
        )
        return try await sendRequest(request)
    }
    
    public func sendRequest<T>(url: URL, apiMethod: APIMethod, headers: [String : String]?, decoder: JSONDecoder) async throws -> T where T : Decodable {
        let request = try createRequest(
            url: url,
            apiMethod: apiMethod,
            headers: headers
        )
        return try await sendRequest(request, decoder: decoder)
    }
    
    public func sendRequest(apiUrl: String, apiMethod: APIMethod, headers: [String:String]?) async throws -> Data {
        let request = try createRequest(
            apiUrl: apiUrl,
            apiMethod: apiMethod,
            headers: headers
        )
        return try await sendRequest(request)
    }
    
    public func sendRequest<T>(
        apiUrl: String,
        apiMethod: APIMethod,
        headers: [String : String]?,
        decoder: JSONDecoder
    ) async throws -> T where T : Decodable {
        let request = try createRequest(
            apiUrl: apiUrl,
            apiMethod: apiMethod,
            headers: headers
        )
        return try await sendRequest(request, decoder: decoder)
    }
    
    public func sendRequest<T: Decodable>(
        _ request: URLRequest,
        decoder: JSONDecoder
    ) async throws -> T {
        let data = try await sendRequest(request)
        
        do {
            let resp = try decoder.decode(T.self, from: data)
            return resp
        }
        catch{
            throw APIError.jsonDecoding
        }
    }
    
    public func sendRequest(
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

public extension APINetworkingProtocol {
    func sendRequest<T: Decodable>(_ request: URLRequest, decoder: JSONDecoder = JSONDecoder()) async throws -> T {
        try await sendRequest(request, decoder: decoder)
    }
    
    func sendRequest<T: Decodable>(apiUrl: String, apiMethod: APIMethod, headers: [String:String]? = nil, decoder: JSONDecoder = JSONDecoder()) async throws -> T {
        try await sendRequest(apiUrl: apiUrl, apiMethod: apiMethod, headers: headers, decoder: decoder)
    }
    
    func sendRequest<T: Decodable>(url: URL, apiMethod: APIMethod, headers: [String:String]? = nil, decoder: JSONDecoder = JSONDecoder()) async throws -> T {
        try await sendRequest(url: url, apiMethod: apiMethod, headers: headers, decoder: decoder)
    }
}
