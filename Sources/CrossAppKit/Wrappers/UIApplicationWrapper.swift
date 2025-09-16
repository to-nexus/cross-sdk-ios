import Foundation
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

struct UIApplicationWrapper {
    let openURL: (URL, _ completionHandler: ((Bool) -> Void)?) -> Void
    let canOpenURL: (URL) -> Bool
}

extension UIApplicationWrapper {
    static let live = Self(
        openURL: { url, completion in
            UIApplication.shared.open(url, completionHandler: completion)
        },
        canOpenURL: { url in
            UIApplication.shared.canOpenURL(url)
        }
    )
}
