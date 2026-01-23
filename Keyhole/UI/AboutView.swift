import Foundation
import SwiftUI

struct AboutView: View {

    private var versionString: LocalizedStringResource {
        let bundleInfo: [String: Any] = Bundle.main.infoDictionary ?? [:]
        return .aboutWindowVersionFormatter(version: bundleInfo["CFBundleShortVersionString"] as? String ?? "?",
                                            build: bundleInfo[kCFBundleVersionKey as String] as? String ?? "?",
                                            verbose: bundleInfo["KeyholeVerboseVersion"] as? String ?? "?")
    }

    private var copyrightString: String {
        let bundleInfo: [String: Any] = Bundle.main.infoDictionary ?? [:]
        return bundleInfo["NSHumanReadableCopyright"] as? String ?? "?"
    }

    @State private var showingOSSLicenses: Bool = false

    var body: some View {
        VStack(spacing: 14.0) {
            VStack(spacing: 6.0) {
                Image(.keyholeIcon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 96.0)
                    .fixedSize(horizontal: true, vertical: true)
                    .shadow(color: .black.opacity(0.4), radius: 1.0, x: 0.5, y: 0.5)
                Text(.appName)
                    .font(.title)
                    .bold()
                VStack(spacing: 4.0) {
                    Text(versionString)
                    Text(verbatim: copyrightString)
                }
                .font(.callout)
            }
            .allowsHitTesting(false)
            Link(.aboutWindowWebsiteButtonTitle, destination: URL(string: "https://ikennd.ac/keyhole/")!)
            HStack(spacing: 4.0) {
                Text(.aboutIconByPrefix)
                Link(.aboutIconLinkTitle, destination: URL(string: "https://matthewskiles.com")!)
            }
            Button(.openSourceLicensesButtonTitle, action: { showingOSSLicenses = true })
                .controlSize(.small)
                .padding(.top, 4.0)
        }
        .sheet(isPresented: $showingOSSLicenses, content: { LicensesView() })
        .padding(.horizontal, 30.0)
        .padding(.top, 10.0)
        .padding(.bottom, 30.0)
        .frame(width: 300.0)
    }
}

struct LicensesView: View {

    @Environment(\.dismiss) var dismiss

    var ossLicenses: String {
        guard let url = Bundle.main.url(forResource: "OSSLicenses", withExtension: "txt"),
              let data = try? Data(contentsOf: url) else { return "" }
        return String(decoding: data, as: UTF8.self)
    }

    var body: some View {
        VStack(spacing: 12.0) {
            Text(.openSourceLicensesHeader)
                .bold()
            ScrollView {
                Text(verbatim: ossLicenses)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal)
                    .font(.system(size: 11.0, weight: .regular, design: .monospaced))
            }
            Button(.dismissButtonTitle, action: { dismiss() })
                .keyboardShortcut(.cancelAction)
        }
        .padding(.vertical)
        .frame(width: 600.0, height: 400.0)
    }
}
