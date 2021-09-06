import Foundation

public protocol TextBuilderSeparator {
    associatedtype Separator: StringProtocol
    static var separator: Separator { get }
}

public struct EmptySeparator: TextBuilderSeparator {
    public static var separator: String { "" }
}

public struct WhitespaceSeparator: TextBuilderSeparator {
    public static var separator: String { " " }
}

public struct NewlineSeparator: TextBuilderSeparator {
    public static var separator: String { "\n" }
}

public typealias BasicTextBuilder = TextBuilder<EmptySeparator>
public typealias SpacedTextBuilder = TextBuilder<WhitespaceSeparator>
public typealias MultilineTextBuilder = TextBuilder<NewlineSeparator>
