//
//  ModelSetupView.swift
//  MediScribe
//
//  First-run model setup and download interface
//

import SwiftUI
import Foundation

struct ModelSetupView: View {
    @State private var downloadProgress: Double = 0
    @State private var currentFile: String = ""
    @State private var isDownloading = false
    @State private var errorMessage: String?
    @State private var isComplete = false
    @State private var repositoryId: String = "username/mediscribe-medgemma-mlx"

    var body: some View {
        ZStack {
            Color(uiColor: UIColor.systemBackground).ignoresSafeArea()

            VStack(spacing: 24) {
                VStack(spacing: 12) {
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 48))
                        .foregroundColor(.blue)

                    Text("Model Setup Required")
                        .font(.title2)
                        .fontWeight(.bold)

                    Text("MediScribe needs to download the MedGemma AI model for clinical documentation support.")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 20)

                VStack(spacing: 16) {
                    if isComplete {
                        HStack(spacing: 12) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                                .font(.title3)

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Model Ready")
                                    .font(.body)
                                    .fontWeight(.semibold)

                                Text("MediScribe is ready to use")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            Spacer()
                        }
                        .padding(12)
                        .background(Color(.systemGreen).opacity(0.1))
                        .cornerRadius(8)
                    } else if let errorMessage = errorMessage {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 12) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.red)
                                    .font(.title3)

                                Text("Download Error")
                                    .font(.body)
                                    .fontWeight(.semibold)

                                Spacer()
                            }

                            Text(errorMessage)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(3)
                        }
                        .padding(12)
                        .background(Color(.systemRed).opacity(0.1))
                        .cornerRadius(8)
                    } else if isDownloading {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Downloading Model")
                                        .font(.body)
                                        .fontWeight(.semibold)

                                    if !currentFile.isEmpty {
                                        Text(currentFile)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                            .lineLimit(1)
                                    }
                                }

                                Spacer()

                                Text("\(Int(downloadProgress * 100))%")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                            }

                            ProgressView(value: downloadProgress)
                                .tint(.blue)
                        }
                        .padding(12)
                        .background(Color(.systemBlue).opacity(0.1))
                        .cornerRadius(8)
                    } else {
                        VStack(alignment: .leading, spacing: 12) {
                            Label("~10 GB download", systemImage: "internaldrive")
                            Label("30-60 minutes on typical network", systemImage: "wifi")
                            Label("Can be resumed if interrupted", systemImage: "arrow.clockwise")
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }
                }
                .padding(16)
                .background(Color(.systemGray6))
                .cornerRadius(12)

                Spacer()

                // Action buttons
                if isComplete {
                    Button(action: { dismiss() }) {
                        Text("Continue")
                            .frame(maxWidth: .infinity)
                            .padding(12)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                            .fontWeight(.semibold)
                    }
                } else if isDownloading {
                    Button(action: cancelDownload) {
                        Text("Cancel Download")
                            .frame(maxWidth: .infinity)
                            .padding(12)
                            .background(Color(.systemGray4))
                            .foregroundColor(.primary)
                            .cornerRadius(8)
                            .fontWeight(.semibold)
                    }
                } else if errorMessage != nil {
                    VStack(spacing: 12) {
                        Button(action: retryDownload) {
                            Text("Retry Download")
                                .frame(maxWidth: .infinity)
                                .padding(12)
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                                .fontWeight(.semibold)
                        }

                        Button(action: { dismiss() }) {
                            Text("Skip for Now")
                                .frame(maxWidth: .infinity)
                                .padding(12)
                                .background(Color(.systemGray4))
                                .foregroundColor(.primary)
                                .cornerRadius(8)
                                .fontWeight(.semibold)
                        }
                    }
                } else {
                    Button(action: startDownload) {
                        Text("Download Model")
                            .frame(maxWidth: .infinity)
                            .padding(12)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                            .fontWeight(.semibold)
                    }
                }
            }
            .padding(20)
        }
    }

    // MARK: - Actions

    private func startDownload() {
        isDownloading = true
        errorMessage = nil

        let config = HFModelConfig(repositoryId: repositoryId)
        ModelDownloader.shared.configure(with: config)

        let destPath = (NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first ?? "") + "/../MediScribe/models/medgemma-1.5-4b-it-mlx"

        ModelDownloader.shared.downloadModel(
            to: destPath,
            progressCallback: { progress in
                DispatchQueue.main.async {
                    downloadProgress = progress.percentComplete
                    currentFile = progress.fileName
                }
            },
            completion: { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success:
                        isDownloading = false
                        isComplete = true
                    case .failure(let error):
                        isDownloading = false
                        errorMessage = error.localizedDescription
                    }
                }
            }
        )
    }

    private func retryDownload() {
        downloadProgress = 0
        currentFile = ""
        errorMessage = nil
        startDownload()
    }

    private func cancelDownload() {
        ModelDownloader.shared.cancelDownloads()
        isDownloading = false
        downloadProgress = 0
        currentFile = ""
    }

    @Environment(\.dismiss) var dismiss
}

#Preview {
    ModelSetupView()
}
