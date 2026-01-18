import Foundation

protocol UserDefaultsStoreableValue {
    static func fromDefaultsStoredValue(_ value: Any) -> Self?
    var defaultsStoreableValue: Any { get }
}

/// A custom user defaults key. Identifies the key and type of a stored value.
struct UserDefaultsKey<T: UserDefaultsStoreableValue> {
    /// Initialize a key.
    ///
    /// - Parameter key: The unique identifier for this key.
    public init(_ identifier: String, defaultValue: T, registerDefaultIn userDefaults: UserDefaults? = .standard, shouldRegister: Bool = true) {
        self.identifier = identifier
        self.defaultValue = defaultValue
        if shouldRegister { userDefaults?.register(defaults: [identifier: defaultValue.defaultsStoreableValue]) }
    }

    /// They key's default value, if any.
    public let defaultValue: T

    /// The key's unique identifier.
    public let identifier: String
}

extension UserDefaults {

    func value<T>(for key: UserDefaultsKey<T>) -> T {
        guard let storedValue = object(forKey: key.identifier) else { return key.defaultValue }
        return T.fromDefaultsStoredValue(storedValue) ?? key.defaultValue
    }

    func setValue<T>(_ value: T, for key: UserDefaultsKey<T>) {
        setValue(value.defaultsStoreableValue, forKey: key.identifier)
    }

    func removeValue<T>(for key: UserDefaultsKey<T>) {
        removeObject(forKey: key.identifier)
    }
}

extension String: UserDefaultsStoreableValue {
    static func fromDefaultsStoredValue(_ value: Any) -> String? { return value as? String }
    var defaultsStoreableValue: Any { return self }
}

extension Int: UserDefaultsStoreableValue {
    static func fromDefaultsStoredValue(_ value: Any) -> Int? { return value as? Int }
    var defaultsStoreableValue: Any { return self }
}

extension Data: UserDefaultsStoreableValue {
    static func fromDefaultsStoredValue(_ value: Any) -> Data? { return value as? Data }
    var defaultsStoreableValue: Any { return self }
}

extension Bool: UserDefaultsStoreableValue {
    static func fromDefaultsStoredValue(_ value: Any) -> Bool? {
        // When we provide user defaults to the app via runtime arguments, they come through as strings.
        // Special-case that here.
        if let boolString = value as? NSString { return boolString.boolValue }
        return value as? Bool
    }
    var defaultsStoreableValue: Any { return self }
}
