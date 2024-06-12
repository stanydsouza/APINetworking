//
//  APIMethod.swift
//  BankingApp
//
//  Created by Stany Bluebik on 21/05/2024.
//

import Foundation

public enum APIMethod {
    
    case get
    case put(Data?)
    case post(Data?)
    case patch(Data?)
    case delete(Data?)
    
    var method: String {
        switch self {
        
        case .get:
            "GET"
        case .put(_):
            "PUT"
        case .post(_):
            "POST"
        case .patch(_):
            "PATCH"
        case .delete(_):
            "DELETE"
        }
    }
    
    var body: Data? {
        switch self {
        
        case .get:
            nil
        case .put(let body), .post(let body), .patch(let body), .delete(let body):
            body
        }
    }
    
}
