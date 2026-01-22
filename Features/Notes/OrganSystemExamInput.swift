//
//  OrganSystemExamInput.swift
//  MediScribe
//
//  Organ system-based exam findings input with system-specific suggestions
//

import SwiftUI

struct OrganSystemExamInput: View {
    let title: String
    @Binding var examFindings: [String: [String]]

    @State private var selectedSystem: String?
    @State private var newFinding = ""

    // Organ systems available
    private let organSystems = [
        "Cardiovascular",
        "Respiratory",
        "Abdominal",
        "Neurological",
        "Skin",
        "Musculoskeletal",
        "ENT"
    ]

    // System-specific finding suggestions
    private let suggestions: [String: [String]] = [
        "Cardiovascular": [
            "Regular rhythm",
            "No murmurs",
            "Normal S1/S2",
            "Pulses equal bilaterally",
            "No peripheral edema",
            "Capillary refill <2s"
        ],
        "Respiratory": [
            "Clear breath sounds",
            "No wheezes",
            "No crackles",
            "Equal air entry",
            "No increased work of breathing",
            "Non-labored breathing"
        ],
        "Abdominal": [
            "Soft",
            "Non-tender",
            "No masses",
            "Bowel sounds present",
            "No guarding",
            "No rebound tenderness",
            "No organomegaly"
        ],
        "Neurological": [
            "Alert and oriented",
            "Pupils equal and reactive",
            "Cranial nerves intact",
            "Motor strength 5/5",
            "Sensation intact",
            "Normal gait",
            "No focal deficits"
        ],
        "Skin": [
            "Warm and dry",
            "Normal color",
            "No rash",
            "No lesions",
            "Good turgor",
            "No jaundice",
            "No cyanosis"
        ],
        "Musculoskeletal": [
            "Full range of motion",
            "No deformity",
            "No swelling",
            "No tenderness",
            "Normal gait",
            "Symmetric movement"
        ],
        "ENT": [
            "Ears clear",
            "Throat non-erythematous",
            "No tonsillar exudate",
            "Nasal passages clear",
            "No lymphadenopathy"
        ]
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)

            if selectedSystem == nil {
                // System selection grid
                systemSelectionGrid
            } else {
                // Findings entry for selected system
                systemFindingsEntry
            }
        }
    }

    // MARK: - Subviews

    private var systemSelectionGrid: some View {
        let columns = [
            GridItem(.flexible()),
            GridItem(.flexible())
        ]

        return VStack(alignment: .leading, spacing: 12) {
            Text("Select Organ System")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(organSystems, id: \.self) { system in
                    Button(action: {
                        selectedSystem = system
                    }) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(system)
                                    .font(.body)
                                    .fontWeight(.semibold)

                                // Show count of findings
                                if let findings = examFindings[system], !findings.isEmpty {
                                    Text("\(findings.count) finding\(findings.count == 1 ? "" : "s")")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            Spacer()

                            // Visual indicator if system has findings
                            if let findings = examFindings[system], !findings.isEmpty {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                            } else {
                                Image(systemName: "circle")
                                    .foregroundStyle(.gray)
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue.opacity(0.05))
                        .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var systemFindingsEntry: some View {
        guard let system = selectedSystem else {
            return AnyView(EmptyView())
        }

        let findings = Binding<[String]>(
            get: { examFindings[system] ?? [] },
            set: { newValue in
                if newValue.isEmpty {
                    examFindings.removeValue(forKey: system)
                } else {
                    examFindings[system] = newValue
                }
            }
        )

        return AnyView(
            VStack(alignment: .leading, spacing: 12) {
                // Header with back button
                HStack {
                    Button(action: {
                        selectedSystem = nil
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                            Text("Back to Systems")
                        }
                        .font(.subheadline)
                    }
                    Spacer()
                }

                Divider()

                // System name
                Text(system)
                    .font(.title3)
                    .fontWeight(.bold)

                // Existing findings
                if !findings.wrappedValue.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Findings")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        ForEach(Array(findings.wrappedValue.enumerated()), id: \.offset) { index, finding in
                            HStack {
                                Text(finding)
                                    .padding(.vertical, 8)
                                Spacer()
                                Button(action: {
                                    var updated = findings.wrappedValue
                                    updated.remove(at: index)
                                    findings.wrappedValue = updated
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundStyle(.red)
                                        .font(.title3)
                                }
                            }
                            .padding(.horizontal, 12)
                            .background(Color.blue.opacity(0.05))
                            .cornerRadius(8)
                        }
                    }
                }

                // Add new finding
                HStack {
                    TextField("Add finding...", text: $newFinding)
                        .textFieldStyle(.roundedBorder)

                    Button(action: addFinding) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundStyle(.green)
                            .font(.title)
                    }
                    .disabled(newFinding.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }

                // Suggestions
                if let systemSuggestions = suggestions[system] {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Common Findings")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(systemSuggestions, id: \.self) { suggestion in
                                    Button(suggestion) {
                                        if !findings.wrappedValue.contains(suggestion) {
                                            var updated = findings.wrappedValue
                                            updated.append(suggestion)
                                            findings.wrappedValue = updated
                                        }
                                    }
                                    .buttonStyle(.bordered)
                                    .disabled(findings.wrappedValue.contains(suggestion))
                                }
                            }
                        }
                    }
                    .padding(12)
                    .background(Color.orange.opacity(0.05))
                    .cornerRadius(8)
                }
            }
        )
    }

    // MARK: - Actions

    private func addFinding() {
        guard let system = selectedSystem else { return }

        let trimmed = newFinding.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        var findings = examFindings[system] ?? []
        guard !findings.contains(trimmed) else {
            newFinding = ""
            return
        }

        findings.append(trimmed)
        examFindings[system] = findings
        newFinding = ""
    }
}

#Preview {
    OrganSystemExamInput(
        title: "Focused Examination",
        examFindings: .constant([
            "Cardiovascular": ["Regular rhythm", "No murmurs"],
            "Respiratory": ["Clear breath sounds"]
        ])
    )
    .padding()
}
