import Foundation
import SwiftUI

struct AboutView: View {

    var versionString: LocalizedStringResource {
        let bundleInfo: [String: Any] = Bundle.main.infoDictionary ?? [:]
        return .aboutWindowVersionFormatter(version: bundleInfo["CFBundleShortVersionString"] as? String ?? "?",
                                            build: bundleInfo[kCFBundleVersionKey as String] as? String ?? "?")
    }

    var copyrightString: String {
        let bundleInfo: [String: Any] = Bundle.main.infoDictionary ?? [:]
        return bundleInfo["NSHumanReadableCopyright"] as? String ?? "?"
    }

    var body: some View {
        VStack(spacing: 14.0) {
            VStack(spacing: 0.0) {
                Image(.keyholeIcon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 128.0)
                    .fixedSize(horizontal: true, vertical: true)
                Text(.appName)
                    .font(.title)
                    .bold()
            }
            .allowsHitTesting(false)
            VStack(spacing: 4.0) {
                Text(versionString)
                Text(verbatim: copyrightString)
            }
            .font(.callout)
            .allowsHitTesting(false)
            Link(.aboutWindowTitle, destination: URL(string: "https://ikennd.ac/keyhole/")!)
        }
        .padding(.horizontal, 30.0)
        .padding(.bottom, 30.0)
        .frame(width: 300.0)
    }
}
