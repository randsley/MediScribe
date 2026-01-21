import Foundation

/// Objective findings observed by the clinician.
struct NoteObjective: Codable {
    var vitals: [VitalSet] = []
    var focusedExam: [String: [String]] = [:] // e.g., ["respiratory": ["crackles"]]
    var primarySurvey: String? // e.g., ABCDE or AVPU/GCS
    var pointOfCareTests: [String] = []
}

struct VitalSet: Codable, Identifiable {
    var id: UUID = UUID()
    var timestamp: Date = Date()
    var bloodPressure: BloodPressure?
    var heartRate: Int?
    var respiratoryRate: Int?
    var spo2: Int?
    var temperatureCelsius: Double?
    var gcs: Int?
}

struct BloodPressure: Codable {
    var systolic: Int
    var diastolic: Int
}
