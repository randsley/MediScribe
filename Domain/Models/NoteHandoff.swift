import Foundation

/// Contains data structured for a handoff report, such as SBAR.
/// Note: SBAR struct is defined in Domain/Services/SBARGenerator.swift
struct NoteHandoff: Codable {
    var sbar: SBAR?
}
