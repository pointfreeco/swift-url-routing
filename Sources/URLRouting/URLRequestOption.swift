import Foundation

/// A protocol used to attach custom options to a request.
public protocol URLRequestOption {
    associatedtype Value

    static var defaultValue: Value { get }
}

public struct URLRequestOptions {
    public var values = [ObjectIdentifier: Any]()

    public init(_ values: [ObjectIdentifier: Any]) {
        self.values = values
    }

    public init<Option>(_ option: Option) {
        self.values = [ObjectIdentifier(Option.self): option]
    }

    @usableFromInline
    init(_ options: [URLRequestOptions]) {
        values = options.reduce(into: [:]) { partialResult, option in
            partialResult.merge(option.values, uniquingKeysWith: { $1 })
        }
    }

    public subscript<Option: URLRequestOption>(option type: Option.Type) -> Option.Value {
        get {
            let key = ObjectIdentifier(type)
            guard let value = values[key] else {
                return type.defaultValue
            }
            guard let value = value as? Option.Value else {
                return type.defaultValue
            }
            return value
        }
        set {
            let key = ObjectIdentifier(type)
            values[key] = newValue
        }
    }
}

extension URLRequestOptions: Equatable {
    public static func ==(lhs: Self, rhs: Self) -> Bool {
        lhs.values.keys == rhs.values.keys
    }
}

@resultBuilder
public enum OptionsBuilder {
    public static func buildBlock(_ components: URLRequestOptions...) -> URLRequestOptions {
        URLRequestOptions(components)
    }
    public static func buildBlock<O1: URLRequestOption>(_ option1: O1) -> URLRequestOptions {
        URLRequestOptions(option1)
    }
    public static func buildBlock<O1: URLRequestOption, O2: URLRequestOption>(_ option1: O1, _ option2: O2) -> URLRequestOptions {
        URLRequestOptions([URLRequestOptions(option1), URLRequestOptions(option2)])
    }
    public static func buildBlock<O1: URLRequestOption, O2: URLRequestOption, O3: URLRequestOption>(_ option1: O1, _ option2: O2, _ option3: O3) -> URLRequestOptions {
        URLRequestOptions([URLRequestOptions(option1), URLRequestOptions(option2), URLRequestOptions(option3)])
    }
}

/// Parses a request's options
///
/// Useful for adding custom configuration options to a request
///
/// For example,
///
public struct Options: ParserPrinter {

    public let options: URLRequestOptions

    @inlinable
    public init(@OptionsBuilder build: () -> URLRequestOptions) {
        options = .init(build().values)
    }

    @inlinable
    public func parse(_ input: inout URLRequestData) {
        // These are client side options only
    }

    @inlinable
    public func print(_ output: (), into input: inout URLRequestData) {
        input.options = options
    }
}

