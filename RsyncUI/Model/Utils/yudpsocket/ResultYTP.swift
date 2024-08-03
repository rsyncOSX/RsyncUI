import Foundation

public enum ResultYTP {
    case success
    case failure(Error)

    public var isSuccess: Bool {
        switch self {
        case .success:
            true
        case .failure:
            false
        }
    }

    public var isFailure: Bool {
        !isSuccess
    }

    public var error: Error? {
        switch self {
        case .success:
            nil
        case let .failure(error):
            error
        }
    }
}
