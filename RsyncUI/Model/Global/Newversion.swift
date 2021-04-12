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

final class Newversion: ObservableObject {
    @Published var urlNewVersion: String?

    private var runningVersion: String?
    private var urlstring: String = ""
    private var url: URL?
    private var getdata: Cancellable?

    func fetch(url: URL) -> AnyPublisher<Data, APIError> {
        let request = URLRequest(url: url)

        return URLSession.DataTaskPublisher(request: request, session: .shared)
            .tryMap { data, response in
                guard let httpResponse = response as? HTTPURLResponse, 200 ..< 300 ~= httpResponse.statusCode else {
                    throw APIError.unknown
                }
                return data
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

    init() {
        runningVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
        urlstring = Resources().getResource(resource: .urlPlist)
        if let url = URL(string: urlstring) {
            getdata = fetch(url: url)
                .sink(receiveCompletion: { completion in
                    switch completion {
                    case .finished:
                        break
                    case let .failure(error):
                        print(error.localizedDescription)
                    }
                }, receiveValue: { data in
                    guard let response = String(data: data, encoding: .utf8) else { return }
                    print(response)
                })
        }
    }
}

/*
 // If new version set URL for download link and notify caller
 private func urlnewVersion() {
     globalBackgroundQueue.async { () -> Void in
         if let url = URL(string: self.urlPlist ?? "") {
             do {
                 let contents = NSDictionary(contentsOf: url)
                 if let url = contents?.object(forKey: self.runningVersion ?? "") {
                     self.urlNewVersion = url as? String
                 }
             }
         }
     }
 }
 */
