import SwiftUI

#if canImport(UIKit)
import UIKit
extension View {
    @ViewBuilder
    func dismissKeyboardOnInteract() -> some View {
        if #available(iOS 16.0, *) {
            self
                .scrollDismissesKeyboard(.interactively)
                .simultaneousGesture(DragGesture(minimumDistance: 1).onChanged { _ in
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                })
                .onTapGesture {
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }
        } else {
            self
                .simultaneousGesture(DragGesture(minimumDistance: 1).onChanged { _ in
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                })
                .onTapGesture {
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }
        }
    }
}
#else
extension View {
    @ViewBuilder
    func dismissKeyboardOnInteract() -> some View { self }
}
#endif


