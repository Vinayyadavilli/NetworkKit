//
//  NetworkError.swift
//  NetworkKit
//
//  Created by vinay yadavilli on 12/08/26.
//

import Foundation

public enum NetworkError: Error {
    case invalidResponse
    case unauthorized
    case forbidden
    case notFound
    case serverError(Int)
    case decodingError(Error)
    case encodingError(Error)
    case requestFailed(Error)
}
