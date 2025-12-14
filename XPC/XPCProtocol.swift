//
//  XPCProtocol.swift
//  XPC
//
//  Created by Thomas Evensen on 12/01/2025.
//

import Foundation

@objc protocol XPCProtocol {
    /// Replace the API of this protocol with an API appropriate to the service you are vending.
    func performCalculation(firstNumber: Int, secondNumber: Int, with reply: @escaping (Int) -> Void)
}
