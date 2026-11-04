import Foundation
import Observation

@Observable @MainActor
final class AlertError {
    var activeError: Error?

    func alert(error: Error) {
        activeError = error
    }
}
