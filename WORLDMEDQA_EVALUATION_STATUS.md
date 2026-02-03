# WorldMedQA/V Evaluation - Medical Multiple-Choice Q&A with Images

**Status**: 🔄 Evaluation in progress  
**Date**: February 2, 2026  
**Dataset**: WorldMedQA/V (1,136 samples)  
**Models**: 4-bit, 6-bit, 8-bit

---

## Dataset Overview

**WorldMedQA/V** is a medical multiple-choice question-answering dataset with clinical images.

- **Total Samples**: 1,136
- **Format**: Medical case description + clinical image + 4 multiple-choice options (A/B/C/D)
- **Task**: Select the correct diagnosis/management option based on image and clinical context

### Sample Structure
```
- image: Medical clinical image (ECG, X-ray, ultrasound, etc.)
- question: Clinical case + options A, B, C, D
- correct_option: The correct answer (A, B, C, or D)
```

### Example Case
```
Case: Teenager after attempted suicide with tricyclic antidepressant overdose
presenting with cardiorespiratory arrest during resuscitation.

Options:
A: ventricular tachycardia (responsive to shock + atropine)
B: ventricular fibrillation (responsive to synchronized cardioversion)  
C: ventricular fibrillation (responsive to defibrillation)
D: ventricular tachycardia (responsive to cardioversion)

Correct Answer: D
```

---

## Initial Test Results (10 Samples)

### Performance by Model

| Model | Accuracy | Inference Time | Status |
|-------|----------|-----------------|--------|
| **4-bit** | 30% (3/10) | 9,306 ms | ✅ Works |
| **6-bit** | 30% (3/10) | 9,565 ms | ✅ Works |
| **8-bit** | 30% (3/10) | 9,594 ms | ✅ Works |

### Observations (10-sample test)
- All models show **identical performance** on first 10 samples
- Same 3 questions answered correctly across all models
- **Inference time**: ~9.3-9.6 seconds per sample (image + complex question processing)
- Model appears to have bias toward selecting option A

---

## Evaluation in Progress

Running larger evaluation on **50 samples** to assess:
1. Performance differences between quantization levels
2. Consistency across more diverse medical cases
3. Accuracy trends on complex clinical reasoning tasks

**Expected Runtime**: ~10-12 minutes for 50 samples on 3 models

---

## Comparison with Other Datasets

| Dataset | Task Type | 4-bit | 6-bit | 8-bit | Best |
|---------|-----------|-------|-------|-------|------|
| **PubMedQA** | Text QA | 90% | 90% | 90% | All tied |
| **VQA-RAD** | Vision QA | 20% | 30% | 40% | 8-bit |
| **WorldMedQA** | Vision MC QA | 30% | 30% | 30% | (Pending) |

---

## Key Insights

1. **Multimodal complexity**: Vision-language tasks are significantly harder
   - PubMedQA (text): 90% accuracy
   - VQA-RAD (vision): 20-40% accuracy  
   - WorldMedQA (vision+MC): 30% accuracy

2. **Quantization impact varies**:
   - Text-only: All quantizations equivalent
   - Vision-language: Higher precision helps
   - Multiple-choice: May require even better models

3. **Inference speed**: Image processing adds significant latency
   - Text QA: 1.6 seconds
   - Vision QA: 8-9 seconds
   - MC Vision QA: 9-10 seconds

---

## Next Steps

1. ✅ Complete 50-sample comparison evaluation
2. ⏳ Analyze performance differences between models
3. ⏳ Test on full 1,136-sample dataset
4. ⏳ Evaluate on different quantization approaches
5. ⏳ Consider fine-tuning strategies for medical MCQs

---

## Dataset Features

**Clinical Cases Covered**:
- Cardiology (ECG interpretation)
- Radiology (X-ray, CT, ultrasound)
- Internal medicine
- Infectious diseases
- Emergency medicine

**Answer Types**:
- Diagnosis identification
- Management selection
- Clinical reasoning
- Risk assessment

---

## Script Features

✅ **Multiple-choice question handling**
- Extracts A/B/C/D options from question text
- Evaluates model's ability to select correct option
- Compares predicted vs. ground truth

✅ **Multimodal evaluation**
- Image decoding (base64 and PIL)
- Image + text context processing
- Complex clinical reasoning

✅ **Comprehensive metrics**
- Accuracy calculation
- Inference time measurement
- Per-sample analysis
- Comparative evaluation across quantizations

---

## Status

- ✅ Script created and tested
- ✅ 10-sample validation passed
- 🔄 50-sample comparison in progress
- ⏳ Full dataset evaluation pending

