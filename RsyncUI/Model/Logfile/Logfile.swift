//
//  Logging.swift
//  rcloneosx
//
//  Created by Thomas Evensen on 20.11.2017.
//  Copyright © 2017 Thomas Evensen. All rights reserved.
//
// swiftlint:disable line_length

import Files
import Foundation

enum Result<Value, Error: Swift.Error> {
    case success(Value)
    case failure(Error)
}

// typealias HandlerRsyncOSX = (Result<Data, RsyncOSXTypeErrors>) -> Void
// typealias Handler = (Result<Data, Error>) -> Void
typealias HandlerNSNumber = (Result<NSNumber, Error>) throws -> Void

extension Result {
    func get() throws -> Value {
        switch self {
        case let .success(value):
            return value
        case let .failure(error):
            throw error
        }
    }
}

enum FilesizeError: LocalizedError {
    case toobig

    var errorDescription: String? {
        switch self {
        case .toobig:
            return "Too big logfile"
        }
    }
}

final class Logfile: NamesandPaths {
    private var logfile: String?
    private var preparedlogview = [String]()

    func getlogfile() -> [String] {
        return preparedlogview
    }

    func writeloggfile() {
        if let atpath = fullpathmacserial {
            do {
                let folder = try Folder(path: atpath)
                let file = try folder.createFile(named: SharedReference.shared.logname)
                if let data = logfile {
                    try file.write(data)
                    filesize { [weak self] result in
                        switch result {
                        case let .success(size):
                            if Int(truncating: size) > SharedReference.shared.logfilesize {
                                let size = Int(truncating: size)
                                if size > SharedReference.shared.logfilesize {
                                    throw FilesizeError.toobig
                                }
                            }
                            return
                        case let .failure(error):
                            self?.propogateerror(error: error)
                        }
                    }
                }
            } catch let e {
                let error = e
                propogateerror(error: error)
            }
        }
    }

    //  typealias HandlerNSNumber = (Result<NSNumber, Error>) -> Void
    func filesize(then handler: @escaping HandlerNSNumber) {
        if var atpath = fullpathmacserial {
            do {
                // check if file exists befor reading, if not bail out
                let fileexists = try Folder(path: atpath).containsFile(named: SharedReference.shared.logname)
                atpath += "/" + SharedReference.shared.logname
                if fileexists {
                    do {
                        // Return filesize
                        let file = try File(path: atpath).url
                        if let filesize = try FileManager.default.attributesOfItem(atPath: file.path)[FileAttributeKey.size] as? NSNumber {
                            try handler(.success(filesize))
                        }
                    } catch {
                        try handler(.failure(error))
                    }
                }
            } catch {
                // try handler(.failure(error))
            }
        }
    }

    func readloggfile() {
        if var atpath = fullpathmacserial {
            do {
                // check if file exists ahead of reading, if not bail out
                guard try Folder(path: atpath).containsFile(named: SharedReference.shared.logname) else { return }
                atpath += "/" + SharedReference.shared.logname
                let file = try File(path: atpath)
                logfile = try file.readAsString()
            } catch let e {
                let error = e
                propogateerror(error: error)
            }
        }
    }

    private func minimumlogging(_ data: [String]) {
        let date = Date().localized_string_from_date()
        readloggfile()
        var tmplogg = [String]()
        var startindex = data.count - 8
        if startindex < 0 { startindex = 0 }
        tmplogg.append("\n" + date + "\n")
        for i in startindex ..< data.count {
            tmplogg.append(data[i])
        }
        if logfile == nil {
            logfile = tmplogg.joined(separator: "\n")
        } else {
            logfile! += tmplogg.joined(separator: "\n")
        }
        writeloggfile()
    }

    private func fulllogging(_ data: [String]) {
        let date = Date().localized_string_from_date()
        readloggfile()
        let tmplogg = "\n" + date + "\n"
        if logfile == nil {
            logfile = tmplogg + data.joined(separator: "\n")
        } else {
            logfile! += tmplogg + data.joined(separator: "\n")
        }
        writeloggfile()
    }

    private func preparelogfile() {
        if let data = logfile?.components(separatedBy: .newlines) {
            for i in 0 ..< data.count {
                preparedlogview.append(data[i])
            }
        }
    }

    init(_ reset: Bool) {
        super.init(.configurations)
        if reset {
            // Reset loggfile
            let date = Date().localized_string_from_date()
            logfile = date + ": " + "new logfile is created...\n"
            writeloggfile()
        } else {
            // Read the logfile
            readloggfile()
            preparelogfile()
        }
    }

    init(_ data: [String]?, error: Bool) {
        super.init(.configurations)
        if error {
            if let data = data {
                fulllogging(data)
            }
        } else {
            guard SharedReference.shared.fulllogging == true ||
                SharedReference.shared.minimumlogging == true
            else {
                return
            }
            if SharedReference.shared.fulllogging {
                fulllogging(data ?? [])
            } else {
                minimumlogging(data ?? [])
            }
        }
    }
}
