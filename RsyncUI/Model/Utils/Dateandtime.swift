//
//  Dateandtime.swift
//  RsyncOSX
//
//  Created by Thomas Evensen on 24.08.2018.
//  Copyright © 2018 Thomas Evensen. All rights reserved.
//

import Foundation

struct Dateandtime {
    // Calculation of time to a spesific date
    func timestring(seconds: Double) -> String {
        var result: String?
        let (hr, minf) = modf(seconds / 3600)
        let (min, secf) = modf(60 * minf)
        // hr, min, 60 * secf
        if hr == 0, min == 0 {
            if secf < 0.9 {
                result = String(format: "%.0f", 60 * secf) + "s"
            } else {
                result = String(format: "%.0f", 1.0) + "m"
            }
        } else if hr == 0, min < 60 {
            if secf < 0.9 {
                result = String(format: "%.0f", min) + "m"
            } else {
                result = String(format: "%.0f", min + 1) + "m"
            }
        } else if hr < 25 {
            result = String(format: "%.0f", hr) + NSLocalizedString("h", comment: "datetime") + " "
                + String(format: "%.0f", min) + "m"
        } else {
            result = String(format: "%.0f", hr / 24) + "d"
        }
        return result ?? ""
    }
}
