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

    // MARK: - Field-Optimized Suggestions (Multi-Regional Coverage)

    // Symptom options (universal coverage)
    private let symptomOptions = [
        "Fever",
        "Cough",
        "Headache",
        "Nausea",
        "Vomiting",
        "Diarrhea",
        "Fatigue",
        "Chest Pain",
        "Shortness of Breath",
        "Abdominal Pain",
        "Rash",
        "Joint Pain",
        "Night Sweats",
        "Weight Loss",
        "Bleeding",
        "Seizure",
        "Altered Consciousness",
        "Weakness"
    ]

    // Key risk factors (including regional conditions)
    private let keyRiskOptions = [
        "Diabetes",
        "Hypertension",
        "Asthma",
        "COPD",
        "Heart Disease",
        "Immunocompromised",
        "HIV+",
        "TB Contact",
        "Pregnancy",
        "Malnutrition",
        "Sickle Cell Disease",
        "Chronic Kidney Disease",
        "Allergy History"
    ]

    // Red flags (critical signs requiring immediate attention)
    private let redFlagOptions = [
        "Altered Consciousness",
        "Severe Pain",
        "Respiratory Distress",
        "Severe Bleeding",
        "Shock",
        "Seizure",
        "Stroke Signs",
        "Chest Pain",
        "Unable to Feed/Drink",
        "Severe Dehydration",
        "High Fever (>39°C)",
        "Severe Malnutrition",
        "Severe Anemia"
    ]

    // Point-of-care tests (universal + regional)
    private let testSuggestions = [
        // Universal/WHO
        "Blood Glucose",
        "SpO2",
        "Urinalysis",
        "Pregnancy Test",
        "Hemoglobin",
        // East/Central Africa
        "Rapid Malaria Test (RDT)",
        "HIV Rapid Test",
        "TB Sputum Test",
        "Stool Microscopy",
        // South/Southeast Asia
        "Dengue NS1/IgM",
        "Typhoid Rapid Test",
        "JE Serology",
        // Latin America
        "Chagas Serology",
        "Leishmaniasis RDT"
    ]

    // Immediate actions (common interventions)
    private let actionSuggestions = [
        "Oral Rehydration",
        "Oxygen Therapy",
        "IV Fluids",
        "Wound Dressing",
        "Splinting",
        "Analgesia",
        "Antipyretic Given",
        "Antibiotics Started"
    ]

    // Medications (WHO generic + multi-regional coverage)
    private let medicationSuggestions = [
        // WHO Generic/Universal
        "Paracetamol",
        "Ibuprofen",
        "Amoxicillin",
        "Metronidazole",
        "Salbutamol",
        "ORS",
        "Ceftriaxone",
        "Gentamicin",
        "Dexamethasone",
        // East/Central Africa
        "Artemether-Lumefantrine (AL)",
        "Quinine IV",
        "Cotrimoxazole",
        "Isoniazid",
        "Rifampicin",
        "ARVs",
        "Albendazole",
        "Praziquantel",
        "Zinc Sulfate",
        "Vitamin A",
        // South/Southeast Asia
        "Artesunate",
        "ACT (Artemisinin Combination)",
        "Azithromycin",
        "Ciprofloxacin",
        "Chloramphenicol",
        "Doxycycline",
        "Primaquine",
        // Latin America
        "Benznidazole",
        "Nifurtimox",
        "Ivermectin",
        "Mebendazol"
    ]

    var body: some View {
        NavigationView {
            Form {
                patientDetailsSection
                triageSection
                subjectiveSection
                objectiveSection
                assessmentSection
                planSection
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
                FieldOptimizedVitalsView(vitalSet: $currentVitals) {
                    if note.objective == nil { note.objective = NoteObjective() }
                    note.objective?.vitals.append(currentVitals)
                    showingVitalsInput = false
                }
            }
        }
    }

    // MARK: - Section Views

    private var patientDetailsSection: some View {
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
    }

    private var triageSection: some View {
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
    }

    private var subjectiveSection: some View {
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
                    MultiSelectGrid(
                        title: "Associated Symptoms",
                        options: symptomOptions,
                        selections: Binding(
                            get: { note.subjective?.associatedSymptoms ?? [] },
                            set: {
                                if note.subjective == nil { note.subjective = NoteSubjective() }
                                note.subjective?.associatedSymptoms = $0
                            }
                        )
                    )
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
                    MultiSelectGrid(
                        title: "Key Risks",
                        options: keyRiskOptions,
                        selections: Binding(
                            get: { note.subjective?.keyRisks ?? [] },
                            set: {
                                if note.subjective == nil { note.subjective = NoteSubjective() }
                                note.subjective?.keyRisks = $0
                            }
                        )
                    )
        }
    }

    private var objectiveSection: some View {
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
                    OrganSystemExamInput(
                        title: "Focused Examination",
                        examFindings: Binding(
                            get: { note.objective?.focusedExam ?? [:] },
                            set: {
                                if note.objective == nil { note.objective = NoteObjective() }
                                note.objective?.focusedExam = $0
                            }
                        )
                    )
                    DynamicListInput(
                        title: "Point-of-Care Tests",
                        items: Binding(
                            get: { note.objective?.pointOfCareTests ?? [] },
                            set: {
                                if note.objective == nil { note.objective = NoteObjective() }
                                note.objective?.pointOfCareTests = $0
                            }
                        ),
                        placeholder: "Add test...",
                        suggestions: testSuggestions
                    )
        }
    }

    private var assessmentSection: some View {
        Section("Assessment") {
                    DynamicListInput(
                        title: "Working Diagnoses",
                        items: Binding(
                            get: { note.assessment?.workingDiagnoses.map { $0.label } ?? [] },
                            set: {
                                if note.assessment == nil { note.assessment = NoteAssessment() }
                                note.assessment?.workingDiagnoses = $0.map { Diagnosis(label: $0, certainty: .possible) }
                            }
                        ),
                        placeholder: "Add diagnosis...",
                        suggestions: []
                    )
                    DynamicListInput(
                        title: "Differentials",
                        items: Binding(
                            get: { note.assessment?.differentials ?? [] },
                            set: {
                                if note.assessment == nil { note.assessment = NoteAssessment() }
                                note.assessment?.differentials = $0
                            }
                        ),
                        placeholder: "Add differential...",
                        suggestions: []
                    )
                    MultiSelectGrid(
                        title: "Red Flags",
                        options: redFlagOptions,
                        selections: Binding(
                            get: { note.assessment?.redFlags ?? [] },
                            set: {
                                if note.assessment == nil { note.assessment = NoteAssessment() }
                                note.assessment?.redFlags = $0
                            }
                        )
                    )
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
    }

    private var planSection: some View {
        Section("Plan") {
                    DynamicListInput(
                        title: "Immediate Actions",
                        items: Binding(
                            get: { note.plan?.immediateActions ?? [] },
                            set: {
                                if note.plan == nil { note.plan = NotePlan() }
                                note.plan?.immediateActions = $0
                            }
                        ),
                        placeholder: "Add action...",
                        suggestions: actionSuggestions
                    )
                    DynamicListInput(
                        title: "Medications Given",
                        items: Binding(
                            get: { note.plan?.medicationsGiven ?? [] },
                            set: {
                                if note.plan == nil { note.plan = NotePlan() }
                                note.plan?.medicationsGiven = $0
                            }
                        ),
                        placeholder: "Add medication...",
                        suggestions: medicationSuggestions
                    )
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

// CaseIterable conformance is now defined in the enum declaration files
