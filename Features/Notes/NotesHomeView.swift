import SwiftUI
import CoreData

struct NotesHomeView: View {
    @State private var selectedSegment: NoteSegment = .soap

    enum NoteSegment: String, CaseIterable {
        case soap = "SOAP Notes"
        case field = "Field Notes"
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("Note type", selection: $selectedSegment) {
                    ForEach(NoteSegment.allCases, id: \.self) { segment in
                        Text(segment.rawValue).tag(segment)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.vertical, 8)

                Divider()

                switch selectedSegment {
                case .soap:
                    SOAPNoteListView()
                        .navigationTitle("Notes")
                case .field:
                    FieldNotesListView()
                        .navigationTitle("Notes")
                }
            }
            .navigationTitle("Notes")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - Field Notes List (existing SBAR workflow)

private struct FieldNotesListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Note.createdAt, ascending: false)],
        animation: .default)
    private var notes: FetchedResults<Note>

    @State private var showingNoteEditor = false
    @State private var selectedNote: FieldNote?
    @State private var selectedNoteEntity: Note?
    @State private var newNote: FieldNote = FieldNote(
        meta: NoteMeta(
            author: NoteAuthor(id: "default_clinician", displayName: "Default Clinician", role: "Unknown"),
            patient: NotePatient(id: "New Patient"),
            encounter: NoteEncounter(setting: .roadside),
            consent: NoteConsent(status: .notPossible)
        )
    )

    var body: some View {
        List {
            ForEach(notes) { noteEntity in
                HStack {
                    VStack(alignment: .leading) {
                        Text("Patient ID: \(noteEntity.patientID ?? "N/A")")
                            .font(.headline)
                        Text("Created: \(noteEntity.createdAt ?? Date(), formatter: itemFormatter)")
                            .font(.subheadline)
                    }

                    Spacer()

                    NavigationLink(destination: NoteDetailView(noteEntity: noteEntity)) {
                        Image(systemName: "info.circle")
                            .foregroundStyle(.blue)
                    }
                    .buttonStyle(.borderless)

                    if !noteEntity.isLocked {
                        Button(action: {
                            do {
                                selectedNote = try noteEntity.getFieldNoteWithMigration()
                                selectedNoteEntity = noteEntity
                                showingNoteEditor = true
                            } catch {
                                print("Failed to decrypt/decode FieldNote: \(error.localizedDescription)")
                            }
                        }) {
                            Image(systemName: "square.and.pencil")
                                .foregroundStyle(.orange)
                        }
                        .buttonStyle(.borderless)
                    }

                    if let fieldNote = try? noteEntity.getFieldNoteWithMigration() {
                        NavigationLink(destination: SBARView(note: fieldNote)) {
                            Image(systemName: "doc.text.fill")
                                .foregroundStyle(.green)
                        }
                        .buttonStyle(.borderless)
                    }
                }
            }
            .onDelete(perform: deleteItems)
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                EditButton()
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    newNote = FieldNote(
                        meta: NoteMeta(
                            author: NoteAuthor(id: "default_clinician", displayName: "Default Clinician", role: "Unknown"),
                            patient: NotePatient(id: "New Patient"),
                            encounter: NoteEncounter(setting: .roadside),
                            consent: NoteConsent(status: .notPossible)
                        )
                    )
                    selectedNote = nil
                    selectedNoteEntity = nil
                    showingNoteEditor = true
                }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                }
            }
        }
        .sheet(isPresented: $showingNoteEditor) {
            NoteEditorView(
                note: Binding(
                    get: { selectedNote ?? newNote },
                    set: {
                        if selectedNote != nil {
                            selectedNote = $0
                        } else {
                            newNote = $0
                        }
                    }
                ),
                existingNoteEntity: selectedNoteEntity
            )
        }
    }

    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            offsets.map { notes[$0] }.forEach(viewContext.delete)
            do {
                try viewContext.save()
            } catch {
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
}

private let itemFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .medium
    return formatter
}()
