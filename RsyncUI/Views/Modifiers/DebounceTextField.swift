//
//  DebounceTextField.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 25/10/2023.
//

import Combine
import SwiftUI

struct DebounceTextField: View {
    @State var publisher = PassthroughSubject<String, Never>()
    @State var label: String
    @Binding var value: String
    var valueChanged: ((_ value: String) -> Void)?

    @State var debounceSeconds = 1.0

    var body: some View {
        TextField(label, text: $value, axis: .vertical)
            .disableAutocorrection(true)
            .onChange(of: value) {
                publisher.send(value)
            }
            .onReceive(
                publisher.debounce(
                    for: .seconds(debounceSeconds),
                    scheduler: DispatchQueue.main
                )
            ) { value in
                if let valueChanged = valueChanged {
                    valueChanged(value)
                }
            }
    }
}
