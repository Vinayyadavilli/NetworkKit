// NetworkKit/Sources/NetworkKit/Utils/ExampleUsage.swift
// ⚠️ This file is for documentation purposes only.
// Copy these patterns into your own feature modules.

import Foundation

/*

 ┌──────────────────────────────────────────────────────┐
 │           HOW TO USE NetworkKit                       │
 └──────────────────────────────────────────────────────┘

 ─── 1. App Launch Setup ────────────────────────────────

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


 ─── 2. Build a shared client (e.g. in a DI container) ──

 let client: NetworkClientProtocol = NetworkClientBuilder()
     .setSession(.shared)
     .add(requestInterceptor: AuthInterceptor(tokenProvider: KeychainTokenStore()))
     .add(requestInterceptor: LoggingInterceptor())
     .build()


 ─── 3. Define an endpoint ──────────────────────────────

 struct GetPostsRequest: NetworkRequest {
     typealias Response = [Post]
     let path = "/posts"
     let method: HTTPMethod = .GET
     let page: Int

     var queryParameters: QueryParameters? {
         ["page": "\(page)", "per_page": "20"]
     }
 }

 struct CreatePostRequest: NetworkRequest {
     typealias Response = Post
     let path = "/posts"
     let method: HTTPMethod = .POST
     let title: String
     let content: String

     struct Body: Encodable { let title: String; let content: String }
     var body: Encodable? { Body(title: title, content: content) }
 }

 struct DeletePostRequest: NetworkRequest {
     typealias Response = EmptyResponse
     let postId: Int
     var path: String { "/posts/\(postId)" }
     let method: HTTPMethod = .DELETE
 }


 ─── 4. Call from a ViewModel / Service ─────────────────

 @MainActor
 final class PostsViewModel: ObservableObject {
     @Published var posts: [Post] = []
     @Published var error: NetworkError?

     private let client: NetworkClientProtocol

     init(client: NetworkClientProtocol) {
         self.client = client
     }

     func loadPosts(page: Int = 1) async {
         do {
             posts = try await client.send(GetPostsRequest(page: page))
         } catch let networkError as NetworkError {
             error = networkError
         } catch {
             self.error = .unknown(error.localizedDescription)
         }
     }
 }


 ─── 5. Testing ─────────────────────────────────────────

 func test_loadPosts_populatesArray() async throws {
     let mock = MockNetworkClient()
     mock.stubbedResult = [Post(id: 1, title: "Hello")]

     let vm = PostsViewModel(client: mock)
     await vm.loadPosts()

     XCTAssertEqual(vm.posts.count, 1)
     XCTAssertEqual(mock.callCount, 1)
 }

*/
