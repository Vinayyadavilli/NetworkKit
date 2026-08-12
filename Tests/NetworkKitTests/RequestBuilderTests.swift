//
//  RequestBuilderTests.swift
//  NetworkKit
//
//  Created by vinay yadavilli on 12/08/26.
//

import Foundation
import Testing
@testable import NetworkKit

// MARK: - Test Endpoint Helpers

/// A simple test endpoint for use in RequestBuilder tests.
struct TestEndpoint: Endpoint {
    var path: String = "/test"
    var method: HTTPMethod = .GET
    var headers: [String: String]? = nil
    var queryItems: [URLQueryItem]? = nil
    var body: RequestBody? = nil
}

/// A simple Codable struct for testing JSON encoding.
struct TestPayload: Codable, Sendable {
    let name: String
    let age: Int
}

// MARK: - RequestBuilder Tests

@Suite("RequestBuilder Tests")
struct RequestBuilderTests {

    let baseURL = URL(string: "https://api.example.com")!

    var builder: RequestBuilder {
        RequestBuilder(
            configuration: NetworkConfiguration(baseURL: baseURL, timeout: 15)
        )
    }

    // MARK: - Basic URL Building

    @Test("builds correct URL from endpoint path")
    func buildURLFromEndpointPath() throws {
        var endpoint = TestEndpoint()
        endpoint.path = "/users/123"

        let request = try builder.build(from: endpoint)

        #expect(request.url?.absoluteString == "https://api.example.com/users/123")
    }

    @Test("sets correct HTTP method")
    func setsHTTPMethod() throws {
        var endpoint = TestEndpoint()
        endpoint.method = .POST

        let request = try builder.build(from: endpoint)

        #expect(request.httpMethod == "POST")
    }

    @Test("sets timeout from configuration")
    func setsTimeout() throws {
        let endpoint = TestEndpoint()
        let request = try builder.build(from: endpoint)

        #expect(request.timeoutInterval == 15)
    }

    // MARK: - Headers

    @Test("applies endpoint headers")
    func appliesHeaders() throws {
        var endpoint = TestEndpoint()
        endpoint.headers = [
            "Authorization": "Bearer token123",
            "Accept": "application/json"
        ]

        let request = try builder.build(from: endpoint)

        #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer token123")
        #expect(request.value(forHTTPHeaderField: "Accept") == "application/json")
    }

    // MARK: - Query Parameters

    @Test("appends query parameters to URL")
    func appendsQueryParameters() throws {
        var endpoint = TestEndpoint()
        endpoint.path = "/search"
        endpoint.queryItems = [
            URLQueryItem(name: "q", value: "swift"),
            URLQueryItem(name: "page", value: "1")
        ]

        let request = try builder.build(from: endpoint)

        let components = URLComponents(url: request.url!, resolvingAgainstBaseURL: false)
        let queryItems = components?.queryItems ?? []

        #expect(queryItems.contains(URLQueryItem(name: "q", value: "swift")))
        #expect(queryItems.contains(URLQueryItem(name: "page", value: "1")))
    }

    // MARK: - JSON Body

    @Test("encodes JSON body and sets content type")
    func encodesJSONBody() throws {
        var endpoint = TestEndpoint()
        endpoint.method = .POST
        endpoint.body = .json(TestPayload(name: "Vinay", age: 25))

        let request = try builder.build(from: endpoint)

        #expect(request.value(forHTTPHeaderField: "Content-Type") == "application/json")
        #expect(request.httpBody != nil)

        // Verify the JSON can be decoded back
        let decoded = try JSONDecoder().decode(TestPayload.self, from: request.httpBody!)
        #expect(decoded.name == "Vinay")
        #expect(decoded.age == 25)
    }

    // MARK: - Form Data Body

    @Test("encodes form data body and sets content type")
    func encodesFormDataBody() throws {
        var endpoint = TestEndpoint()
        endpoint.method = .POST
        endpoint.body = .formData([
            "username": "vinay",
            "password": "secret"
        ])

        let request = try builder.build(from: endpoint)

        #expect(request.value(forHTTPHeaderField: "Content-Type") == "application/x-www-form-urlencoded")
        #expect(request.httpBody != nil)

        let bodyString = String(data: request.httpBody!, encoding: .utf8)!
        #expect(bodyString.contains("username=vinay"))
        #expect(bodyString.contains("password=secret"))
    }

    // MARK: - Multipart Body

    @Test("encodes multipart body and sets content type with boundary")
    func encodesMultipartBody() throws {
        let imageData = "fake-image-data".data(using: .utf8)!
        let file = MultipartFile(
            fieldName: "avatar",
            fileName: "photo.jpg",
            mimeType: "image/jpeg",
            data: imageData
        )

        var endpoint = TestEndpoint()
        endpoint.method = .POST
        endpoint.body = .multipart(files: [file], fields: ["caption": "My Photo"])

        let request = try builder.build(from: endpoint)

        let contentType = request.value(forHTTPHeaderField: "Content-Type")!
        #expect(contentType.starts(with: "multipart/form-data; boundary="))
        #expect(request.httpBody != nil)

        let bodyString = String(data: request.httpBody!, encoding: .utf8)!
        #expect(bodyString.contains("name=\"avatar\""))
        #expect(bodyString.contains("filename=\"photo.jpg\""))
        #expect(bodyString.contains("Content-Type: image/jpeg"))
        #expect(bodyString.contains("fake-image-data"))
        #expect(bodyString.contains("name=\"caption\""))
        #expect(bodyString.contains("My Photo"))
    }

    // MARK: - Raw Body

    @Test("sets raw body data and custom content type")
    func setsRawBody() throws {
        let xmlData = "<root><item>hello</item></root>".data(using: .utf8)!

        var endpoint = TestEndpoint()
        endpoint.method = .POST
        endpoint.body = .raw(xmlData, contentType: "application/xml")

        let request = try builder.build(from: endpoint)

        #expect(request.value(forHTTPHeaderField: "Content-Type") == "application/xml")
        #expect(request.httpBody == xmlData)
    }

    // MARK: - Legacy Manual Build

    @Test("legacy build method constructs correct request")
    func legacyBuildMethod() throws {
        let request = try builder.build(
            path: "/posts",
            method: .GET,
            headers: ["Accept": "application/json"],
            queryItems: [URLQueryItem(name: "limit", value: "10")]
        )

        #expect(request.httpMethod == "GET")
        #expect(request.value(forHTTPHeaderField: "Accept") == "application/json")

        let components = URLComponents(url: request.url!, resolvingAgainstBaseURL: false)
        #expect(components?.queryItems?.contains(URLQueryItem(name: "limit", value: "10")) == true)
    }
}
