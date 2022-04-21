import SwiftUI

public extension StringProtocol {
    var text: Text { Text(self) }
}

public extension Sequence where Element == Text {
    func joined(separator: Text = Text("")) -> Text {
        var isInitial = true
        return reduce(Text("")) { result, text in
            if isInitial {
                isInitial = false
                return text
            }
            return result + separator + text
        }
    }
}

public extension Text {
    init(separator: Text = Text(""), @BasicTextBuilder content: () -> [Text]) {
        self = content().joined(separator: separator)
    }

    init<Separator: StringProtocol>(separator: Separator, @BasicTextBuilder content: () -> [Text]) {
        self.init(separator: Text(separator), content: content)
    }
}
