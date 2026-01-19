import SwiftUI

struct RootView: View {
    var body: some View {
        TabView {
            NotesHomeView()
                .tabItem { Label("Notes", systemImage: "doc.text") }

            ImagingHomeView()
                .tabItem { Label("Imaging", systemImage: "photo.on.rectangle") }

            ReferralsHomeView()
                .tabItem { Label("Referrals", systemImage: "paperplane") }

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gear") }
        }
    }
}
