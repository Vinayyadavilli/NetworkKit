//
//  Untitled.swift
//  NetworkKit
//
//  Created by vinay yadavilli on 12/08/26.
//

import Foundation

public final class NetworkManager: NetworkManagerProtocol {
    private let session: URLSession
    
    public init(session: URLSession = .shared) {
        self.session = session
    }
    
    public func  request<T: Decodable>(
        _ request: URLRequest
    ) async throws -> T {
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw NetworkError.invalidResponse
            }
            
            try validateStatusCode(
                httpResponse.statusCode,
            )
            
            do {
                return try JSONDecoder().decode(
                    T.self,
                    from: data
                )
            } catch {
                throw NetworkError.decodingError(error)
            }
        } catch let error as NetworkError {
            throw error
        } catch  {
            throw NetworkError.requestFailed(error)
        }
    }
    
    private func validateStatusCode(
        _ statusCode: Int
    ) throws {
        
        switch statusCode {
            
        case 200...299:
            return
            
        case 401:
            throw NetworkError.unauthorized
            
        case 403:
            throw NetworkError.forbidden
            
        case 404:
            throw NetworkError.notFound
            
        case 500...599:
            throw NetworkError.serverError(statusCode)
            
        default:
            throw NetworkError.serverError(statusCode)
        }
    }
}
