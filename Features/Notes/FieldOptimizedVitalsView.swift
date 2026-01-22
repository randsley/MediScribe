//
//  FieldOptimizedVitalsView.swift
//  MediScribe
//
//  Field-optimized vitals entry with large touch targets and number pad
//

import SwiftUI

struct FieldOptimizedVitalsView: View {
    @Binding var vitalSet: VitalSet
    var onSave: () -> Void

    @State private var currentField: VitalField?
    @State private var inputValue = ""

    enum VitalField: String, CaseIterable {
        case systolic = "Systolic BP"
        case diastolic = "Diastolic BP"
        case heartRate = "Heart Rate"
        case respiratoryRate = "Resp Rate"
        case spo2 = "SpO2"
        case temperature = "Temperature"
        case gcs = "GCS"

        var unit: String {
            switch self {
            case .systolic, .diastolic: return "mmHg"
            case .heartRate: return "bpm"
            case .respiratoryRate: return "/min"
            case .spo2: return "%"
            case .temperature: return "°C"
            case .gcs: return "/15"
            }
        }

        var maxDigits: Int {
            switch self {
            case .temperature: return 4
            case .spo2, .gcs: return 2
            default: return 3
            }
        }

        var allowDecimal: Bool {
            return self == .temperature
        }

        var icon: String {
            switch self {
            case .systolic, .diastolic: return "heart.fill"
            case .heartRate: return "waveform.path.ecg"
            case .respiratoryRate: return "lungs.fill"
            case .spo2: return "drop.fill"
            case .temperature: return "thermometer"
            case .gcs: return "brain.head.profile"
            }
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Current values display
                    currentValuesCard

                    // Field selection grid
                    if currentField == nil {
                        fieldSelectionGrid
                    } else {
                        // Number pad for selected field
                        numberPadSection
                    }
                }
                .padding()
            }
            .navigationTitle(currentField == nil ? "Record Vitals" : currentField!.rawValue)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        if currentField != nil {
                            currentField = nil
                            inputValue = ""
                        } else {
                            onSave()
                        }
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    if currentField == nil {
                        Button("Save") {
                            vitalSet.timestamp = Date()
                            onSave()
                        }
                    }
                }
            }
        }
    }

    // MARK: - Subviews

    private var currentValuesCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Current Values")
                .font(.headline)

            VStack(spacing: 8) {
                valueRow("BP", "\(vitalSet.bloodPressure?.systolic ?? 0)/\(vitalSet.bloodPressure?.diastolic ?? 0) mmHg")
                valueRow("HR", vitalSet.heartRate.map { "\($0) bpm" } ?? "—")
                valueRow("RR", vitalSet.respiratoryRate.map { "\($0) /min" } ?? "—")
                valueRow("SpO2", vitalSet.spo2.map { "\($0)%" } ?? "—")
                valueRow("Temp", vitalSet.temperatureCelsius.map { String(format: "%.1f°C", $0) } ?? "—")
                valueRow("GCS", vitalSet.gcs.map { "\($0)/15" } ?? "—")
            }
        }
        .padding()
        .background(Color.blue.opacity(0.05))
        .cornerRadius(12)
    }

    private func valueRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .fontWeight(.medium)
            Spacer()
            Text(value)
                .foregroundStyle(.secondary)
        }
        .font(.body)
    }

    private var fieldSelectionGrid: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Select Vital to Record")
                .font(.headline)

            let columns = [
                GridItem(.flexible()),
                GridItem(.flexible())
            ]

            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(VitalField.allCases, id: \.self) { field in
                    Button(action: {
                        selectField(field)
                    }) {
                        VStack(spacing: 8) {
                            Image(systemName: field.icon)
                                .font(.largeTitle)
                            Text(field.rawValue)
                                .font(.body)
                                .fontWeight(.semibold)
                            Text(field.unit)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 24)
                        .background(Color.blue)
                        .cornerRadius(12)
                    }
                }
            }
        }
    }

    private var numberPadSection: some View {
        VStack(spacing: 20) {
            if let field = currentField {
                VStack(spacing: 8) {
                    HStack {
                        Image(systemName: field.icon)
                            .font(.title)
                        Text(field.rawValue)
                            .font(.title2)
                            .fontWeight(.bold)
                    }
                    Text(field.unit)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                LargeNumberPad(
                    value: $inputValue,
                    maxDigits: field.maxDigits,
                    allowDecimal: field.allowDecimal
                )

                Button(action: {
                    saveFieldValue()
                }) {
                    Text("Confirm")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(inputValue.isEmpty ? Color.gray : Color.green)
                        .cornerRadius(12)
                }
                .disabled(inputValue.isEmpty)
            }
        }
    }

    // MARK: - Actions

    private func selectField(_ field: VitalField) {
        currentField = field

        // Pre-populate with existing value
        switch field {
        case .systolic:
            if let value = vitalSet.bloodPressure?.systolic {
                inputValue = "\(value)"
            }
        case .diastolic:
            if let value = vitalSet.bloodPressure?.diastolic {
                inputValue = "\(value)"
            }
        case .heartRate:
            if let value = vitalSet.heartRate {
                inputValue = "\(value)"
            }
        case .respiratoryRate:
            if let value = vitalSet.respiratoryRate {
                inputValue = "\(value)"
            }
        case .spo2:
            if let value = vitalSet.spo2 {
                inputValue = "\(value)"
            }
        case .temperature:
            if let value = vitalSet.temperatureCelsius {
                inputValue = String(format: "%.1f", value)
            }
        case .gcs:
            if let value = vitalSet.gcs {
                inputValue = "\(value)"
            }
        }
    }

    private func saveFieldValue() {
        guard let field = currentField, !inputValue.isEmpty else {
            return
        }

        switch field {
        case .systolic:
            if vitalSet.bloodPressure == nil {
                vitalSet.bloodPressure = BloodPressure(systolic: Int(inputValue) ?? 0, diastolic: 0)
            } else {
                vitalSet.bloodPressure?.systolic = Int(inputValue) ?? 0
            }

        case .diastolic:
            if vitalSet.bloodPressure == nil {
                vitalSet.bloodPressure = BloodPressure(systolic: 0, diastolic: Int(inputValue) ?? 0)
            } else {
                vitalSet.bloodPressure?.diastolic = Int(inputValue) ?? 0
            }

        case .heartRate:
            vitalSet.heartRate = Int(inputValue)

        case .respiratoryRate:
            vitalSet.respiratoryRate = Int(inputValue)

        case .spo2:
            vitalSet.spo2 = Int(inputValue)

        case .temperature:
            vitalSet.temperatureCelsius = Double(inputValue)

        case .gcs:
            vitalSet.gcs = Int(inputValue)
        }

        // Reset
        currentField = nil
        inputValue = ""
    }
}

#Preview {
    FieldOptimizedVitalsView(
        vitalSet: .constant(VitalSet()),
        onSave: {}
    )
}
