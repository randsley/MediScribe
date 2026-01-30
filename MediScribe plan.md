# MediScribe MedGemma-4B Integration Plan

## Project Overview
Integrate Google's MedGemma-4B medical LLM into the MediScribe iOS/iPadOS app for on-device SOAP note generation with HIPAA compliance.

## Approach

### Phase 1: Model Conversion & Setup (Steps 1-3)
1. **Install MLX dependencies** - Set up Python environment with mlx-lm for model conversion
2. **Download and convert MedGemma-4B** - Convert from HuggingFace to MLX format with 4-bit quantization
3. **Validate converted model** - Test model locally on Mac to ensure quality before iOS integration

### Phase 2: Swift MLX Integration (Steps 4-7)
4. **Add MLX-Swift to Xcode project** - Integrate mlx-swift package via SPM
5. **Create model loading infrastructure** - Build model container and resource management
6. **Implement SOAPNoteGenerator class** - Core service for SOAP note generation
7. **Build prompt engineering system** - Create medical prompts with proper structure

### Phase 3: SOAP Note Architecture (Steps 8-10)
8. **Define data models** - Create Swift structs for VitalSigns, PatientContext, SOAPNote
9. **Implement SOAP parser** - Extract structured SOAP sections from LLM output
10. **Add HIPAA-compliant storage** - Encrypted Core Data persistence for generated notes

### Phase 4: UI Integration (Steps 11-13)
11. **Create SOAP generation UI** - SwiftUI views for input collection and note display
12. **Implement streaming generation** - Real-time token streaming with progress indication
13. **Add voice input integration** - Connect existing speech recognition to SOAP generator

### Phase 5: Testing & Optimization (Steps 14-16)
14. **Create medical test cases** - Validate accuracy across common clinical scenarios
15. **Profile memory and performance** - Optimize for iOS/iPadOS constraints
16. **Implement error handling** - Graceful degradation and user feedback

### Phase 6: Production Readiness (Steps 17-18)
17. **Add model versioning** - Support for model updates without app releases
18. **Create documentation** - Developer docs and clinical usage guidelines

## Domains
- github.com (for mlx-swift repository)
- huggingface.co (for MedGemma model download)
- docs.apple.com (for Swift/iOS documentation reference)
- python.org (for MLX installation if needed)

## Key Deliverables
1. Converted MedGemma-4B model in MLX format (~2.5GB)
2. Swift SOAPNoteGenerator service class
3. Complete data model architecture
4. SwiftUI UI components for SOAP generation
5. Test suite with medical scenarios
6. Documentation for medical accuracy validation

## Technical Constraints
- Model must be <3GB for iOS memory limits
- Generation must complete in <10 seconds
- Must work offline (no cloud dependency)
- HIPAA-compliant local storage only
- Support iOS 16+ and iPadOS 16+

## Success Criteria
- SOAP notes generated in <5 seconds on iPhone 15 Pro
- Model accuracy validated against 50+ test cases
- Zero PHI data sent to external servers
- Seamless integration with existing MediScribe voice input
- App bundle size increase <500MB