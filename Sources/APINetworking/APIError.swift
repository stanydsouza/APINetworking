//
//  APIError.swift
//  APIServiceDemo
//
//  Created by Stany Dsouza on 02/07/22.
//

import Foundation

public enum APIError : Error, LocalizedError, Equatable {
    
    case apiError(reason: String)
    case jsonDecoding
    case noData
    case unableToProcess
    case serverError
    case urlError
    case noResponse
    case emptyBody
    case invalidResponse(code: Int)
    
    public var errorDescription: String?{
        switch self {
        case .jsonDecoding: "Json decoding error"
        case .noData: "No data found"
        case .unableToProcess: "Unable to process at the moment"
        case .serverError: "Invalid response form server"
        case .urlError: "Invalid url"
        case .noResponse: "No response from server"
        case .emptyBody: "Empty body in request"
        case .apiError(let reason): reason
        case .invalidResponse(let code): "Invalid Response. (Status Code: \(code))"
        }
    }
    
}
