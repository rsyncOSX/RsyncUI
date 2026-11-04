import SwiftUI

struct LogRecordsFooterView: View {
    let logsCount: Int
    let selectedUuidsIsEmpty: Bool
    let filterString: String
    let showInDebounce: Bool

    var body: some View {
        HStack {
            if showInDebounce {
                ProgressView()
                    .controlSize(.small)
            } else {
                footerText

                if filterString.isEmpty == false {
                    Label(String(localized: "Filtered by: \(filterString)"), systemImage: "magnifyingglass")
                }
            }

            Spacer()
        }
        .padding()
    }

    private var footerText: Text {
        if selectedUuidsIsEmpty {
            let logText = logsCount == 1 ?
                String(localized: "All log records — select a task to filter: 1 record") :
                String(localized: "All log records — select a task to filter: \(logsCount) records")
            return Text(logText)
        } else {
            let logText = logsCount == 1 ?
                String(localized: "Log records for selected task: 1 record") :
                String(localized: "Log records for selected task: \(logsCount) records")
            return Text(logText)
        }
    }
}
