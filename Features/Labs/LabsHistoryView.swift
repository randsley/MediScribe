//
//  LabsHistoryView.swift
//  MediScribe
//
//  View for browsing historical lab results
//

import SwiftUI

struct LabsHistoryView: View {
    var body: some View {
        List {
            Text("Lab results history will appear here")
                .foregroundStyle(.secondary)
        }
        .navigationTitle("Lab History")
    }
}

#Preview {
    NavigationStack {
        LabsHistoryView()
    }
}
