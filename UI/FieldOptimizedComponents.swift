//
//  FieldOptimizedComponents.swift
//  MediScribe
//
//  Field-optimized UI components for fast data entry in challenging environments
//

import SwiftUI

// MARK: - Multi-Select Grid

/// Grid-based multi-select component with large, glove-friendly buttons
struct MultiSelectGrid: View {
    let title: String
    let options: [String]
    @Binding var selections: [String]

    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)

            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(options, id: \.self) { option in
                    MultiSelectButton(
                        label: option,
                        isSelected: selections.contains(option),
                        action: {
                            toggleSelection(option)
                        }
                    )
                }
            }
        }
    }

    private func toggleSelection(_ option: String) {
        if selections.contains(option) {
            selections.removeAll { $0 == option }
        } else {
            selections.append(option)
        }
    }
}

/// Individual multi-select button with large touch target
struct MultiSelectButton: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? .green : .gray)
                    .font(.title3)
                Text(label)
                    .font(.body)
                    .foregroundStyle(.primary)
                Spacer()
            }
            .padding()
            .background(isSelected ? Color.green.opacity(0.1) : Color.gray.opacity(0.05))
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Dynamic List Input

/// Dynamic list with add/remove buttons for medications, actions, etc.
struct DynamicListInput: View {
    let title: String
    @Binding var items: [String]
    let placeholder: String
    let suggestions: [String]

    @State private var newItem = ""
    @State private var showingSuggestions = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(title)
                    .font(.headline)
                Spacer()
                Button(action: {
                    showingSuggestions.toggle()
                }) {
                    Image(systemName: "list.bullet.circle")
                        .font(.title3)
                }
            }

            // Existing items
            ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                HStack {
                    Text(item)
                        .padding(.vertical, 8)
                    Spacer()
                    Button(action: {
                        items.remove(at: index)
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

            // Add new item
            HStack {
                TextField(placeholder, text: $newItem)
                    .textFieldStyle(.roundedBorder)
                    .autocapitalization(.none)

                Button(action: addItem) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(.green)
                        .font(.title)
                }
                .disabled(newItem.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }

            // Suggestions
            if showingSuggestions && !suggestions.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Common Items")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(suggestions, id: \.self) { suggestion in
                                Button(suggestion) {
                                    if !items.contains(suggestion) {
                                        items.append(suggestion)
                                    }
                                }
                                .buttonStyle(.bordered)
                                .disabled(items.contains(suggestion))
                            }
                        }
                    }
                }
                .padding(12)
                .background(Color.orange.opacity(0.05))
                .cornerRadius(8)
            }
        }
    }

    private func addItem() {
        let trimmed = newItem.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !items.contains(trimmed) else {
            return
        }
        items.append(trimmed)
        newItem = ""
    }
}

// MARK: - Quick Action Grid

/// Large button grid for quick actions (oxygen, fluids, etc.)
struct QuickActionGrid: View {
    let title: String
    let actions: [QuickAction]
    let onAction: (QuickAction) -> Void

    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)

            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(actions) { action in
                    Button(action: {
                        onAction(action)
                    }) {
                        VStack(spacing: 8) {
                            Image(systemName: action.icon)
                                .font(.largeTitle)
                            Text(action.label)
                                .font(.body)
                                .fontWeight(.semibold)
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 24)
                        .background(action.color)
                        .cornerRadius(12)
                    }
                }
            }
        }
    }
}

struct QuickAction: Identifiable {
    let id = UUID()
    let label: String
    let icon: String
    let color: Color
    let value: String
}

// MARK: - Large Number Pad

/// Extra-large number pad for vitals entry with gloved hands
struct LargeNumberPad: View {
    @Binding var value: String
    let maxDigits: Int
    let allowDecimal: Bool

    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        VStack(spacing: 12) {
            // Display
            Text(value.isEmpty ? "—" : value)
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)

            // Number pad
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(["1", "2", "3", "4", "5", "6", "7", "8", "9"], id: \.self) { digit in
                    numberButton(digit)
                }

                if allowDecimal {
                    numberButton(".")
                }

                numberButton("0")

                Button(action: {
                    if !value.isEmpty {
                        value.removeLast()
                    }
                }) {
                    Image(systemName: "delete.left.fill")
                        .font(.title)
                        .foregroundStyle(.red)
                        .frame(maxWidth: .infinity, minHeight: 60)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                }
            }

            // Clear button
            Button(action: {
                value = ""
            }) {
                Text("Clear")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red)
                    .cornerRadius(8)
            }
        }
    }

    private func numberButton(_ digit: String) -> some View {
        Button(action: {
            appendDigit(digit)
        }) {
            Text(digit)
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity, minHeight: 60)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)
        }
    }

    private func appendDigit(_ digit: String) {
        // Check decimal constraints
        if digit == "." {
            if !allowDecimal || value.contains(".") {
                return
            }
        }

        // Check max digits
        if value.count >= maxDigits {
            return
        }

        value += digit
    }
}

// MARK: - Preset Common Values

/// Common preset values for quick selection
struct PresetValuePicker: View {
    let title: String
    let presets: [String]
    @Binding var selectedValue: String
    let customInputPlaceholder: String

    @State private var showingCustomInput = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)

            // Preset buttons
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(presets, id: \.self) { preset in
                        Button(preset) {
                            selectedValue = preset
                        }
                        .buttonStyle(.bordered)
                        .tint(selectedValue == preset ? .blue : .gray)
                    }

                    Button("Custom...") {
                        showingCustomInput = true
                    }
                    .buttonStyle(.bordered)
                }
            }

            // Selected value display
            if !selectedValue.isEmpty && !presets.contains(selectedValue) {
                Text("Custom: \(selectedValue)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .alert("Enter Custom Value", isPresented: $showingCustomInput) {
            TextField(customInputPlaceholder, text: $selectedValue)
            Button("OK", role: .cancel) { }
        }
    }
}

// MARK: - Preview

#Preview("Multi-Select Grid") {
    MultiSelectGrid(
        title: "Select Symptoms",
        options: ["Fever", "Cough", "Dyspnea", "Fatigue", "Headache", "Nausea"],
        selections: .constant(["Fever", "Cough"])
    )
    .padding()
}

#Preview("Dynamic List") {
    DynamicListInput(
        title: "Medications Given",
        items: .constant(["Paracetamol 500mg PO", "IV Fluids 1L"]),
        placeholder: "Add medication...",
        suggestions: ["Paracetamol 500mg PO", "Ibuprofen 400mg PO", "IV Fluids 1L", "Oxygen 15L NRB"]
    )
    .padding()
}

#Preview("Large Number Pad") {
    LargeNumberPad(
        value: .constant("120"),
        maxDigits: 3,
        allowDecimal: false
    )
    .padding()
}
