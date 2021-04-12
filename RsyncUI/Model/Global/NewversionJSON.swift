//
//  NewversionJSON.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 12/04/2021.
//

import Combine
import Foundation

struct Resource<T: Codable> {
    let request: URLRequest
}

struct Versionrsyncui: Codable {
    let url: String?
    let version: String?

    enum CodingKeys: String, CodingKey {
        case url
        case version
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        url = try values.decodeIfPresent(String.self, forKey: .url)
        version = try values.decodeIfPresent(String.self, forKey: .version)
    }
}

final class NewversionJSON: ObservableObject {
    @Published var notifynewversion: Bool = false
    var subscriber: AnyCancellable?

    init() {
        if let baseURL = URL(string: Resources().getResource(resource: .urlJSON)) {
            let request = URLRequest(url: baseURL)
            let resource = Resource<Versionrsyncui>(request: request)
            subscriber?.cancel()
            subscriber = URLSession.shared.fetchJSON(for: resource)
                .receive(on: DispatchQueue.main)
                .sink(receiveCompletion: { completion in
                    switch completion {
                    case .finished:
                        print("The publisher finished normally.")
                    case let .failure(error):
                        print("An error occured: \(error).")
                    }
                }, receiveValue: { [unowned self] result in
                    verifynewversion(result)
                })
        }
    }
}

extension NewversionJSON {
    func verifynewversion(_ result: Versionrsyncui) {
        print(result)
    }
}

extension URLSession {
    func fetchJSON<T: Codable>(for resource: Resource<T>) -> AnyPublisher<T, Error> {
        return dataTaskPublisher(for: resource.request)
            .map { $0.data }
            .decode(type: T.self, decoder: JSONDecoder())
            .eraseToAnyPublisher()
    }
}
