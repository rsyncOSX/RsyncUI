//
//  Macserialnumber.swift
//  RsyncOSX
//
//  Created by Thomas Evensen on 24.08.2018.
//  Copyright © 2018 Thomas Evensen. All rights reserved.
//

import Foundation

final class Macserialnumber {
    private var macSerialNumber: String?

    // Function for computing MacSerialNumber
    func computemacSerialNumber() -> String {
        // Get the platform expert
        let platformExpert: io_service_t = IOServiceGetMatchingService(kIOMasterPortDefault,
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

    // Function for returning the MacSerialNumber
    func getMacSerialNumber() -> String? {
        guard macSerialNumber != nil else {
            // Compute it, set it and return
            macSerialNumber = computemacSerialNumber()
            return macSerialNumber!
        }
        return macSerialNumber
    }
}
