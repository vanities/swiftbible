//
//  SettingsView.swift
//  swiftbible
//
//  Created by Adam Mischke on 9/4/24.
//

import SwiftUI


struct SettingsView: View {
    @Environment(UserViewModel.self) private var userViewModel
    @AppStorage("showJesusWordsInRed") var showJesusWordsInRed = true
    @AppStorage("hideNavAndTab") var hideNavAndTab = false

    @Binding var selectedTab: Tabs

    var body: some View {
        @Bindable var userViewModel = userViewModel

        NavigationStack {
            List {
                Section(header: Text("Appearance")) {
                    NavigationLink(destination: FontOptionsView()) {
                        Label("Font Options", systemImage: "textformat.size")
                    }
                    NavigationLink(destination: ColorOptionsView()) {
                        Label("Color Options", systemImage: "paintpalette.fill")
                    }
                    Toggle("Show Jesus's Words in Red", isOn: $showJesusWordsInRed)
                    Toggle("Hide Navigation and Tab Bar while reading", isOn: $hideNavAndTab)
                }

                Section(header: Text("App")) {
                    NavigationLink(destination: SeeSavedNotesView(selectedTab: $selectedTab)) {
                        Label("See Saved Notes", systemImage: "note.text")
                    }
                    NavigationLink(destination: SeeHighlightsView(selectedTab: $selectedTab)) {
                        Label("See Highlights", systemImage: "highlighter")
                    }
                }

                Section(header: Text("About")) {
                    Button(action: {
                        openMail(subject: "swiftbible - Contact Us")
                    }) {
                        Label("Contact Us", systemImage: "envelope")
                    }

                    Button(action: {
                        openMail(subject: "swiftbible - Bug")
                    }) {
                        Label("Report a Bug", systemImage: "ladybug")
                    }

                    Button(action: {
                        if let url = URL(string: "https://github.com/vanities/swiftbible") {
                            UIApplication.shared.open(url)
                        }
                    }) {
                        Label("Check out the code on GitHub", systemImage: "link")
                    }

                    Button(action: {
                        guard let url = URL(string: "itms-apps://itunes.apple.com/app/6670373108") else { return }
                         UIApplication.shared.open(url)
                    }) {
                        Label("View on App Store", systemImage: "apple.logo")
                    }

                    Button(action: {
                        if let url = URL(string: "https://am2.biz/swiftbible") {
                            UIApplication.shared.open(url)
                        }
                    }) {
                        Label("View our Website", systemImage: "globe")
                    }
                }

                Section {
                    HStack {
                        Spacer()
                        Text("Version \(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "")")
                            .font(.footnote)
                            .foregroundColor(.gray)
                        Spacer()
                    }
                }

            }
            .navigationBarTitle("Settings")
            .navigationDestination(isPresented: $userViewModel.showSignInFlow) {
                AuthenticateView()
            }
            .accessibilityIdentifier("SettingsView")
        }
    }

    func openMail(
        _ emailTo: String="mischke@proton.me",
        subject: String = ""
    ) {
        if let url = URL(string: "mailto:\(emailTo)?subject=\(subject.fixToBrowserString())"),
           UIApplication.shared.canOpenURL(url)
        {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }
}

#Preview {
    SettingsView(selectedTab: .constant(.bible))
        .environment(UserViewModel())
}

