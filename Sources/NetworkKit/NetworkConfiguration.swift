//
//  NetworkConfiguration.swift
//  NetworkKit
//
//  Created by vinay yadavilli on 12/08/26.
//

import Foundation

public struct NetworkConfiguration {
    public let baseURL: URL
    public let timeout: TimeInterval
    
    public init(baseURL: URL, timeout: TimeInterval = 30) {
        self.baseURL = baseURL
        self.timeout = timeout
    }
}
