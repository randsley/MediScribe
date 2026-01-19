import SwiftUI

struct SettingsView: View {
    var body: some View {
        NavigationStack {
            Form {
                Section("About") {
                    Text("MediScribe — Clinical documentation support.")
                        .font(.footnote)
                }
            }
            .navigationTitle("Settings")
        }
    }
}
