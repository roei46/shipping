//
//  NetworkLayer.swift
//  Shipping
//
//  EndPoint builds the request (url, method, body). NetworkLayer attaches
//  the saved token, sends, maps HTTP statuses from the contract, decodes.
//

import Foundation

enum NetworkError: Error, Equatable {
    case badUrl
    case invalidResponse
    case unauthorized             // 401
    case notFound                 // 404
    case conflict                 // 409
    case validation([FieldError]) // 422
    case statusCode(Int)
    case decodeError
}

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
}

protocol EnumProtocol {
    var method: HTTPMethod { get }
    var path: String { get }
    var requiresAuth: Bool { get }
    var request: URLRequest? { get }
}

enum EndPoint: EnumProtocol {
    case login(username: String, password: String)
    case shipments
    case createShipment(request: ShipmentRequest)
    case shipment(id: String)
    case approve(id: String, optionId: String)
    case registerDevice(deviceToken: String)

    // Local FastAPI server (uvicorn default port).
    private var baseUrl: String {
        "http://localhost:8000"
    }

    var method: HTTPMethod {
        switch self {
        case .shipments, .shipment:
            .get
        case .login, .createShipment, .approve, .registerDevice:
            .post
        }
    }

    var path: String {
        switch self {
        case .login:
            "/customer/login"
        case .shipments, .createShipment:
            "/customer/shipments"
        case .shipment(let id):
            "/customer/shipments/\(id)"
        case .approve(let id, _):
            "/customer/shipments/\(id)/approve"
        case .registerDevice:
            "/customer/devices"
        }
    }

    // Every call except login sends the token.
    var requiresAuth: Bool {
        switch self {
        case .login:
            false
        default:
            true
        }
    }

    // Like Portfol's queryItems: per-case data in one switch.
    private var bodyItems: (any Encodable)? {
        switch self {
        case .login(let username, let password):
            LoginBody(username: username, password: password)
        case .createShipment(let request):
            CreateShipmentBody(request: request)
        case .approve(_, let optionId):
            ApproveBody(optionId: optionId)
        case .registerDevice(let deviceToken):
            DeviceBody(deviceToken: deviceToken)
        case .shipments, .shipment:
            nil
        }
    }

    var request: URLRequest? {
        var components = URLComponents(string: baseUrl)
        components?.path = path
        guard let url = components?.url else { return nil }

        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        if let bodyItems {
            request.httpBody = try? JSONEncoder().encode(bodyItems)
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        return request
    }
}

protocol NetworkLayerProtocol {
    func fetchData<T: Decodable>(endPoint: EnumProtocol) async throws -> T
}

final class NetworkLayer: NetworkLayerProtocol {
    private let session: URLSession
    private let keychain: KeychainServiceProtocol
    private let decoder = JSONDecoder()

    init(keychain: KeychainServiceProtocol, session: URLSession = .shared) {
        self.keychain = keychain
        self.session = session
    }

    func fetchData<T: Decodable>(endPoint: EnumProtocol) async throws -> T {
        guard var request = endPoint.request else { throw NetworkError.badUrl }

        // The one cross-cutting step: attach the saved token.
        if endPoint.requiresAuth, let token = keychain.token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let (data, response) = try await session.data(for: request)

        guard let response = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }

        switch response.statusCode {
        case 200...299:
            break
        case 401:
            throw NetworkError.unauthorized
        case 404:
            throw NetworkError.notFound
        case 409:
            throw NetworkError.conflict
        case 422:
            let dto = try? decoder.decode(ValidationErrorsDTO.self, from: data)
            let errors = dto?.errors.map { FieldError(field: $0.field, message: $0.message) } ?? []
            throw NetworkError.validation(errors)
        default:
            throw NetworkError.statusCode(response.statusCode)
        }

        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw NetworkError.decodeError
        }
    }
}
