import SwiftUI

@resultBuilder
public struct TextBuilder<Separator: TextBuilderSeparator> {
    public static func buildArray(_ texts: [[Text]]) -> [Text] {
        texts.flatMap { $0 }
    }

    public static func buildBlock(_ texts: [Text]...) -> [Text] {
        texts.flatMap { $0 }
    }

    public static func buildEither(first texts: [Text]) -> [Text] {
        texts
    }

    public static func buildEither(second texts: [Text]) -> [Text] {
        texts
    }

    public static func buildExpression(_ string: String) -> [Text] {
        [Text(string)]
    }

    public static func buildExpression(_ text: Text) -> [Text] {
        [text]
    }

    public static func buildLimitedAvailability(_ texts: [Text]) -> [Text] {
        texts
    }

    public static func buildOptional(_ texts: [Text]?) -> [Text] {
        texts ?? []
    }

    public static func buildFinalResult(_ texts: [Text]) -> Text {
        texts.joined(separator: Text(Separator.separator))
    }

    public static func buildFinalResult(_ texts: [Text]) -> [Text] {
        texts
    }
}
