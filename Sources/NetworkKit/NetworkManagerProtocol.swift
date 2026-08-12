//
//  NetworkManagerProtocol.swift
//  NetworkKit
//
//  Created by vinay yadavilli on 12/08/26.
//

import Foundation

public protocol NetworkManagerProtocol {

    func request<T: Decodable>(
        _ request: URLRequest
    ) async throws -> T
}
