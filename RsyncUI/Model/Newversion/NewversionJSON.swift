//
//  NewversionJSON.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 12/04/2021.
//

import Combine
import Foundation

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

struct Resource<T: Codable> {
    let request: URLRequest
}

final class NewversionJSON: ObservableObject {
    @Published var notifynewversion: Bool = false
    private var subscriber: AnyCancellable?
    private var runningversion: String?

    func verifynewversion(_ result: [Versionrsyncui]?) {
        if let result = result {
            if let runningversion = runningversion {
                let check = result.filter { runningversion.isEmpty ? true : $0.version == runningversion }
                if check.count > 0 {
                    notifynewversion = true
                    SharedReference.shared.URLnewVersion = check[0].url
                }
            }
        }
        subscriber?.cancel()
    }

    init() {
        runningversion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
        if let baseURL = URL(string: Resources().getResource(resource: .urlJSON)) {
            let request = URLRequest(url: baseURL)
            let resource = Resource<[Versionrsyncui]>(request: request)
            subscriber?.cancel()
            subscriber = URLSession.shared.fetchJSON(for: resource)
                .receive(on: DispatchQueue.main)
                .sink(receiveCompletion: { completion in
                    switch completion {
                    case .finished:
                        // print("The publisher finished normally.")
                        return
                    case let .failure(error):
                        self.propogateerror(error: error)
                    }
                }, receiveValue: { [unowned self] result in
                    verifynewversion(result)
                })
        }
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

extension NewversionJSON {
    func propogateerror(error: Error) {
        SharedReference.shared.errorobject?.propogateerror(error: error)
    }
}
