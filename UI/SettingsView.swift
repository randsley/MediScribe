import SwiftUI

struct SettingsView: View {
    @StateObject private var appSettings = AppSettings.shared
    @State private var showingClinicianEdit = false
    @State private var showingFacilityEdit = false
    @State private var showingDataExport = false

    var body: some View {
        NavigationStack {
            Form {
                // MARK: - Clinician Profile
                Section("Clinician Profile") {
                    NavigationLink(destination: ClinicianEditView(appSettings: appSettings)) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(appSettings.clinicianName)
                                .font(.headline)
                            if !appSettings.clinicianInfo.credentials.isEmpty {
                                Text(appSettings.clinicianInfo.credentials)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            if !appSettings.clinicianInfo.licenseNumber.isEmpty {
                                Text("License: \(appSettings.clinicianInfo.licenseNumber)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }

                // MARK: - Facility Information
                Section("Facility Information") {
                    NavigationLink(destination: FacilityEditView(appSettings: appSettings)) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(appSettings.facilityName)
                                .font(.headline)
                            if !appSettings.facilityInfo.location.isEmpty {
                                Text(appSettings.facilityInfo.location)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            if !appSettings.facilityInfo.phoneNumber.isEmpty || !appSettings.facilityInfo.email.isEmpty {
                                HStack(spacing: 8) {
                                    if !appSettings.facilityInfo.phoneNumber.isEmpty {
                                        Text(appSettings.facilityInfo.phoneNumber)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    if !appSettings.facilityInfo.email.isEmpty {
                                        Text(appSettings.facilityInfo.email)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }

                // MARK: - Data Management
                Section("Data Management") {
                    NavigationLink(destination: DataExportView()) {
                        HStack {
                            Image(systemName: "arrow.up.doc")
                            Text("Export Data")
                        }
                    }

                    NavigationLink(destination: EncryptionStatusView()) {
                        HStack {
                            Image(systemName: "lock.shield")
                            Text("Encryption Status")
                        }
                    }

                    NavigationLink(destination: PrivacyView()) {
                        HStack {
                            Image(systemName: "hand.raised.shield")
                            Text("Privacy & Security")
                        }
                    }
                }

                // MARK: - About & Support
                Section("About") {
                    HStack {
                        Text("App Version")
                        Spacer()
                        Text(appVersion)
                            .foregroundColor(.secondary)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("MediScribe")
                            .font(.headline)
                        Text("Clinical documentation support software for offline, resource-constrained healthcare settings.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)

                    NavigationLink(destination: SafetyLimitationsView()) {
                        HStack {
                            Image(systemName: "exclamationmark.triangle")
                            Text("Safety Limitations")
                        }
                    }

                    NavigationLink(destination: DocumentationView()) {
                        HStack {
                            Image(systemName: "book")
                            Text("Documentation")
                        }
                    }

                    NavigationLink(destination: LicenseView()) {
                        HStack {
                            Image(systemName: "doc.text")
                            Text("License & Credits")
                        }
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }

    private var appVersion: String {
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
           let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
            return "\(version) (\(build))"
        }
        return "1.0"
    }
}

// MARK: - Clinician Edit View
struct ClinicianEditView: View {
    @ObservedObject var appSettings: AppSettings
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Form {
            Section("Clinician Information") {
                TextField("Full Name", text: $appSettings.clinicianInfo.name)
                TextField("Credentials (MD, RN, etc.)", text: $appSettings.clinicianInfo.credentials)
                TextField("License Number", text: $appSettings.clinicianInfo.licenseNumber)
            }

            Section("About") {
                Text("This information will appear on signed documents and referrals to identify the clinician responsible for the care.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .navigationTitle("Edit Clinician Profile")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Facility Edit View
struct FacilityEditView: View {
    @ObservedObject var appSettings: AppSettings
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Form {
            Section("Facility Information") {
                TextField("Facility Name", text: $appSettings.facilityInfo.name)
                TextField("Location / Address", text: $appSettings.facilityInfo.location)
                TextField("Phone Number", text: $appSettings.facilityInfo.phoneNumber)
                    .keyboardType(.phonePad)
                TextField("Email Address", text: $appSettings.facilityInfo.email)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
            }

            Section("About") {
                Text("This information will appear on referral documents and exported records to identify the originating facility.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .navigationTitle("Edit Facility Information")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Data Export View
struct DataExportView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var isExporting = false

    var body: some View {
        Form {
            Section("Export Options") {
                Button(action: exportAllData) {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                        Text("Export All Data")
                            .fontWeight(.semibold)
                    }
                }
                .disabled(isExporting)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Exports all notes, imaging findings, lab results, and referrals as encrypted JSON files.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("Files can be saved to your device or shared securely.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 4)
            }

            Section("Exported Data Format") {
                HStack {
                    Image(systemName: "lock.shield.fill")
                        .foregroundColor(.green)
                    Text("AES-256-GCM Encrypted")
                }

                HStack {
                    Image(systemName: "iphone.homebutton")
                        .foregroundColor(.blue)
                    Text("Local Storage Only")
                }

                HStack {
                    Image(systemName: "square.stack")
                        .foregroundColor(.orange)
                    Text("JSON Format")
                }
            }

            Section("Privacy") {
                Text("All exported data remains encrypted. The encryption key is stored securely on this device only.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .navigationTitle("Export Data")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Export Status", isPresented: $showingAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
    }

    private func exportAllData() {
        isExporting = true
        alertMessage = "Data export feature coming soon. For now, use device backup or iCloud sync."
        showingAlert = true
        isExporting = false
    }
}

// MARK: - Encryption Status View
struct EncryptionStatusView: View {
    var body: some View {
        Form {
            Section("Encryption Status") {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Encryption Enabled")
                            .fontWeight(.semibold)
                        Text("AES-256-GCM")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

            Section("Protected Data") {
                HStack {
                    Image(systemName: "doc.text")
                        .foregroundColor(.blue)
                    Text("Clinical Notes")
                }

                HStack {
                    Image(systemName: "photo")
                        .foregroundColor(.blue)
                    Text("Imaging Findings")
                }

                HStack {
                    Image(systemName: "chart.bar")
                        .foregroundColor(.blue)
                    Text("Lab Results")
                }

                HStack {
                    Image(systemName: "arrow.up.doc")
                        .foregroundColor(.blue)
                    Text("Referrals")
                }
            }

            Section("About Encryption") {
                Text("All sensitive clinical data (notes, images, lab results, and referrals) is encrypted using AES-256-GCM. Encryption keys are managed by iOS Keychain and never leave this device.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .navigationTitle("Encryption Status")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Privacy View
struct PrivacyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Privacy & Security")
                    .font(.title2)
                    .bold()
                    .padding(.horizontal)

                VStack(alignment: .leading, spacing: 12) {
                    privacySection(icon: "lock.shield", title: "End-to-End Encryption", description: "All patient data is encrypted with AES-256-GCM encryption on your device. Encryption keys never leave this device.")

                    privacySection(icon: "network.slash", title: "Offline by Design", description: "MediScribe works entirely offline. No data is sent to external servers or cloud services.")

                    privacySection(icon: "hand.raised.shield", title: "Local Storage Only", description: "All data is stored locally on your iOS device. You control when and how data is backed up.")

                    privacySection(icon: "lock", title: "Secure Key Management", description: "Encryption keys are stored in iOS Keychain, Apple's secure credential storage system.")

                    privacySection(icon: "eye.slash", title: "Privacy by Default", description: "MediScribe collects no telemetry, usage data, or analytics. No tracking of any kind.")
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .navigationTitle("Privacy & Security")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func privacySection(icon: String, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .font(.title3)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .fontWeight(.semibold)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Safety Limitations View
struct SafetyLimitationsView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Safety Limitations")
                    .font(.title2)
                    .bold()
                    .padding(.horizontal)

                VStack(alignment: .leading, spacing: 12) {
                    warningBox(
                        title: "NOT for Clinical Decision-Making",
                        description: "MediScribe does not provide diagnoses, assess disease likelihood, or recommend treatments. All output is descriptive only."
                    )

                    warningBox(
                        title: "Requires Clinician Review",
                        description: "All AI-generated content must be reviewed and approved by a qualified clinician before use in patient care."
                    )

                    warningBox(
                        title: "Documentation Support Only",
                        description: "MediScribe assists with documentation. Clinical responsibility remains entirely with the licensed healthcare provider."
                    )

                    warningBox(
                        title: "No Emergency Use",
                        description: "Do not use MediScribe in acute emergencies. This is a documentation tool, not a clinical decision support system."
                    )

                    warningBox(
                        title: "Offline Operation",
                        description: "MediScribe works offline only. It cannot access external lab systems, imaging systems, or patient registries."
                    )
                }
                .padding(.horizontal)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Required User Competencies")
                        .font(.headline)
                        .padding(.horizontal)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("• Licensed healthcare professional in your jurisdiction")
                        Text("• Operating within scope of practice")
                        Text("• Capable of reviewing and editing generated content")
                        Text("• Responsible for all clinical decisions")
                    }
                    .font(.caption)
                    .padding()
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(8)
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
        .navigationTitle("Safety Limitations")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func warningBox(title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.orange)
                .font(.title3)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .fontWeight(.semibold)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color.orange.opacity(0.05))
        .cornerRadius(8)
    }
}

// MARK: - Documentation View
struct DocumentationView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Documentation & Resources")
                    .font(.title2)
                    .bold()
                    .padding(.horizontal)

                VStack(alignment: .leading, spacing: 12) {
                    docSection(
                        icon: "doc.text",
                        title: "User Guide",
                        description: "Learn how to use MediScribe features including notes, imaging, labs, and referrals."
                    )

                    docSection(
                        icon: "book",
                        title: "Clinical Best Practices",
                        description: "Guidelines for appropriate use in clinical workflow and documentation standards."
                    )

                    docSection(
                        icon: "globe",
                        title: "Regulatory Information",
                        description: "Information about regulatory status, compliance, and deployment guidance."
                    )

                    docSection(
                        icon: "envelope",
                        title: "Support Contact",
                        description: "technical-support@mediscribe.org"
                    )
                }
                .padding(.horizontal)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Deployment Environments")
                        .font(.headline)
                        .padding(.horizontal)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("✓ NGO-run clinics")
                        Text("✓ Rural health posts")
                        Text("✓ Mobile outreach programs")
                        Text("✓ Humanitarian medical missions")
                        Text("✓ Low-resource settings")
                    }
                    .font(.caption)
                    .padding()
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(8)
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
        .navigationTitle("Documentation")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func docSection(icon: String, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .font(.title3)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .fontWeight(.semibold)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - License View
struct LicenseView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("License & Credits")
                    .font(.title2)
                    .bold()
                    .padding(.horizontal)

                VStack(alignment: .leading, spacing: 12) {
                    creditSection(
                        title: "MediScribe",
                        component: "Application",
                        license: "MIT License"
                    )

                    creditSection(
                        title: "Google MedGemma",
                        component: "Medical Language Model (1.5-4B)",
                        license: "Apache 2.0"
                    )

                    creditSection(
                        title: "MLX Framework",
                        component: "Apple Silicon Model Inference Engine",
                        license: "Apache 2.0"
                    )

                    creditSection(
                        title: "SwiftUI & Core Data",
                        component: "Apple Frameworks",
                        license: "Apple License"
                    )
                }
                .padding(.horizontal)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Open Source Acknowledgements")
                        .font(.headline)
                        .padding(.horizontal)

                    Text("MediScribe is built on excellent open-source software. We are grateful to the communities and developers who make healthcare technology accessible and transparent.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                        .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
        .navigationTitle("License & Credits")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func creditSection(title: String, component: String, license: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .fontWeight(.semibold)
            Text(component)
                .font(.caption)
                .foregroundColor(.secondary)
            HStack {
                Image(systemName: "doc.plaintext")
                    .font(.caption2)
                Text(license)
                    .font(.caption2)
            }
            .foregroundColor(.blue)
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(8)
    }
}

#Preview {
    SettingsView()
}
