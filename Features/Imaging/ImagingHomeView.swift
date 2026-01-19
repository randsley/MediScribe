import SwiftUI

struct ImagingHomeView: View {
    var body: some View {
        NavigationStack {
            List {
                NavigationLink("Generate findings summary") {
                    ImagingGenerateView()
                }
                NavigationLink("History") {
                    ImagingHistoryView()
                }
            }
            .navigationTitle("Imaging Review")
        }
    }
}
