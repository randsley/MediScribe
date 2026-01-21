import SwiftUI
import CoreData

struct NotesHomeView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Note.createdAt, ascending: false)],
        animation: .default)
    private var notes: FetchedResults<Note>

    @State private var showingNoteEditor = false
    @State private var selectedNote: FieldNote? // For editing existing notes
    @State private var selectedNoteEntity: Note? // Track the Core Data entity being edited
    @State private var newNote: FieldNote = FieldNote( // For creating new notes
        meta: NoteMeta(
            author: NoteAuthor(id: "default_clinician", displayName: "Default Clinician", role: "Unknown"),
            patient: NotePatient(id: "New Patient"),
            encounter: NoteEncounter(setting: .roadside),
            consent: NoteConsent(status: .notPossible)
        )
    )

    var body: some View {
        NavigationStack {
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

                        // Detail view button
                        NavigationLink(destination: NoteDetailView(noteEntity: noteEntity)) {
                            Image(systemName: "info.circle")
                                .foregroundStyle(.blue)
                        }
                        .buttonStyle(.borderless)

                        // Edit button (only if note is not locked)
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

                        // SBAR button
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
            .navigationTitle("Notes")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        // Initialize a new note with default values for meta
                        newNote = FieldNote(
                            meta: NoteMeta(
                                author: NoteAuthor(id: "default_clinician", displayName: "Default Clinician", role: "Unknown"),
                                patient: NotePatient(id: "New Patient"),
                                encounter: NoteEncounter(setting: .roadside),
                                consent: NoteConsent(status: .notPossible)
                            )
                        )
                        selectedNote = nil // Ensure we're creating a new one
                        selectedNoteEntity = nil // No existing entity
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
