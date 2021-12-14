//
//  Newversion.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 12/04/2021.
//

import Combine
import Foundation

enum APIError: Error, LocalizedError {
    case unknown, apiError(reason: String)

    var errorDescription: String? {
        switch self {
        case .unknown:
            return "Unknown error"
        case let .apiError(reason):
            return reason
        }
    }
}

final class NewversionPLIST: ObservableObject {
    @Published var notifynewversion: Bool = false

    private var runningversion: String?
    private var subscriber: AnyCancellable?

    func verifynewversion(_: String, _: String) {
        // print(runningversion)
        // print(data)
        subscriber?.cancel()
    }

    init() {
        runningversion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
        if let baseURL = URL(string: Resources().getResource(resource: .urlPLIST)) {
            let request = URLRequest(url: baseURL)
            let resource = Resource<Data>(request: request)
            subscriber = URLSession.shared.fetchData(for: resource)
                .sink(receiveCompletion: { completion in
                    switch completion {
                    case .finished:
                        return
                    case let .failure(error):
                        self.propogateerror(error: error)
                    }
                }, receiveValue: { [unowned self] data in
                    // Convert data to String
                    if let response = String(data: data, encoding: .utf8),
                       let runningversion = runningversion
                    {
                        verifynewversion(runningversion, response)
                    }
                })
        }
    }
}

extension URLSession {
    func fetchData<T>(for resource: Resource<T>) -> AnyPublisher<T, Error> {
        return dataTaskPublisher(for: resource.request)
            .tryMap { element -> T in
                guard let httpResponse = element.response as? HTTPURLResponse,
                      200 ..< 300 ~= httpResponse.statusCode
                else {
                    throw APIError.unknown
                }
                if let data = element.data as? T {
                    return data
                }
                throw APIError.unknown
            }
            .mapError { error in
                if let error = error as? APIError {
                    return error
                } else {
                    return APIError.apiError(reason: error.localizedDescription)
                }
            }
            .eraseToAnyPublisher()
    }
}

extension NewversionPLIST: PropogateError {
    func propogateerror(error: Error) {
        SharedReference.shared.errorobject?.propogateerror(error: error)
    }
}
