//
//  WidgetHomepath.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 10/01/2025.
//

import Foundation

public struct WidgetHomepath {
    // full path with macserialnumber
    var fullpathmacserial: String?
    // Documentscatalog
    var documentscatalog: String? {
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true) as NSArray
        return paths.firstObject as? String
    }
    // Path for userconfig
    let configpath: String = "/.rsyncosx/"

    // Mac serialnumber
    public var macserialnumber: String? {
        // Get the platform expert
        let platformExpert: io_service_t = IOServiceGetMatchingService(kIOMainPortDefault,
                                                                       IOServiceMatching("IOPlatformExpertDevice"))
        // Get the serial number as a CFString ( actually as Unmanaged<AnyObject>! )
        let serialNumberAsCFString = IORegistryEntryCreateCFProperty(platformExpert,
                                                                     kIOPlatformSerialNumberKey as CFString?,
                                                                     kCFAllocatorDefault, 0)
        // Release the platform expert (we're responsible)
        IOObjectRelease(platformExpert)
        // Take the unretained value of the unmanaged-any-object
        // (so we're not responsible for releasing it)
        // and pass it back as a String or, if it fails, an empty string
        // return (serialNumberAsCFString!.takeUnretainedValue() as? String) ?? ""
        return (serialNumberAsCFString?.takeRetainedValue() as? String) ?? "C00123456789"
    }

    public var userHomeDirectoryURLPath: URL? {
        let pw = getpwuid(getuid())
        if let home = pw?.pointee.pw_dir {
            let homePath = FileManager.default.string(withFileSystemRepresentation: home, length: Int(strlen(home)))
            return URL(fileURLWithPath: homePath)
        } else {
            return nil
        }
    }
    
    var userHomeDirectoryPath: String? {
        let pw = getpwuid(getuid())
        if let home = pw?.pointee.pw_dir {
            let homePath = FileManager.default.string(withFileSystemRepresentation: home, length: Int(strlen(home)))
            return homePath
        } else {
            return nil
        }
    }

    public init() {
        fullpathmacserial = (userHomeDirectoryPath ?? "") + configpath + (macserialnumber ?? "")
    }
}

