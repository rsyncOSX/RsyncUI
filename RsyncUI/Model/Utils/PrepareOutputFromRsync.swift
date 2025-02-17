//
//  PrepareOutputFromRsync.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 17/02/2025.
//

struct PrepareOutputFromRsync {
    func prepareOutputFromRsync(_ stringoutputfromrsync: [String]?) -> [String] {
        // Trim output, remove all catalogs - keep files only in output
        // And then only keep the lst 20 lines, it is there the accumulated numbers are
        let trimmeddata = stringoutputfromrsync?.compactMap({ line in
            return ((line.last != "/")) ? line : nil
        })
        var resultarrayrsyncoutput: [String]?
        let count = trimmeddata?.count
        // Delete most of lines and keep only the last 20 lines of array, that is where the summarized data stay.
        if (count ?? 0) >= 20 {
            let firstindex = (count ?? 0) - 20
            let lastindex = (count ?? 0)
            resultarrayrsyncoutput = Array(trimmeddata?[firstindex ..< lastindex] ?? [])
        } else {
            resultarrayrsyncoutput = trimmeddata
        }
        return resultarrayrsyncoutput ?? []
    }
}
