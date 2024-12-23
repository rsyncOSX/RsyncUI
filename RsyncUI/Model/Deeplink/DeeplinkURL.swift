//
//  DeeplinkURL.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 23/12/2024.
//

import Foundation
import OSLog

enum Deeplinknavigation {
    case quicktask
    case invalidurl
    case invalidscheme
}

struct DeeplinkURL {
    private func validateScheme(_ scheme: String) -> Bool {
        guard scheme == "rsyncuiapp" else { return false }
        return true
    }
    
    func handleURL(_ url: URL) -> Deeplinknavigation {
        
        Logger.process.info("App was opened via URL: \(url)")
        
        guard (url.scheme != nil) else { return .invalidurl }
        if let scheme = url.scheme {
            guard validateScheme(scheme) else { return .invalidscheme }
            guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true) else {
                Logger.process.warning("Invalid URL")
                return .invalidurl
            }

            print(components)
            return .quicktask
        }
        return .invalidurl
    }
}

enum DeeplinkQueryDataKey: String {
    case type
}

struct DeeplinkParsedData {
    let navigationType: DeeplinkNavigationType
    let queryData: [DeeplinkQueryDataKey: Any]
}


final class DeeplinkDefaultDataParser {
    private func validateScheme(_ scheme: String) -> Bool {
        // Validate the scheme here
        return true
    }
    
    func parseDeeplink(_ urlString: String) -> DeeplinkParsedData? {
        // Consider an example deeplink URL as "sample-app://sampleapp?type=homeScreen&data=1234"
        // After parsing the navigation type will be "homeScreen" in the DeeplinkParsedData object.
        // Rest of the URL params will be part of query data in the DeeplinkParsedData.
        guard let url = URL(string: urlString),
              let scheme = url.scheme,
              validateScheme(scheme) else {
            return nil
        }
        
        // Parse the URL components to extract query parameters
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        
        // Create a dictionary to store the query data
        var queryData = [DeeplinkQueryDataKey: Any]()
        if let queryItems = components?.queryItems {
            // Iterate through the query items and store them in the dictionary
            queryItems.forEach({
                if let value = $0.value,
                   let queryDataKey = DeeplinkQueryDataKey(rawValue: $0.name) {
                    queryData[queryDataKey] = value
                }
            })
        }
        
        // Extract the deeplink navigation type from the query data
        if let navigationTypeValue = queryData[DeeplinkQueryDataKey.type] as? String,
           let navigationType = DeeplinkNavigationType(rawValue: navigationTypeValue) {
            return DeeplinkParsedData(navigationType: navigationType, queryData: queryData)
        }
        
        return nil
    }
}

enum DeeplinkNavigationType: String {
    case homeScreen
    case transactionScreen
}

/*
enum ViewModelDeeplinkState {
    case pending
    case inProgress
    case completed
    case notActive
}

typealias DeeplinkDataCompletionHandler = () -> ()

protocol ViewModelDeeplinkHandlerProtocol: AnyObject {
    var deeplinkState: Observable<ViewModelDeeplinkState> { get }
    var supportedDeeplinkTypes: [DeeplinkNavigationType] { get }
    var finalDeeplinkTypes: [DeeplinkNavigationType] { get }
    func handleDeeplink(with data: DeeplinkParsedData, completionHandler: DeeplinkDataCompletionHandler?)
}

extension ViewModelDeeplinkHandlerProtocol {
     func getActiveDeeplinkData() -> DeeplinkParsedData? {
        return DeeplinkDataManager.shared.getDeeplinkData()
    }
    
    func handleAnyActiveDeeplink() {
        // Set the initial deeplink state to 'notActive'
        deeplinkState.value = .notActive
        
        // Get the active deeplink data from the DeeplinkDataManager
        guard let deeplinkData = getActiveDeeplinkData(),
              // Check if the supportedDeeplinkTypes contains the current deeplink's navigation type
              supportedDeeplinkTypes.contains(deeplinkData.navigationType) else {
            return
        }
        
        // If the current deeplink's navigation type is one of the finalDeeplinkTypes, remove it from the DeeplinkDataManager
        if finalDeeplinkTypes.contains(deeplinkData.navigationType) {
            DeeplinkDataManager.shared.removeDeeplinkData()
        }
        
        // Set the deeplink state to 'inProgress'
        deeplinkState.value = .inProgress
        
        // Call the handleDeeplink which will be implemented in the respective View Models.
        handleDeeplink(with: deeplinkData) { [weak self] in
            // Once the handling is complete, update the deeplink state to 'completed'
            guard let self else {
                // Ensure self is not deallocated before updating the deeplink state
                return
            }
            self.deeplinkState.value = .completed
        }
    }
}

final class DeeplinkDataManager {
    static let shared = DeeplinkDataManager()
    private var activeDeeplinkData: DeeplinkParsedData?
    
    private init() {}
    
    func getDeeplinkData() -> DeeplinkParsedData? {
        return activeDeeplinkData
    }
    
    func setDeeplinkData(_ data: DeeplinkParsedData) {
        activeDeeplinkData = data
    }
    
    func removeDeeplinkData() {
        activeDeeplinkData = nil
    }
}
*/
