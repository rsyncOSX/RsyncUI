//
//  SchedulesConfigurations.swift
//  Calendar
//
//  Created by Thomas Evensen on 25/03/2025.
//

/*
 let currendate = Date()
 let date = currendate.en_us_string_from_date()
 */

import Foundation

enum ScheduleType: String, CaseIterable, Identifiable, CustomStringConvertible {
    case once
    case daily
    case weekly
    case stopped

    var id: String { rawValue }
    var description: String { rawValue.localizedCapitalized }
}

struct SchedulesConfigurations: Identifiable, Codable {
    var id = UUID()
    var profile: String?
    var dateAdded: String?
    var dateRun: String?
    var dateStop: String?
    var schedule: String?

    init(_ data: DecodeSchedules) {
        dateRun = data.dateRun
        dateAdded = data.dateAdded
        dateStop = data.dateStop
        schedule = data.schedule
        profile = data.profile
    }

    init(profile: String?, dateAdded: String?, dateRun: String?, dateStop: String?, schedule: String?) {
        self.profile = profile
        self.dateAdded = dateAdded
        self.dateRun = dateRun
        self.dateStop = dateStop
        self.schedule = schedule
    }
}

extension SchedulesConfigurations: Hashable, Equatable {
    static func == (lhs: SchedulesConfigurations, rhs: SchedulesConfigurations) -> Bool {
        lhs.id == rhs.id &&
            lhs.profile == rhs.profile &&
            lhs.dateAdded == rhs.dateAdded &&
            lhs.dateRun == rhs.dateRun &&
            lhs.dateStop == rhs.dateStop &&
            lhs.schedule == rhs.schedule
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(profile)
        hasher.combine(dateRun)
        hasher.combine(dateAdded)
        hasher.combine(id)
        hasher.combine(schedule)
    }
}

struct DecodeSchedules: Codable {
    let dateRun: String?
    let dateAdded: String?
    let dateStop: String?
    let schedule: String?
    let profile: String?

    enum CodingKeys: String, CodingKey {
        case dateRun
        case dateAdded
        case dateStop
        case schedule
        case profile
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        dateRun = try values.decodeIfPresent(String.self, forKey: .dateRun)
        dateAdded = try values.decodeIfPresent(String.self, forKey: .dateAdded)
        dateStop = try values.decodeIfPresent(String.self, forKey: .dateStop)
        schedule = try values.decodeIfPresent(String.self, forKey: .schedule)
        profile = try values.decodeIfPresent(String.self, forKey: .profile)
    }
}
