//
//  DebounceFilter.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 25/10/2023.
//

import Combine
import Foundation
import SwiftUI

@Observable
final class DebounceFilter {
    var subscriptons = Set<AnyCancellable>()
    var debouncefilter: String = ""
    // @ObservationIgnored
    var filter: String = ""

    init() {
        debounce()
    }

    func debounce() {
        filter.publisher
            .debounce(for: 2, scheduler: RunLoop.main)
            .sink { completion in
                switch completion {
                case .finished:
                    return
                case .failure:
                    return
                }
            } receiveValue: { [unowned self] data in
                print("new text value: \(data)")
                debouncefilter = data.description
            }
            .store(in: &subscriptons)
    }
}

/*
 struct ContentView: View {
     @State var viewModel = ViewModel()

     var body: some View {
         TextField("Search", text: $viewModel.text)
     }
 }
 */
