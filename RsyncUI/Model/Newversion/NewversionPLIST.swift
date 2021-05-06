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

    func setnewverion(_ respons: String) {
        print(respons)
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
                    guard let response = String(data: data, encoding: .utf8) else { return }
                    setnewverion(response)
                })
        }
    }
}

extension URLSession {
    func fetchData<Data>(for resource: Resource<Data>) -> AnyPublisher<Data, Error> {
        return dataTaskPublisher(for: resource.request)
            .tryMap { data, response in
                guard let httpResponse = response as? HTTPURLResponse, 200 ..< 300 ~= httpResponse.statusCode else {
                    throw APIError.unknown
                }
                return (data as? Data)!
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
