# NetworkKit

A lightweight, protocol-based networking framework for iOS, built for testability and clean architecture.

## Usage

### 1. Global Configuration (App Launch)
Set your base URL and environment parameters at app launch:

```swift
@main
struct MyApp: App {
    init() {
        NetworkConfiguration.shared.configure(with: .init(
            baseURL: URL(string: "https://api.myapp.com/v1")!,
            environment: .production,
            logLevel: .info
        ))
    }
}
```

### 2. Building the Network Client
Construct a client using `NetworkClientBuilder`, usually inside a dependency injection container. You can attach interceptors like Auth or Logging:

```swift
let client: NetworkClientProtocol = NetworkClientBuilder()
    .setSession(.shared)
    .add(requestInterceptor: AuthInterceptor(tokenProvider: KeychainTokenStore()))
    .add(requestInterceptor: LoggingInterceptor())
    .build()
```

### 3. Defining an Endpoint (Request)
Create structs that conform to the `NetworkRequest` protocol to define your specific endpoints.

```swift
import NetworkKit

struct LoginResponse: Decodable {
    let resultStatus: String
    let reportStatus: String
}

struct LoginRequest: NetworkRequest {
    typealias Response = LoginResponse
    
    // The path gets automatically appended to the global baseURL
    let path = "/api/accounts/one50login/"
    let method: HTTPMethod = .POST
    
    let mobileNumber: String
    let code: String
    
    private struct Body: Encodable {
        let mobileNumber: String
        let code: String
    }
    
    var body: Encodable? { 
        Body(mobileNumber: mobileNumber, code: code) 
    }
}
```
*(Note: If you want to use a full URL instead of the global baseURL, you can simply override `var baseURL: URL { URL(string: "https://full-url.com")! }` in your request struct and leave `let path = ""`)*

### 4. Making the API Call (ViewModel)
Inject the `NetworkClientProtocol` into your ViewModels to keep them decoupled from the actual networking implementation:

```swift
@MainActor
final class LoginViewModel: ObservableObject {
    @Published var responseMessage: String = ""
    private let client: NetworkClientProtocol

    init(client: NetworkClientProtocol) {
        self.client = client
    }

    func login() async {
        let request = LoginRequest(mobileNumber: "1234567890", code: "91")
        
        do {
            let response = try await client.send(request)
            self.responseMessage = response.reportStatus
        } catch {
            print("Error: \(error)")
        }
    }
}
```

### 5. Testing
Since you are using `NetworkClientProtocol`, you can easily mock the client in your unit tests:

```swift
func test_login_success() async throws {
    let mock = MockNetworkClient()
    mock.stubbedResult = LoginResponse(resultStatus: "true", reportStatus: "Success")

    let vm = LoginViewModel(client: mock)
    await vm.login()

    XCTAssertEqual(vm.responseMessage, "Success")
    XCTAssertEqual(mock.callCount, 1)
}
```
