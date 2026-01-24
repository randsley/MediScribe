//
//  AppSettings.swift
//  MediScribe
//
//  Application-wide settings for clinician and facility information
//

import Foundation
import Combine

struct ClinicianInfo: Codable {
    var name: String = ""
    var credentials: String = ""
    var licenseNumber: String = ""
    var signature: String = ""  // Base64-encoded signature image
}

struct FacilityInfo: Codable {
    var name: String = ""
    var location: String = ""
    var phoneNumber: String = ""
    var email: String = ""
}

class AppSettings: ObservableObject {
    static let shared = AppSettings()

    @Published var clinicianInfo: ClinicianInfo {
        didSet {
            saveClinician()
        }
    }

    @Published var facilityInfo: FacilityInfo {
        didSet {
            saveFacility()
        }
    }

    private let clinicianKey = "mediscribe.clinician"
    private let facilityKey = "mediscribe.facility"

    init() {
        // Load from UserDefaults
        if let clinicianData = UserDefaults.standard.data(forKey: clinicianKey) {
            self.clinicianInfo = (try? JSONDecoder().decode(ClinicianInfo.self, from: clinicianData)) ?? ClinicianInfo()
        } else {
            self.clinicianInfo = ClinicianInfo()
        }

        if let facilityData = UserDefaults.standard.data(forKey: facilityKey) {
            self.facilityInfo = (try? JSONDecoder().decode(FacilityInfo.self, from: facilityData)) ?? FacilityInfo()
        } else {
            self.facilityInfo = FacilityInfo()
        }
    }

    private func saveClinician() {
        if let encoded = try? JSONEncoder().encode(clinicianInfo) {
            UserDefaults.standard.set(encoded, forKey: clinicianKey)
        }
    }

    private func saveFacility() {
        if let encoded = try? JSONEncoder().encode(facilityInfo) {
            UserDefaults.standard.set(encoded, forKey: facilityKey)
        }
    }

    var clinicianName: String {
        clinicianInfo.name.isEmpty ? "Unknown Clinician" : clinicianInfo.name
    }

    var facilityName: String {
        facilityInfo.name.isEmpty ? "Unknown Facility" : facilityInfo.name
    }
}
