//
//  SOAPNoteInputView.swift
//  MediScribe
//
//  Form for collecting patient information for SOAP note generation
//

import SwiftUI

/// View for collecting patient data and vital signs
struct SOAPNoteInputView: View {
    @ObservedObject var viewModel: SOAPNoteViewModel
    @State private var newHistoryItem: String = ""
    @State private var newMedication: String = ""
    @State private var newAllergy: String = ""

    var body: some View {
        NavigationStack {
            Form {
                // MARK: - Demographics Section

                Section(header: Text("Patient Information").font(.headline)) {
                    HStack {
                        Text("Age")
                        Spacer()
                        TextField("Years", text: $viewModel.patientAge)
                            .keyboardType(.numberPad)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 80)
                    }

                    Picker("Sex", selection: $viewModel.patientSex) {
                        Text("Male").tag("M")
                        Text("Female").tag("F")
                        Text("Other").tag("Other")
                    }

                    TextField("Chief Complaint", text: $viewModel.chiefComplaint)
                        .textFieldStyle(.roundedBorder)
                }

                // MARK: - Vital Signs Section

                Section(header: Text("Vital Signs").font(.headline)) {
                    HStack {
                        Text("Temperature")
                        Spacer()
                        TextField("°C", text: $viewModel.temperature)
                            .keyboardType(.decimalPad)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 80)
                    }

                    HStack {
                        Text("Heart Rate")
                        Spacer()
                        TextField("bpm", text: $viewModel.heartRate)
                            .keyboardType(.numberPad)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 80)
                    }

                    HStack {
                        Text("Respiratory Rate")
                        Spacer()
                        TextField("breaths/min", text: $viewModel.respiratoryRate)
                            .keyboardType(.numberPad)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 80)
                    }

                    HStack {
                        Text("BP Systolic")
                        Spacer()
                        TextField("mmHg", text: $viewModel.systolicBP)
                            .keyboardType(.numberPad)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 80)
                    }

                    HStack {
                        Text("BP Diastolic")
                        Spacer()
                        TextField("mmHg", text: $viewModel.diastolicBP)
                            .keyboardType(.numberPad)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 80)
                    }

                    HStack {
                        Text("O₂ Saturation")
                        Spacer()
                        TextField("%", text: $viewModel.oxygenSaturation)
                            .keyboardType(.numberPad)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 80)
                    }
                }

                // MARK: - Medical History Section

                Section(header: Text("Medical History").font(.headline)) {
                    ForEach(viewModel.medicalHistory, id: \.self) { item in
                        HStack {
                            Text(item)
                            Spacer()
                            Button(action: {
                                viewModel.medicalHistory.removeAll { $0 == item }
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.red)
                            }
                        }
                    }

                    HStack {
                        TextField("Add history item", text: $newHistoryItem)
                            .textFieldStyle(.roundedBorder)
                        Button(action: {
                            if !newHistoryItem.trimmingCharacters(in: .whitespaces).isEmpty {
                                viewModel.medicalHistory.append(newHistoryItem)
                                newHistoryItem = ""
                            }
                        }) {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.blue)
                        }
                    }
                }

                // MARK: - Medications Section

                Section(header: Text("Current Medications").font(.headline)) {
                    ForEach(viewModel.medications, id: \.self) { item in
                        HStack {
                            Text(item)
                            Spacer()
                            Button(action: {
                                viewModel.medications.removeAll { $0 == item }
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.red)
                            }
                        }
                    }

                    HStack {
                        TextField("Add medication", text: $newMedication)
                            .textFieldStyle(.roundedBorder)
                        Button(action: {
                            if !newMedication.trimmingCharacters(in: .whitespaces).isEmpty {
                                viewModel.medications.append(newMedication)
                                newMedication = ""
                            }
                        }) {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.blue)
                        }
                    }
                }

                // MARK: - Allergies Section

                Section(header: Text("Allergies").font(.headline)) {
                    ForEach(viewModel.allergies, id: \.self) { item in
                        HStack {
                            Text(item)
                            Spacer()
                            Button(action: {
                                viewModel.allergies.removeAll { $0 == item }
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.red)
                            }
                        }
                    }

                    HStack {
                        TextField("Add allergy", text: $newAllergy)
                            .textFieldStyle(.roundedBorder)
                        Button(action: {
                            if !newAllergy.trimmingCharacters(in: .whitespaces).isEmpty {
                                viewModel.allergies.append(newAllergy)
                                newAllergy = ""
                            }
                        }) {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.blue)
                        }
                    }
                }

                // MARK: - Safety Notice Section

                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("AI-Assisted Documentation", systemImage: "info.circle.fill")
                            .font(.headline)

                        Text("This SOAP note will be generated with AI assistance. All output requires clinician review and verification before use. Clinician remains responsible for all clinical decisions.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }

                // MARK: - Generate Button

                Section {
                    Button(action: { viewModel.generateSOAPNote() }) {
                        if viewModel.generationState.isGenerating {
                            HStack {
                                ProgressView()
                                    .tint(.white)
                                Text("Generating...")
                            }
                            .frame(maxWidth: .infinity)
                            .foregroundColor(.white)
                        } else {
                            Text("Generate SOAP Note")
                                .frame(maxWidth: .infinity)
                                .foregroundColor(.white)
                        }
                    }
                    .listRowBackground(Color.blue)
                    .disabled(!viewModel.isReadyToGenerate || viewModel.generationState.isGenerating)
                }
            }
            .navigationTitle("New SOAP Note")
            .navigationBarTitleDisplayMode(.inline)
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK") { viewModel.showError = false }
            } message: {
                Text(viewModel.errorMessage)
            }
        }
    }
}

// MARK: - Preview

struct SOAPNoteInputView_Previews: PreviewProvider {
    static var previews: some View {
        SOAPNoteInputView(viewModel: SOAPNoteViewModel())
    }
}
