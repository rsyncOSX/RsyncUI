//
//  XPCProtocol.swift
//  XPC
//
//  Created by Thomas Evensen on 12/01/2025.
//

import Foundation

/// The protocol that this service will vend as its API. This protocol will also need to be visible to the process hosting the service.
@objc protocol XPCProtocol {
    /// Replace the API of this protocol with an API appropriate to the service you are vending.
    func performCalculation(firstNumber: Int, secondNumber: Int, with reply: @escaping (Int) -> Void)
}
