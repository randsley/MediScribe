import SwiftUI
import CoreData // Import CoreData

struct NoteEditorView: View {
    @Binding var note: FieldNote
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.managedObjectContext) private var viewContext // Inject managed object context

    // Optional: if provided, we're editing an existing note
    var existingNoteEntity: Note?

    @State private var showingVitalsInput = false
    @State private var currentVitals: VitalSet = VitalSet()

    var body: some View {
        NavigationView {
            Form {
                // MARK: - Field Header (NoteMeta)
                Section("Patient & Encounter Details") {
                    TextField("Patient ID", text: $note.meta.patient.id)
                    Picker("Sex at Birth", selection: Binding(
                        get: { note.meta.patient.sexAtBirth ?? .unknown },
                        set: { note.meta.patient.sexAtBirth = $0 == .unknown ? nil : $0 }
                    )) {
                        Text("Unknown").tag(SexAtBirth.unknown)
                        Text("Male").tag(SexAtBirth.male)
                        Text("Female").tag(SexAtBirth.female)
                    }
                    TextField("Estimated Age (Years)", value: $note.meta.patient.estimatedAgeYears, formatter: NumberFormatter())
                        .keyboardType(.numberPad)

                    Picker("Encounter Setting", selection: $note.meta.encounter.setting) {
                        ForEach(EncounterSetting.allCases, id: \.self) { setting in
                            Text(setting.rawValue.capitalized).tag(setting)
                        }
                    }
                    TextField("Location Text", text: Binding(
                        get: { note.meta.encounter.locationText ?? "" },
                        set: { note.meta.encounter.locationText = $0.isEmpty ? nil : $0 }
                    ))
                }

                // MARK: - Triage
                Section("Triage") {
                    Picker("Triage System", selection: Binding(
                        get: { note.triage?.system ?? .start },
                        set: {
                            if note.triage == nil { note.triage = NoteTriage(system: $0, category: .red) }
                            else { note.triage?.system = $0 }
                        }
                    )) {
                        ForEach(TriageSystem.allCases, id: \.self) { system in
                            Text(system.rawValue).tag(system)
                        }
                    }
                    Picker("Triage Category", selection: Binding(
                        get: { note.triage?.category ?? .red },
                        set: {
                            if note.triage == nil { note.triage = NoteTriage(system: .start, category: $0) }
                            else { note.triage?.category = $0 }
                        }
                    )) {
                        ForEach(TriageCategory.allCases, id: \.self) { category in
                            Text(category.rawValue.capitalized).tag(category)
                        }
                    }
                }

                // MARK: - Subjective
                Section("Subjective") {
                    TextField("Chief Complaint", text: Binding(
                        get: { note.subjective?.chiefComplaint ?? "" },
                        set: {
                            if note.subjective == nil { note.subjective = NoteSubjective() }
                            note.subjective?.chiefComplaint = $0.isEmpty ? nil : $0
                        }
                    ))
                    TextField("Onset / Duration", text: Binding(
                        get: { note.subjective?.onset ?? "" },
                        set: {
                            if note.subjective == nil { note.subjective = NoteSubjective() }
                            note.subjective?.onset = $0.isEmpty ? nil : $0
                        }
                    ))
                    TextField("Severity", text: Binding(
                        get: { note.subjective?.severity ?? "" },
                        set: {
                            if note.subjective == nil { note.subjective = NoteSubjective() }
                            note.subjective?.severity = $0.isEmpty ? nil : $0
                        }
                    ))
                    TextField("Mechanism / Exposure", text: Binding(
                        get: { note.subjective?.mechanismOrExposure ?? "" },
                        set: {
                            if note.subjective == nil { note.subjective = NoteSubjective() }
                            note.subjective?.mechanismOrExposure = $0.isEmpty ? nil : $0
                        }
                    ))
                    TextField("Associated Symptoms (comma-separated)", text: Binding(
                        get: { note.subjective?.associatedSymptoms.joined(separator: ", ") ?? "" },
                        set: {
                            if note.subjective == nil { note.subjective = NoteSubjective() }
                            note.subjective?.associatedSymptoms = $0.split(separator: ",").map { String($0.trimmingCharacters(in: .whitespaces)) }
                        }
                    ))
                    TextField("Allergies (or unknown)", text: Binding(
                        get: { note.subjective?.allergies ?? "" },
                        set: {
                            if note.subjective == nil { note.subjective = NoteSubjective() }
                            note.subjective?.allergies = $0.isEmpty ? nil : $0
                        }
                    ))
                    TextField("Medications (or unknown)", text: Binding(
                        get: { note.subjective?.medications ?? "" },
                        set: {
                            if note.subjective == nil { note.subjective = NoteSubjective() }
                            note.subjective?.medications = $0.isEmpty ? nil : $0
                        }
                    ))
                    TextField("Key Risks (comma-separated)", text: Binding(
                        get: { note.subjective?.keyRisks.joined(separator: ", ") ?? "" },
                        set: {
                            if note.subjective == nil { note.subjective = NoteSubjective() }
                            note.subjective?.keyRisks = $0.split(separator: ",").map { String($0.trimmingCharacters(in: .whitespaces)) }
                        }
                    ))
                }

                // MARK: - Objective
                Section("Objective") {
                    Button("Add Vitals") {
                        currentVitals = VitalSet() // Reset for new entry
                        showingVitalsInput = true
                    }
                    ForEach(note.objective?.vitals ?? []) { vitalSet in
                        Text("BP: \(vitalSet.bloodPressure?.systolic ?? 0)/\(vitalSet.bloodPressure?.diastolic ?? 0), HR: \(vitalSet.heartRate ?? 0), RR: \(vitalSet.respiratoryRate ?? 0), SpO2: \(vitalSet.spo2 ?? 0)%")
                    }
                    TextField("Primary Survey (ABCDE/AVPU/GCS)", text: Binding(
                        get: { note.objective?.primarySurvey ?? "" },
                        set: {
                            if note.objective == nil { note.objective = NoteObjective() }
                            note.objective?.primarySurvey = $0.isEmpty ? nil : $0
                        }
                    ))
                    TextField("Focused Exam (comma-separated)", text: Binding(
                        get: { note.objective?.focusedExam.values.flatMap { $0 }.joined(separator: ", ") ?? "" },
                        set: {
                            if note.objective == nil { note.objective = NoteObjective() }
                            let components = $0.split(separator: ",").map { String($0.trimmingCharacters(in: .whitespaces)) }
                            note.objective?.focusedExam = ["general": components] // Simplified: all under "general"
                        }
                    ))
                    TextField("Point-of-Care Tests (comma-separated)", text: Binding(
                        get: { note.objective?.pointOfCareTests.joined(separator: ", ") ?? "" },
                        set: {
                            if note.objective == nil { note.objective = NoteObjective() }
                            note.objective?.pointOfCareTests = $0.split(separator: ",").map { String($0.trimmingCharacters(in: .whitespaces)) }
                        }
                    ))
                }

                // MARK: - Assessment
                Section("Assessment") {
                    TextField("Working Diagnoses (comma-separated)", text: Binding(
                        get: { note.assessment?.workingDiagnoses.map { $0.label }.joined(separator: ", ") ?? "" },
                        set: {
                            if note.assessment == nil { note.assessment = NoteAssessment() }
                            note.assessment?.workingDiagnoses = $0.split(separator: ",").map { Diagnosis(label: String($0.trimmingCharacters(in: .whitespaces)), certainty: .possible) }
                        }
                    ))
                    TextField("Differentials (comma-separated)", text: Binding(
                        get: { note.assessment?.differentials.joined(separator: ", ") ?? "" },
                        set: {
                            if note.assessment == nil { note.assessment = NoteAssessment() }
                            note.assessment?.differentials = $0.split(separator: ",").map { String($0.trimmingCharacters(in: .whitespaces)) }
                        }
                    ))
                    TextField("Red Flags (comma-separated)", text: Binding(
                        get: { note.assessment?.redFlags.joined(separator: ", ") ?? "" },
                        set: {
                            if note.assessment == nil { note.assessment = NoteAssessment() }
                            note.assessment?.redFlags = $0.split(separator: ",").map { String($0.trimmingCharacters(in: .whitespaces)) }
                        }
                    ))
                    Picker("Stability", selection: Binding(
                        get: { note.assessment?.stability ?? .stable },
                        set: {
                            if note.assessment == nil { note.assessment = NoteAssessment() }
                            note.assessment?.stability = $0
                        }
                    )) {
                        ForEach(Stability.allCases, id: \.self) { stability in
                            Text(stability.rawValue.capitalized).tag(stability)
                        }
                    }
                }

                // MARK: - Plan
                Section("Plan") {
                    TextField("Immediate Actions (comma-separated)", text: Binding(
                        get: { note.plan?.immediateActions.joined(separator: ", ") ?? "" },
                        set: {
                            if note.plan == nil { note.plan = NotePlan() }
                            note.plan?.immediateActions = $0.split(separator: ",").map { String($0.trimmingCharacters(in: .whitespaces)) }
                        }
                    ))
                    TextField("Medications Given (comma-separated)", text: Binding(
                        get: { note.plan?.medicationsGiven.joined(separator: ", ") ?? "" },
                        set: {
                            if note.plan == nil { note.plan = NotePlan() }
                            note.plan?.medicationsGiven = $0.split(separator: ",").map { String($0.trimmingCharacters(in: .whitespaces)) }
                        }
                    ))
                    Picker("Disposition Type", selection: Binding(
                        get: { note.plan?.disposition?.type ?? .observe },
                        set: {
                            if note.plan == nil { note.plan = NotePlan() }
                            if note.plan?.disposition == nil { note.plan?.disposition = Disposition(type: $0) }
                            else { note.plan?.disposition?.type = $0 }
                        }
                    )) {
                        ForEach(DispositionType.allCases, id: \.self) { type in
                            Text(type.rawValue.capitalized).tag(type)
                        }
                    }
                    TextField("Destination", text: Binding(
                        get: { note.plan?.disposition?.destination ?? "" },
                        set: {
                            if note.plan == nil { note.plan = NotePlan() }
                            if note.plan?.disposition == nil { note.plan?.disposition = Disposition(type: .observe) }
                            note.plan?.disposition?.destination = $0.isEmpty ? nil : $0
                        }
                    ))
                    Picker("Urgency", selection: Binding(
                        get: { note.plan?.disposition?.urgency ?? .routine },
                        set: {
                            if note.plan == nil { note.plan = NotePlan() }
                            if note.plan?.disposition == nil { note.plan?.disposition = Disposition(type: .observe) }
                            note.plan?.disposition?.urgency = $0
                        }
                    )) {
                        ForEach(Urgency.allCases, id: \.self) { urgency in
                            Text(urgency.rawValue.capitalized).tag(urgency)
                        }
                    }
                    TextField("Safety-Net Instructions", text: Binding(
                        get: { note.plan?.safetyNetInstructions ?? "" },
                        set: {
                            if note.plan == nil { note.plan = NotePlan() }
                            note.plan?.safetyNetInstructions = $0.isEmpty ? nil : $0
                        }
                    ))
                }
            }
            .navigationTitle("New Note")
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Save") {
                    saveNote()
                    presentationMode.wrappedValue.dismiss()
                }
            )
            .sheet(isPresented: $showingVitalsInput) {
                VitalsInputView(vitalSet: $currentVitals) {
                    if note.objective == nil { note.objective = NoteObjective() }
                    note.objective?.vitals.append(currentVitals)
                    showingVitalsInput = false
                }
            }
        }
    }

    private func saveNote() {
        do {
            let noteEntity: Note

            if let existing = existingNoteEntity {
                // Check if note is locked
                if existing.isLocked {
                    throw NoteSigningError.cannotEditLockedNote
                }
                // Update existing note
                noteEntity = existing
            } else {
                // Create new note
                noteEntity = Note(context: viewContext)
                noteEntity.id = note.id
                noteEntity.createdAt = note.meta.createdAt
            }

            // Use encrypted save method (works for both new and existing)
            try noteEntity.setFieldNote(note)

            try viewContext.save()
        } catch {
            // Handle the error appropriately, e.g., show an alert to the user
            print("Failed to save note (encrypted): \(error.localizedDescription)")
        }
    }
}

// MARK: - Vitals Input Sub-View
struct VitalsInputView: View {
    @Binding var vitalSet: VitalSet
    var onSave: () -> Void

    var body: some View {
        NavigationView {
            Form {
                Section("Blood Pressure") {
                    TextField("Systolic", value: $vitalSet.bloodPressure.systolic, formatter: NumberFormatter())
                        .keyboardType(.numberPad)
                    TextField("Diastolic", value: $vitalSet.bloodPressure.diastolic, formatter: NumberFormatter())
                        .keyboardType(.numberPad)
                }
                Section("Other Vitals") {
                    TextField("Heart Rate", value: $vitalSet.heartRate, formatter: NumberFormatter())
                        .keyboardType(.numberPad)
                    TextField("Respiratory Rate", value: $vitalSet.respiratoryRate, formatter: NumberFormatter())
                        .keyboardType(.numberPad)
                    TextField("SpO2 (%)", value: $vitalSet.spo2, formatter: NumberFormatter())
                        .keyboardType(.numberPad)
                    TextField("Temperature (°C)", value: $vitalSet.temperatureCelsius, formatter: NumberFormatter())
                        .keyboardType(.decimalPad)
                    TextField("GCS", value: $vitalSet.gcs, formatter: NumberFormatter())
                        .keyboardType(.numberPad)
                }
            }
            .navigationTitle("Add Vitals")
            .navigationBarItems(
                leading: Button("Cancel") {
                    // Dismiss without saving
                    onSave() // Call onSave to dismiss the sheet, but don't add vitals
                },
                trailing: Button("Save") {
                    onSave()
                }
            )
        }
    }
}

// MARK: - Previews
struct NoteEditorView_Previews: PreviewProvider {
    @State static var sampleNote: FieldNote = {
        var note = FieldNote(
            meta: NoteMeta(
                author: NoteAuthor(id: "clin_01", displayName: "Dr. Smith", role: "Physician"),
                patient: NotePatient(id: "PAT-001", estimatedAgeYears: 35, sexAtBirth: .male),
                encounter: NoteEncounter(setting: .roadside, locationText: "Village A"),
                consent: NoteConsent(status: .obtained)
            )
        )
        note.triage = NoteTriage(system: .start, category: .yellow)
        return note
    }()

    static var previews: some View {
        NoteEditorView(note: $sampleNote)
    }
}

// Extend Enums for ForEach
extension EncounterSetting: CaseIterable {}
extension TriageSystem: CaseIterable {}
extension TriageCategory: CaseIterable {}
extension SexAtBirth: CaseIterable {}
extension Stability: CaseIterable {}
extension DispositionType: CaseIterable {}
extension Urgency: CaseIterable {}
