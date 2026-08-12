# NetworkKit

[![Swift 6.0](https://img.shields.io/badge/Swift-6.0-orange.svg?style=flat)](https://swift.org)
[![Platform](https://img.shields.io/badge/Platforms-iOS%2015.0%2B%20%7C%20macOS%2012.0%2B-blue.svg?style=flat)](https://developer.apple.com/swift/)
[![License](https://img.shields.io/badge/License-MIT-lightgrey.svg)](LICENSE)

**NetworkKit** is a lightweight, modern, protocol-oriented Swift networking library built on top of `URLSession` using native `async/await`. It provides a type-safe `Endpoint` architecture, request body encoding (JSON, Form-Data, Multipart file uploads), query parameter management, request interceptors (for auth tokens), and mock testing support.

---

## ✨ Features

- ⚡️ **Native Async/Await**: Leverages modern Swift concurrency.
- 🎯 **Type-Safe `Endpoint` Abstraction**: Clean, declarative API routing.
- 📦 **Multiple Request Body Formats**:
  - `JSON` (via `Encodable` models or custom `JSONEncoder`)
  - `Form-Data` (`application/x-www-form-urlencoded`)
  - `Multipart Form-Data` (for file, image, and document uploads)
  - `Raw Data` (XML, plain text, custom binaries)
- 🔍 **Query Parameter Support**: Easily append URL query items (`?key=value`).
- 🔒 **Request Interceptors**: Inject Auth Bearer tokens, API keys, or custom headers seamlessly.
- 🛡️ **Comprehensive Error Handling**: Validates HTTP status codes (`401`, `403`, `404`, `5xx`) and decoding failures.
- 🧪 **Testable Architecture**: Includes `MockURLProtocol` for fast, offline unit testing.

---

## 💻 Requirements

- **iOS** 15.0+ / **macOS** 12.0+
- **Swift** 6.0+
- **Xcode** 15.0+

---

## 📦 Installation

### Swift Package Manager (SPM)

#### In Xcode:
1. Open your project in Xcode.
2. Go to **File** > **Add Package Dependencies...**
3. Enter the repository URL:
   ```text
   https://github.com/Vinayyadavilli/NetworkKit.git
   ```
4. Select the version requirement and click **Add Package**.

#### In `Package.swift`:
```swift
dependencies: [
    .package(url: "https://github.com/Vinayyadavilli/NetworkKit.git", from: "1.0.0")
]
```

---

## 🚀 Quick Start & Usage

### 1. Define your Response Models

```swift
import Foundation

struct User: Codable, Identifiable {
    let id: Int
    let name: String
    let email: String
}
```

---

### 2. Create Type-Safe Endpoints

Conform an enum or struct to the `Endpoint` protocol:

```swift
import Foundation
import NetworkKit

enum UserEndpoint: Endpoint {
    case getUsers(page: Int)
    case getUser(id: Int)
    case createUser(name: String, email: String)
    case uploadAvatar(userId: Int, imageData: Data)
    
    var path: String {
        switch self {
        case .getUsers:
            return "/users"
        case .getUser(let id), .uploadAvatar(let id, _):
            return "/users/\(id)"
        case .createUser:
            return "/users"
        }
    }
    
    var method: HTTPMethod {
        switch self {
        case .getUsers, .getUser:
            return .GET
        case .createUser, .uploadAvatar:
            return .POST
        }
    }
    
    var headers: [String: String]? {
        nil // Add custom headers if needed
    }
    
    var queryItems: [URLQueryItem]? {
        switch self {
        case .getUsers(let page):
            return [URLQueryItem(name: "page", value: "\(page)")]
        default:
            return nil
        }
    }
    
    var body: RequestBody? {
        switch self {
        case .createUser(let name, let email):
            return .json(["name": name, "email": email])
            
        case .uploadAvatar(_, let imageData):
            let file = MultipartFile(
                fieldName: "avatar",
                fileName: "photo.jpg",
                mimeType: "image/jpeg",
                data: imageData
            )
            return .multipart(files: [file], fields: ["quality": "high"])
            
        default:
            return nil
        }
    }
}
```

---

### 3. Initialize & Execute Requests

```swift
import Foundation
import NetworkKit

// 1. Define configuration
let configuration = NetworkConfiguration(
    baseURL: URL(string: "https://api.example.com")!,
    timeout: 30
)

// 2. Initialize NetworkManager
let networkManager: NetworkManagerProtocol = NetworkManager(configuration: configuration)

// 3. Make requests
func fetchUsers() async {
    do {
        // GET /users?page=1
        let users: [User] = try await networkManager.request(UserEndpoint.getUsers(page: 1))
        print("Fetched \(users.count) users")
    } catch let error as NetworkError {
        handleNetworkError(error)
    } catch {
        print("Unexpected error: \(error)")
    }
}
```

---

### 4. Authentication & Request Interceptors

Automatically inject `Authorization` Bearer tokens or API keys into every outgoing request by conforming to `RequestInterceptor`:

```swift
import Foundation
import NetworkKit

struct AuthInterceptor: RequestInterceptor {
    let tokenProvider: () -> String?
    
    func adapt(_ request: URLRequest) async throws -> URLRequest {
        var request = request
        if let token = tokenProvider() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        return request
    }
}

// Attach interceptor to NetworkManager
let authInterceptor = AuthInterceptor(tokenProvider: { "my_secret_bearer_token" })

let networkManager = NetworkManager(
    configuration: configuration,
    interceptors: [authInterceptor]
)
```

---

### 5. Error Handling

`NetworkKit` provides structured error cases via `NetworkError`:

```swift
func handleNetworkError(_ error: NetworkError) {
    switch error {
    case .unauthorized:
        print("401 Unauthorized — Prompt login screen")
    case .forbidden:
        print("403 Forbidden — Access denied")
    case .notFound:
        print("404 Not Found")
    case .serverError(let statusCode):
        print("Server Error: HTTP \(statusCode)")
    case .decodingError(let error):
        print("JSON Decoding Failed: \(error.localizedDescription)")
    case .requestFailed(let error):
        print("Network Connection Error: \(error.localizedDescription)")
    default:
        print("Error: \(error)")
    }
}
```

---

### 6. Unit Testing with `MockURLProtocol`

You can unit test your ViewModels or Services without making real network calls:

```swift
import Testing
@testable import NetworkKit

@Test func testFetchUserSuccess() async throws {
    // 1. Setup Mock Handler
    MockURLProtocol.requestHandler = { request in
        let json = """
        {"id": 1, "name": "Vinay", "email": "vinay@example.com"}
        """.data(using: .utf8)!
        
        let response = HTTPURLResponse(
            url: request.url!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )!
        return (response, json)
    }
    
    // 2. Configure URLSession with MockURLProtocol
    let config = URLSessionConfiguration.ephemeral
    config.protocolClasses = [MockURLProtocol.self]
    let mockSession = URLSession(configuration: config)
    
    let manager = NetworkManager(
        configuration: NetworkConfiguration(baseURL: URL(string: "https://api.example.com")!),
        session: mockSession
    )
    
    // 3. Execute request & assert
    let user: User = try await manager.request(UserEndpoint.getUser(id: 1))
    #expect(user.name == "Vinay")
}
```

---

## 📁 Repository Structure

```text
Sources/NetworkKit/
├── Core/
│   ├── NetworkManager.swift            # Main network execution engine
│   ├── NetworkManagerProtocol.swift    # Network manager protocol requirement
│   └── NetworkConfiguration.swift      # Base URL & timeout configuration
├── Endpoint/
│   ├── Endpoint.swift                  # Endpoint protocol definition
│   ├── RequestBody.swift               # Request body options (.json, .formData, .multipart, .raw)
│   └── HTTPMethod.swift                # HTTP method enum (GET, POST, PUT, PATCH, DELETE, HEAD)
├── Request/
│   ├── RequestBuilder.swift            # Assembles URLRequests with headers & query items
│   ├── RequestInterceptor.swift        # Middleware protocol for request modification
│   ├── MultipartFile.swift             # Model for uploading files/images
│   └── MultipartFormDataBuilder.swift  # Encodes multipart/form-data with boundaries
└── Response/
    ├── ResponseHandler.swift           # Validates HTTP status codes & parses JSON
    └── NetworkError.swift              # Custom NetworkKit error enum
```

---

## 📝 License

Distributed under the MIT License. See `LICENSE` for more information.
