import Foundation

public enum HTTPClientConfigurationError: Error, Equatable, Sendable {
    case invalidRequestTimeout
}

public enum HTTPTransportError: Error, Equatable, Sendable {
    case invalidResponse
    case timedOut
    case notConnectedToInternet
    case networkConnectionLost
    case urlError(code: URLError.Code)
    case unexpected
}

public final class URLSessionHTTPClient: HTTPClient, Sendable {
    public static let defaultRequestTimeout: TimeInterval = 30

    private let session: URLSession
    private let boundedSession: URLSession
    private let boundedLoader: BoundedURLSessionDataLoader
    private let requestTimeout: TimeInterval

    public init(
        requestTimeout: TimeInterval = URLSessionHTTPClient.defaultRequestTimeout
    ) throws {
        let configuration = try Self.makeLiveConfiguration(requestTimeout: requestTimeout)
        session = URLSession(configuration: configuration)
        let loader = BoundedURLSessionDataLoader()
        boundedLoader = loader
        boundedSession = URLSession(
            configuration: configuration,
            delegate: loader,
            delegateQueue: nil
        )
        self.requestTimeout = requestTimeout
    }

    public init(
        session: URLSession,
        requestTimeout: TimeInterval = URLSessionHTTPClient.defaultRequestTimeout
    ) throws {
        try Self.validate(requestTimeout: requestTimeout)
        self.session = session
        let loader = BoundedURLSessionDataLoader()
        boundedLoader = loader
        boundedSession = URLSession(
            configuration: session.configuration,
            delegate: loader,
            delegateQueue: nil
        )
        self.requestTimeout = requestTimeout
    }

    deinit {
        boundedSession.invalidateAndCancel()
    }

    public func send(_ request: HTTPRequest) async throws -> HTTPResponse {
        try Task.checkCancellation()

        var urlRequest = URLRequest(
            url: request.url,
            cachePolicy: request.cachePolicy,
            timeoutInterval: requestTimeout
        )
        urlRequest.httpMethod = request.method.rawValue
        urlRequest.httpBody = request.body
        for (name, value) in request.headers {
            urlRequest.setValue(value, forHTTPHeaderField: name)
        }

        do {
            let body: Data
            let response: URLResponse
            if let maximumResponseBodyBytes = request.maximumResponseBodyBytes {
                guard maximumResponseBodyBytes > 0 else {
                    throw HTTPTransportError.invalidResponse
                }
                (body, response) = try await boundedLoader.data(
                    for: urlRequest,
                    session: boundedSession,
                    maximumBodyBytes: maximumResponseBodyBytes
                )
            } else {
                (body, response) = try await session.data(for: urlRequest)
            }
            try Task.checkCancellation()

            guard let httpResponse = response as? HTTPURLResponse else {
                throw HTTPTransportError.invalidResponse
            }

            return HTTPResponse(
                statusCode: httpResponse.statusCode,
                headers: Self.headers(from: httpResponse),
                body: body
            )
        } catch is CancellationError {
            throw CancellationError()
        } catch let error as HTTPTransportError {
            throw error
        } catch let error as URLError {
            if error.code == .cancelled, Task.isCancelled {
                throw CancellationError()
            }
            throw Self.transportError(for: error.code)
        } catch {
            throw HTTPTransportError.unexpected
        }
    }

    public func invalidate() {
        session.invalidateAndCancel()
        boundedSession.invalidateAndCancel()
    }

    public static func makeLiveConfiguration(
        requestTimeout: TimeInterval
    ) throws -> URLSessionConfiguration {
        try validate(requestTimeout: requestTimeout)
        let configuration = URLSessionConfiguration.ephemeral
        configuration.urlCache = nil
        configuration.httpCookieStorage = nil
        configuration.urlCredentialStorage = nil
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
        configuration.timeoutIntervalForRequest = requestTimeout
        return configuration
    }

    private static func validate(requestTimeout: TimeInterval) throws {
        guard requestTimeout.isFinite, requestTimeout > 0 else {
            throw HTTPClientConfigurationError.invalidRequestTimeout
        }
    }

    private static func headers(from response: HTTPURLResponse) -> [String: String] {
        response.allHeaderFields.reduce(into: [:]) { headers, field in
            headers[String(describing: field.key)] = String(describing: field.value)
        }
    }

    private static func transportError(for code: URLError.Code) -> HTTPTransportError {
        switch code {
        case .timedOut:
            .timedOut
        case .notConnectedToInternet:
            .notConnectedToInternet
        case .networkConnectionLost:
            .networkConnectionLost
        default:
            .urlError(code: code)
        }
    }
}

private final class BoundedURLSessionDataLoader: NSObject, URLSessionDataDelegate, @unchecked Sendable {
    private struct RequestState {
        let continuation: CheckedContinuation<(Data, URLResponse), any Error>
        let maximumBodyBytes: Int
        var response: URLResponse?
        var body = Data()
    }

    private let lock = NSLock()
    private var requests: [Int: RequestState] = [:]

    func data(
        for request: URLRequest,
        session: URLSession,
        maximumBodyBytes: Int
    ) async throws -> (Data, URLResponse) {
        let task = session.dataTask(with: request)
        return try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                lock.withLock {
                    requests[task.taskIdentifier] = RequestState(
                        continuation: continuation,
                        maximumBodyBytes: maximumBodyBytes
                    )
                }
                guard !Task.isCancelled else {
                    cancel(task)
                    return
                }
                task.resume()
            }
        } onCancel: {
            self.cancel(task)
        }
    }

    private func cancel(_ task: URLSessionTask) {
        let continuation = lock.withLock {
            requests.removeValue(forKey: task.taskIdentifier)?.continuation
        }
        task.cancel()
        continuation?.resume(throwing: CancellationError())
    }

    func urlSession(
        _ session: URLSession,
        dataTask: URLSessionDataTask,
        didReceive response: URLResponse,
        completionHandler: @escaping @Sendable (URLSession.ResponseDisposition) -> Void
    ) {
        let exceeded = lock.withLock { () -> Bool in
            guard var state = requests[dataTask.taskIdentifier] else { return true }
            guard response.expectedContentLength < 0
                    || response.expectedContentLength <= state.maximumBodyBytes else {
                return true
            }
            state.response = response
            requests[dataTask.taskIdentifier] = state
            return false
        }
        guard !exceeded else {
            fail(dataTask, with: HTTPTransportError.invalidResponse)
            completionHandler(.cancel)
            return
        }
        completionHandler(.allow)
    }

    func urlSession(
        _ session: URLSession,
        dataTask: URLSessionDataTask,
        didReceive data: Data
    ) {
        let continuation = lock.withLock {
            guard var state = requests[dataTask.taskIdentifier] else {
                return nil as CheckedContinuation<(Data, URLResponse), any Error>?
            }
            guard state.body.count <= state.maximumBodyBytes,
                  data.count <= state.maximumBodyBytes - state.body.count else {
                return requests.removeValue(forKey: dataTask.taskIdentifier)?.continuation
            }
            state.body.append(data)
            requests[dataTask.taskIdentifier] = state
            return nil
        }
        guard let continuation else { return }
        dataTask.cancel()
        continuation.resume(throwing: HTTPTransportError.invalidResponse)
    }

    func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        didCompleteWithError error: (any Error)?
    ) {
        guard let state = lock.withLock({
            requests.removeValue(forKey: task.taskIdentifier)
        }) else { return }
        if let error {
            state.continuation.resume(throwing: error)
        } else if let response = state.response {
            state.continuation.resume(returning: (state.body, response))
        } else {
            state.continuation.resume(throwing: HTTPTransportError.invalidResponse)
        }
    }

    private func fail(_ task: URLSessionTask, with error: any Error) {
        let continuation = lock.withLock {
            requests.removeValue(forKey: task.taskIdentifier)?.continuation
        }
        continuation?.resume(throwing: error)
    }
}

public extension HTTPResponse {
    func headerValue(for name: String) -> String? {
        headers.first { header, _ in
            header.caseInsensitiveCompare(name) == .orderedSame
        }?.value
    }
}
