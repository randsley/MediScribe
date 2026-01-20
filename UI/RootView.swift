import SwiftUI

struct RootView: View {
    var body: some View {
        TabView {
            NotesHomeView()
                .tabItem { Label("Notes", systemImage: "doc.text") }

            ImagingHomeView()
                .tabItem { Label("Imaging", systemImage: "photo.on.rectangle") }

            LabsHomeView()
                .tabItem { Label("Labs", systemImage: "waveform.path.ecg") }

            ReferralsHomeView()
                .tabItem { Label("Referrals", systemImage: "paperplane") }

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gear") }
        }
    }
}
