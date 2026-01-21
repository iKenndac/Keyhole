import Foundation
import SwiftUI

extension View {
    /// Applies the given transform if the given condition evaluates to `true`.
    /// - Parameters:
    ///   - condition: The condition to evaluate.
    ///   - transform: The transform to apply to the source `View`.
    /// - Returns: Either the original `View` or the modified `View` if the condition is `true`.
    @ViewBuilder func onCondition<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }

    /// Applies the given transform if the given optional isn't `nil`.
    /// - Parameters:
    ///   - value: The value to unwrap.
    ///   - transform: The transform to apply to the source `View` if the value can be unwrapped.
    @ViewBuilder func onUnwrap<Content: View, T>(_ value: T?, transform: (Self, T) -> Content) -> some View {
        if let value {
            transform(self, value)
        } else {
            self
        }
    }
}

// MARK: ScrollView

 extension ScrollView {
     @ViewBuilder func withSizedBasedBounceBehaviorIfAvailable() -> some View {
         if #available(iOS 16.4, macCatalyst 16.4, macOS 13.3, tvOS 16.4, watchOS 9.4, *) {
             self.scrollBounceBehavior(.basedOnSize)
         } else {
             self
         }
     }
 }

