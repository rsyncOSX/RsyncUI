//
//  LogToFile.swift
//  rcloneosx
//
//  Created by Thomas Evensen on 20.11.2017.
//  Copyright © 2017 Thomas Evensen. All rights reserved.
//
// swiftlint:disable non_optional_string_data_conversion

import Foundation
import OSLog

enum FilesizeError: LocalizedError {
    case toobig

    var errorDescription: String? {
        switch self {
        case .toobig:
            "Big logfile\n Please reset file"
        }
    }
}

actor ActorLogToFile {

    @concurrent
    nonisolated func writeloggfile(_ newlogadata: String, _ reset: Bool) async {
        let path = await Homepath()
        if let fullpathmacserial = path.fullpathmacserial {
            let fullpathmacserialURL = URL(fileURLWithPath: fullpathmacserial)
            let logfileURL = fullpathmacserialURL.appendingPathComponent(SharedConstants().logname)

            Logger.process.info("LogToFile: write logfile to \(logfileURL.path, privacy: .public)")
            Logger.process.info("LogToFile: writeloggfile() MAIN THREAD: \(Thread.isMain) but on \(Thread.current)")

            if let logfiledata = await appendloggfileData(newlogadata, reset) {
                    do {
                        try logfiledata.write(to: logfileURL)
                        /*
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
                                await path.propogateerror(error: error)
                            }
                        }
                         */
                    } catch let e {
                        let error = e
                        await path.propogateerror(error: error)
                    }
            }
        }
    }

    @concurrent
    nonisolated func readloggfile() async -> [String]? {
        let path = await Homepath()
        let fm = FileManager.default
        if let fullpathmacserial = path.fullpathmacserial {
            let logfileString = fullpathmacserial.appending("/") + SharedConstants().logname
            guard fm.locationExists(at: logfileString, kind: .file) == true else { return nil }

            let fullpathmacserialURL = URL(fileURLWithPath: fullpathmacserial)
            let logfileURL = fullpathmacserialURL.appendingPathComponent(SharedConstants().logname)

            Logger.process.info("LogToFile: read logfile \(logfileURL.path, privacy: .public)")
            Logger.process.info("LogToFile: readloggfile() MAIN THREAD: \(Thread.isMain) but on \(Thread.current)")
            
            do {
                let data = try Data(contentsOf: logfileURL)
                let logfile = String(data: data, encoding: .utf8)
                return logfile.map { line in
                    line.components(separatedBy: .newlines)
                }
            } catch let e {
                let error = e
                await path.propogateerror(error: error)
            }
        }
         
         return nil
    }
    
    @concurrent
    nonisolated private func readloggfileasline() async -> String? {
        let path = await Homepath()
        let fm = FileManager.default
        if let fullpathmacserial = path.fullpathmacserial {
            let logfileString = fullpathmacserial.appending("/") + SharedConstants().logname
            guard fm.locationExists(at: logfileString, kind: .file) == true else { return nil }

            let fullpathmacserialURL = URL(fileURLWithPath: fullpathmacserial)
            let logfileURL = fullpathmacserialURL.appendingPathComponent(SharedConstants().logname)

            Logger.process.info("LogToFile: read logfile \(logfileURL.path, privacy: .public)")
            Logger.process.info("LogToFile: readloggfileasline() MAIN THREAD: \(Thread.isMain) but on \(Thread.current)")
            
            do {
                let data = try Data(contentsOf: logfileURL)
                return String(data: data, encoding: .utf8)
                
            } catch let e {
                let error = e
                await path.propogateerror(error: error)
            }
        }
         
         return nil
    }
    
    @concurrent
    nonisolated private func appendloggfileData(_ newlogadata: String, _ reset: Bool) async -> Data? {
       let path = await Homepath()
       let fm = FileManager.default
       if let fullpathmacserial = path.fullpathmacserial {
           let logfileString = fullpathmacserial.appending("/") + SharedConstants().logname
           guard fm.locationExists(at: logfileString, kind: .file) == true else { return nil }

           let fullpathmacserialURL = URL(fileURLWithPath: fullpathmacserial)
           let logfileURL = fullpathmacserialURL.appendingPathComponent(SharedConstants().logname)

           Logger.process.info("LogToFile: read logfile \(logfileURL.path, privacy: .public)")
           Logger.process.info("LogToFile: appendloggfileData() MAIN THREAD: \(Thread.isMain) but on \(Thread.current)")
                      
           if let newdata = newlogadata.data(using: .utf8) {
               do {
                   if reset {
                       // Only return reset string
                       return newdata
                   } else {
                       // Or append any new log data
                       let data = try Data(contentsOf: logfileURL)
                       var returneddata = data
                       returneddata.append(newdata)
                       return returneddata
                   }
               } catch let e {
                   let error = e
                   await path.propogateerror(error: error)
               }
           }
       }
        
        return nil
   }
    
    private func filesize(then handler: @escaping (Result<NSNumber, Error>) throws -> Void) async {
        let path = await Homepath()
        let fm = FileManager.default
        if let fullpathmacserial = path.fullpathmacserial {
            let logfileString = fullpathmacserial.appending("/") + SharedConstants().logname
            guard fm.locationExists(at: logfileString, kind: .file) == true else { return }

            let fullpathmacserialURL = URL(fileURLWithPath: fullpathmacserial)
            let logfileURL = fullpathmacserialURL.appendingPathComponent(SharedConstants().logname)

            do {
                // Return filesize
                if let filesize = try fm.attributesOfItem(atPath: logfileURL.path)[FileAttributeKey.size] as? NSNumber {
                    Logger.process.info("Filesize of logfile \(filesize, privacy: .public)")
                    try handler(.success(filesize))
                }
            } catch let e {
                let error = e
                await path.propogateerror(error: error)
            }
        }
    }

    

    private func minimumlogging(command: String, stringoutputfromrsync: [String]) async {
        
        let date = Date().localized_string_from_date()
        var tmplogg = [String]()

        var startindex = stringoutputfromrsync.count - 20
        if startindex < 0 { startindex = 0 }

        tmplogg.append("\n" + date)
        tmplogg.append(command)
       
        var count = 0
        let tmploggrsync = stringoutputfromrsync.compactMap { line in
            count += 1
            return startindex >= count ? nil : line
        }
        
        var logfile = await readloggfileasline()

        if logfile == nil {
            logfile = tmplogg.joined(separator: "\n") + tmploggrsync.joined(separator: "\n")
        } else {
            logfile! += tmplogg.joined(separator: "\n") + tmploggrsync.joined(separator: "\n")
        }
        if let logfile {
            await writeloggfile(logfile, false)
        }
        
    }

    @discardableResult
    init(_ reset: Bool) async {
        if reset {
            // Reset loggfile
            let date = Date().localized_string_from_date()
            let reset = date + ": " + "logfile is reset..." + "\n"
            await writeloggfile(reset, true)
        }
    }

    @discardableResult
    init(command: String, stringoutputfromrsync: [String]?) async {
        if let stringoutputfromrsync {
            await minimumlogging(command: command, stringoutputfromrsync: stringoutputfromrsync)
        }
    }
}

// swiftlint:enable non_optional_string_data_conversion
