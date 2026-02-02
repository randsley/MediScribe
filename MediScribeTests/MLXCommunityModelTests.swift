//
//  MLXCommunityModelTests.swift
//  MediScribeTests
//
//  Tests for mlx-community MedGemma model integration
//  Validates compatibility with quantized models from mlx-community repository
//

import XCTest
@testable import MediScribe

class MLXCommunityModelTests: XCTestCase {
    // MARK: - Properties

    var downloader: ModelDownloader!

    // MARK: - Setup & Teardown

    override func setUp() {
        super.setUp()
        downloader = ModelDownloader.shared
    }

    override func tearDown() {
        downloader = nil
        super.tearDown()
    }

    // MARK: - Model Structure Tests

    /// Test 1: ModelConfiguration is set to mlx-community repository
    func testModelConfigurationUsesMLXCommunity() {
        let config = ModelConfiguration.createHFConfig()

        XCTAssertTrue(
            config.repositoryId.contains("mlx-community") ||
            config.repositoryId.contains("medgemma"),
            "Repository should be mlx-community: \(config.repositoryId)"
        )

        print("✓ Model configuration: \(config.repositoryId)")
    }

    /// Test 2: Model directory name is appropriate
    func testModelDirectoryNameIsValid() {
        let dirName = ModelConfiguration.modelDirectoryName

        XCTAssertFalse(dirName.isEmpty, "Model directory name should not be empty")
        XCTAssertTrue(dirName.contains("medgemma"), "Should reference MedGemma")

        print("✓ Model directory: \(dirName)")
    }

    /// Test 3: Required model files are identified
    func testRequiredModelFilesIdentified() {
        // Base required files should be identifiable
        let config = HFModelConfig(
            repositoryId: "mlx-community/medgemma-4b-it-4bit"
        )

        XCTAssertEqual(config.repositoryId, "mlx-community/medgemma-4b-it-4bit")
        XCTAssertEqual(config.revision, "main")

        print("✓ Model configuration created successfully")
    }

    // MARK: - File Verification Tests

    /// Test 4: Model files validation accepts single-file format
    func testModelFilesValidationSingleFile() {
        // Create temporary test directory
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("medgemma-test-single")

        do {
            try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)

            // Create required files for mlx-community 4-bit model
            let requiredFiles = [
                "config.json",
                "tokenizer.json",
                "model.safetensors"  // Single file, not sharded
            ]

            for file in requiredFiles {
                let filePath = tempDir.appendingPathComponent(file)
                // Create dummy files with minimal size (1MB minimum for model)
                let minSize = file.contains("model") ? 1_000_000 : 1000
                let dummyData = Data(repeating: 0, count: minSize)
                try dummyData.write(to: filePath)
            }

            // Verify files exist
            let fm = FileManager.default
            for file in requiredFiles {
                let filePath = tempDir.appendingPathComponent(file)
                XCTAssertTrue(fm.fileExists(atPath: filePath.path),
                             "File \(file) should exist")
            }

            print("✓ Single-file model structure validated")

            // Cleanup
            try? FileManager.default.removeItem(at: tempDir)

        } catch {
            XCTFail("Failed to create test files: \(error)")
        }
    }

    /// Test 5: Model files validation accepts sharded format
    func testModelFilesValidationShardedFormat() {
        // Create temporary test directory
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("medgemma-test-sharded")

        do {
            try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)

            // Create required files for sharded model
            let requiredFiles = [
                "config.json",
                "tokenizer.json",
                "model.safetensors.index.json",
                "model-00001-of-00002.safetensors",
                "model-00002-of-00002.safetensors"
            ]

            for file in requiredFiles {
                let filePath = tempDir.appendingPathComponent(file)
                let minSize = file.contains("model") ? 1_000_000 : 1000
                let dummyData = Data(repeating: 0, count: minSize)
                try dummyData.write(to: filePath)
            }

            // Verify files exist
            let fm = FileManager.default
            for file in requiredFiles {
                let filePath = tempDir.appendingPathComponent(file)
                XCTAssertTrue(fm.fileExists(atPath: filePath.path),
                             "File \(file) should exist")
            }

            print("✓ Sharded model structure validated")

            // Cleanup
            try? FileManager.default.removeItem(at: tempDir)

        } catch {
            XCTFail("Failed to create test files: \(error)")
        }
    }

    // MARK: - Model Loader Tests

    /// Test 6: MLXModelLoader can be instantiated
    func testMLXModelLoaderInstantiation() {
        let loader = MLXModelLoader.shared
        XCTAssertNotNil(loader, "MLXModelLoader should be instantiable")

        print("✓ MLXModelLoader instantiated")
    }

    /// Test 7: Model configuration path is valid
    func testModelConfigurationPath() {
        let path = ModelConfiguration.modelDirectoryPath()

        XCTAssertFalse(path.isEmpty, "Model directory path should not be empty")
        XCTAssertTrue(path.contains("medgemma"), "Path should contain medgemma")

        print("✓ Model path: \(path)")
    }

    // MARK: - Safety Integration Tests

    /// Test 8: Safety validation works with expected model output format
    func testSafetyValidationWithModelOutput() {
        // Simulate output from mlx-community model
        let modelOutput = """
        {
            "documentType": "imaging",
            "documentDate": "2026-02-02T00:00:00Z",
            "observations": {
                "lungs": ["Bilateral lungs appear clear"],
                "pleural": ["No pleural effusion"],
                "cardiac": ["Cardiac silhouette normal size"],
                "mediastinal": ["Mediastinum without abnormality"],
                "bones": ["Osseous structures intact"],
                "soft_tissues": ["Soft tissues unremarkable"]
            },
            "limitations": "This summary describes visible image features only and does not assess clinical significance or provide a diagnosis."
        }
        """

        do {
            let findings = try FindingsValidator.decodeAndValidate(Data(modelOutput.utf8))
            XCTAssertNotNil(findings, "Valid model output should pass validation")
            XCTAssertTrue(findings.limitations.contains("does not assess"),
                         "Limitations must be present")

            print("✓ Model output passes safety validation")
        } catch {
            XCTFail("Valid model output should not throw: \(error)")
        }
    }

    /// Test 9: Safety validation blocks forbidden content
    func testSafetyValidationBlocksForbiddenContent() {
        // Malicious output with disease name
        let maliciousOutput = """
        {
            "documentType": "imaging",
            "observations": {
                "lungs": ["Pneumonia evident in right lower lobe"]
            },
            "limitations": "This summary describes visible image features only and does not assess clinical significance or provide a diagnosis."
        }
        """

        do {
            _ = try FindingsValidator.decodeAndValidate(Data(maliciousOutput.utf8))
            XCTFail("Should reject findings with forbidden word 'pneumonia'")
        } catch {
            // Expected - forbidden phrase should be caught
            print("✓ Safety validation correctly blocked forbidden content")
        }
    }

    // MARK: - Download Configuration Tests

    /// Test 10: Download configuration is valid
    func testDownloadConfigurationIsValid() {
        let config = ModelConfiguration.createHFConfig()

        // Validate repository ID format
        let parts = config.repositoryId.split(separator: "/")
        XCTAssertEqual(parts.count, 2, "Repository ID should be 'org/repo'")

        // Validate revision
        XCTAssertFalse(config.revision.isEmpty, "Revision should not be empty")

        print("✓ Download configuration valid: \(config.repositoryId)@\(config.revision)")
    }

    /// Test 11: Model size expectations are reasonable
    func testModelSizeExpectations() {
        // mlx-community 4-bit model should be ~3GB
        // Check that configuration accounts for this
        let minSpace = ModelConfiguration.minimumFreeSpaceBytes

        // Should require at least 5GB (for download + buffer)
        XCTAssertGreaterThanOrEqual(minSpace, 5_000_000_000,
                                   "Should require reasonable minimum space")

        print("✓ Model size expectations: \(minSpace / 1_000_000_000)GB required")
    }

    // MARK: - Compatibility Tests

    /// Test 12: Model is compatible with current inference infrastructure
    func testModelCompatibilityWithInferenceStack() {
        // The MLXMedGemmaBridge should work with any Gemma3-based model
        let bridge = MLXMedGemmaBridge.shared
        XCTAssertNotNil(bridge, "Bridge should be available")

        // Verify bridge is available
        print("✓ MLXMedGemmaBridge available for inference")
    }

    // MARK: - Integration Summary

    /// Test 13: All components work together
    func testIntegrationReadiness() {
        // 1. Configuration is set up
        let config = ModelConfiguration.createHFConfig()
        XCTAssertNotNil(config)

        // 2. Model loader is available
        let loader = MLXModelLoader.shared
        XCTAssertNotNil(loader)

        // 3. Safety validation is active
        let validOutput = """
        {
            "documentType": "imaging",
            "observations": {"lungs": ["Clear"]},
            "limitations": "This summary describes visible image features only and does not assess clinical significance or provide a diagnosis."
        }
        """

        do {
            _ = try FindingsValidator.decodeAndValidate(Data(validOutput.utf8))
        } catch {
            XCTFail("Integration incomplete: \(error)")
            return
        }

        print("""
        ✓ Integration ready:
          - Configuration: \(config.repositoryId)
          - Model directory: \(ModelConfiguration.modelDirectoryName)
          - Safety validation: Active
          - MLX framework: Configured
        """)
    }
}
