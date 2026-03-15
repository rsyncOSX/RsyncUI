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
                    Label("Filtered by: \(filterString)", systemImage: "magnifyingglass")
                }
            }

            Spacer()
        }
        .padding()
    }

    private var footerText: Text {
        if selectedUuidsIsEmpty {
            let logText = logsCount == 1 ?
                "ALL logrecords, select task for logrecords by task: 1 log" :
                "ALL logrecords, select task for logrecords by task: \(logsCount) logs"
            return Text(logText)
        } else {
            let logText = logsCount == 1 ?
                "Logrecords by selected task: 1 log" :
                "Logrecords by selected task: \(logsCount) logs"
            return Text(logText)
        }
    }
}
