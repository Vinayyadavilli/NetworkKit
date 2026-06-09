// NetworkKit/Tests/NetworkKitTests/Cases/NetworkRequestTests.swift

import XCTest
@testable import NetworkKit

final class NetworkRequestTests: XCTestCase {

    // MARK: - Sample Request

    struct GetUsersRequest: NetworkRequest {
        typealias Response = [UserDTO]
        let path = "/users"
        let method: HTTPMethod = .GET
        var queryParameters: QueryParameters? = ["page": "1", "limit": "20"]
    }

    struct UserDTO: Decodable {
        let id: Int
        let name: String
    }

    // MARK: - Tests

    func test_buildURLRequest_setsCorrectMethod() throws {
        let request = GetUsersRequest()
        let urlRequest = try request.asURLRequest()
        XCTAssertEqual(urlRequest.httpMethod, "GET")
    }

    func test_buildURLRequest_appendsQueryParameters() throws {
        let request = GetUsersRequest()
        let urlRequest = try request.asURLRequest()
        let components = URLComponents(url: urlRequest.url!, resolvingAgainstBaseURL: false)
        let items = components?.queryItems?.sorted { $0.name < $1.name }
        XCTAssertEqual(items?.first(where: { $0.name == "limit" })?.value, "20")
        XCTAssertEqual(items?.first(where: { $0.name == "page" })?.value, "1")
    }

    func test_buildURLRequest_setsContentTypeForPostBody() throws {
        struct CreateUserRequest: NetworkRequest {
            typealias Response = UserDTO
            let path = "/users"
            let method: HTTPMethod = .POST
            struct Body: Encodable { let name: String }
            var body: Encodable? { Body(name: "Alice") }
        }
        let urlRequest = try CreateUserRequest().asURLRequest()
        XCTAssertEqual(urlRequest.value(forHTTPHeaderField: "Content-Type"), "application/json")
        XCTAssertNotNil(urlRequest.httpBody)
    }

    func test_mockClient_returnsStub() async throws {
        let mock = MockNetworkClient()
        mock.stubbedResult = [UserDTO(id: 1, name: "Alice")]

        let result: [UserDTO] = try await mock.send(GetUsersRequest())
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.name, "Alice")
        XCTAssertEqual(mock.callCount, 1)
    }

    func test_mockClient_throwsStubError() async {
        let mock = MockNetworkClient()
        mock.stubbedError = NetworkError.unauthorized

        do {
            _ = try await mock.send(GetUsersRequest())
            XCTFail("Expected error to be thrown")
        } catch let error as NetworkError {
            XCTAssertEqual(error, .unauthorized)
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }
}
