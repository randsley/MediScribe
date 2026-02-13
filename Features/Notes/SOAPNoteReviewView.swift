//
//  SOAPNoteReviewView.swift
//  MediScribe
//
//  Review and validation view for generated SOAP notes
//

import SwiftUI

/// View for reviewing generated SOAP note with validation feedback
struct SOAPNoteReviewView: View {
    @ObservedObject var viewModel: SOAPNoteViewModel
    @State private var clinicianID: String = ""
    @State private var showSigningAlert: Bool = false
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    // MARK: - Validation Status Banner

                    if !viewModel.validationErrors.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.orange)
                                Text("Validation Warnings")
                                    .font(.headline)
                            }

                            ForEach(viewModel.validationErrors, id: \.id) { error in
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(error.field)
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.secondary)
                                    Text(error.message)
                                        .font(.caption)
                                }
                                .padding(.vertical, 4)
                                .padding(.horizontal, 8)
                                .background(Color(.systemGray6))
                                .cornerRadius(4)
                            }
                        }
                        .padding()
                        .background(Color(.systemYellow).opacity(0.1))
                        .cornerRadius(8)
                    } else {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("Validation Passed")
                                .font(.headline)
                        }
                        .padding()
                        .background(Color(.systemGreen).opacity(0.1))
                        .cornerRadius(8)
                    }

                    Divider()

                    // MARK: - SOAP Note Display

                    if let note = viewModel.currentNote {
                        // Subjective
                        VStack(alignment: .leading, spacing: 8) {
                            SectionHeader(title: "SUBJECTIVE", icon: "person.fill")

                            VStack(alignment: .leading, spacing: 8) {
                                SOAPDetailRow(label: "Chief Complaint", value: note.subjective.chiefComplaint)

                                SOAPDetailRow(label: "HPI", value: note.subjective.historyOfPresentIllness)

                                if let pmh = note.subjective.pastMedicalHistory, !pmh.isEmpty {
                                    SOAPDetailRow(label: "PMHx", value: pmh.joined(separator: ", "))
                                }

                                if let meds = note.subjective.medications, !meds.isEmpty {
                                    SOAPDetailRow(label: "Medications", value: meds.joined(separator: ", "))
                                }

                                if let allergies = note.subjective.allergies, !allergies.isEmpty {
                                    SOAPDetailRow(label: "Allergies", value: allergies.joined(separator: ", "))
                                }
                            }
                        }

                        Divider()

                        // Objective
                        VStack(alignment: .leading, spacing: 8) {
                            SectionHeader(title: "OBJECTIVE", icon: "stethoscope")

                            VStack(alignment: .leading, spacing: 8) {
                                Text("Vital Signs")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.secondary)

                                VStack(alignment: .leading, spacing: 4) {
                                    if let temp = note.objective.vitalSigns.temperature {
                                        Text("Temperature: \(String(format: "%.1f", temp.value))°C")
                                            .font(.caption)
                                    }
                                    if let hr = note.objective.vitalSigns.heartRate {
                                        Text("Heart Rate: \(Int(hr.value)) bpm")
                                            .font(.caption)
                                    }
                                    if let rr = note.objective.vitalSigns.respiratoryRate {
                                        Text("RR: \(Int(rr.value)) breaths/min")
                                            .font(.caption)
                                    }
                                    if let sys = note.objective.vitalSigns.systolicBP,
                                       let dia = note.objective.vitalSigns.diastolicBP {
                                        Text("BP: \(sys)/\(dia) mmHg")
                                            .font(.caption)
                                    }
                                    if let o2 = note.objective.vitalSigns.oxygenSaturation {
                                        Text("O₂: \(o2)%")
                                            .font(.caption)
                                    }
                                }
                                .padding(.vertical, 4)
                                .padding(.horizontal, 8)
                                .background(Color(.systemGray6))
                                .cornerRadius(4)

                                if let findings = note.objective.physicalExamFindings, !findings.isEmpty {
                                    SOAPDetailRow(label: "Exam", value: findings.joined(separator: ", "))
                                }
                            }
                        }

                        Divider()

                        // Assessment
                        VStack(alignment: .leading, spacing: 8) {
                            SectionHeader(title: "ASSESSMENT", icon: "doc.text")

                            SOAPDetailRow(label: "Impression", value: note.assessment.clinicalImpression)

                            if let diffs = note.assessment.differentialConsiderations, !diffs.isEmpty {
                                SOAPDetailRow(label: "Differentials", value: diffs.joined(separator: ", "))
                            }
                        }

                        Divider()

                        // Plan
                        VStack(alignment: .leading, spacing: 8) {
                            SectionHeader(title: "PLAN", icon: "list.bullet")

                            if let interventions = note.plan.interventions, !interventions.isEmpty {
                                SOAPDetailRow(label: "Interventions", value: interventions.joined(separator: ", "))
                            }

                            if let followUp = note.plan.followUp, !followUp.isEmpty {
                                SOAPDetailRow(label: "Follow-up", value: followUp.joined(separator: ", "))
                            }

                            if let education = note.plan.patientEducation, !education.isEmpty {
                                SOAPDetailRow(label: "Education", value: education.joined(separator: ", "))
                            }
                        }

                        Divider()

                        // Limitations Statement
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "info.circle.fill")
                                    .foregroundColor(.blue)
                                Text("Important Notice")
                                    .font(.headline)
                            }

                            Text("This summary describes visible image features only and does not assess clinical significance or provide a diagnosis.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color(.systemBlue).opacity(0.1))
                        .cornerRadius(8)
                    }

                    Spacer()
                }
                .padding()
            }

            // MARK: - Review Actions

            VStack(spacing: 12) {
                if !viewModel.isReviewed {
                    Button(action: {
                        viewModel.markAsReviewed(clinicianID: clinicianID.isEmpty ? "Current Clinician" : clinicianID)
                    }) {
                        HStack {
                            Image(systemName: "checkmark.seal")
                            Text("Mark as Reviewed")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                } else {
                    HStack {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundColor(.green)
                        Text("Reviewed by Clinician")
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.systemGreen).opacity(0.1))
                    .cornerRadius(8)

                    Button(action: {
                        showSigningAlert = true
                    }) {
                        HStack {
                            Image(systemName: "hand.raised.fingers.spread")
                            Text("Sign Note")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                }

                Button(action: {
                    let textContent = viewModel.exportAsText()
                    // Copy to pasteboard or share
                    UIPasteboard.general.string = textContent
                }) {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                        Text("Export as Text")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.systemGray5))
                    .foregroundColor(.primary)
                    .cornerRadius(8)
                }

                Button(action: { dismiss() }) {
                    Text("Done")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.systemGray3))
                        .foregroundColor(.primary)
                        .cornerRadius(8)
                }
            }
            .padding()
            .navigationTitle("Review SOAP Note")
            .navigationBarTitleDisplayMode(.inline)
            .alert("Sign Note", isPresented: $showSigningAlert) {
                TextField("Clinician ID", text: $clinicianID)
                Button("Sign") {
                    viewModel.signNote(clinicianID: clinicianID.isEmpty ? "Current Clinician" : clinicianID)
                    dismiss()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Enter your clinician ID to sign this note")
            }
        }
    }
}

// MARK: - Helper Components

struct SectionHeader: View {
    let title: String
    let icon: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
            Text(title)
                .font(.headline)
            Spacer()
        }
        .padding(.bottom, 4)
    }
}

struct SOAPDetailRow: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
            Text(value)
                .font(.body)
        }
    }
}

// MARK: - Preview

struct SOAPNoteReviewView_Previews: PreviewProvider {
    static var previews: some View {
        SOAPNoteReviewView(viewModel: SOAPNoteViewModel())
    }
}
