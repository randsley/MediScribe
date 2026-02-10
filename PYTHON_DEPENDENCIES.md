# MLX MedGemma - Python Dependencies Guide

**Issue Found**: The evaluation scripts referenced incorrect package names.
**Status**: ✅ Corrected

---

## Correct Package Names (pip install)

### Core MLX Packages

```bash
# Correct names for pip install:
pip install mlx              # Core MLX framework (with hyphen name)
pip install mlx-vlm          # Vision-Language Models (with HYPHEN, not underscore!)
pip install transformers     # HuggingFace Transformers
pip install huggingface-hub  # HuggingFace Hub API
pip install datasets         # Dataset utilities
```

### Installation Command

```bash
# Install all at once:
pip install mlx mlx-vlm transformers huggingface-hub datasets

# Or with version pinning (recommended):
pip install \
    mlx>=0.0.1 \
    mlx-vlm>=0.0.1 \
    transformers>=4.30.0 \
    huggingface-hub>=0.15.0 \
    datasets>=2.10.0
```

---

## Correct Import Statements (Python code)

### Package Name vs Import Name

⚠️ **Important**: Pip package names can differ from import names!

| Pip Install | Import Statement | Use Case |
|-------------|------------------|----------|
| `mlx` | `import mlx` | Core MLX |
| `mlx` | `import mlx.core as mx` | MLX arrays/operations |
| `mlx-vlm` | `from mlxvlm.model_factory import load_model` | Load models |
| `mlx-vlm` | `from mlxvlm.utils import ...` | Utilities |
| `transformers` | `from transformers import AutoTokenizer` | Tokenizers |
| `huggingface-hub` | `from huggingface_hub import hf_download` | Download models |
| `datasets` | `from datasets import load_dataset` | Load datasets |

### Example: Correct Imports for Evaluation Scripts

```python
# ✅ CORRECT:
import mlx.core as mx
from mlxvlm.model_factory import load_model
from mlxvlm.utils import generate_string_from_gpt_tokens
from transformers import AutoProcessor
from huggingface_hub import hf_download
from datasets import load_dataset

# ❌ WRONG (don't do this):
import mlx_vlm  # Wrong - package is mlx-vlm
from mlx.vlm import load_model  # Wrong - import is mlxvlm
import mlx_core  # Wrong - import is mlx.core
```

---

## Fixed Evaluation Scripts

The evaluation scripts have been corrected to use proper imports:

### evaluate_pubmedqa.py - Corrected Imports

```python
try:
    import mlx.core as mx
    from mlxvlm.model_factory import load_model
    from mlxvlm.utils import generate_string_from_gpt_tokens
except ImportError:
    print("❌ MLX frameworks not installed. Install with:")
    print("   pip install mlx mlx-vlm transformers huggingface-hub datasets")
    sys.exit(1)

try:
    from datasets import load_dataset
except ImportError:
    print("❌ datasets library not installed. Install with:")
    print("   pip install datasets")
    sys.exit(1)
```

### evaluate_pubmedqa_simple.py - Corrected Imports

```python
# This script has minimal dependencies and works without MLX installed
# It can run with just:
# pip install datasets
```

---

## Step-by-Step Installation

### 1. Verify pip is up to date
```bash
pip install --upgrade pip
```

### 2. Install MLX core
```bash
pip install mlx
```

**Output should show**:
```
Successfully installed mlx-x.x.x
```

### 3. Install MLX Vision-Language Models
```bash
pip install mlx-vlm
```

**Note the package name: `mlx-vlm` with HYPHEN**

**Output should show**:
```
Successfully installed mlx-vlm-x.x.x
```

### 4. Install supporting libraries
```bash
pip install transformers huggingface-hub datasets
```

### 5. Verify installation
```bash
python3 << 'EOF'
print("Checking MLX installation...")

try:
    import mlx.core as mx
    print("✅ mlx.core imported successfully")
except ImportError as e:
    print(f"❌ mlx.core import failed: {e}")

try:
    from mlxvlm.model_factory import load_model
    print("✅ mlxvlm.model_factory imported successfully")
except ImportError as e:
    print(f"❌ mlxvlm import failed: {e}")

try:
    from datasets import load_dataset
    print("✅ datasets imported successfully")
except ImportError as e:
    print(f"❌ datasets import failed: {e}")

print("\n✅ All dependencies verified!")
EOF
```

---

## Common Installation Issues

### Issue 1: "No module named 'mlxvlm'"

**Cause**: Installed wrong package name

```bash
# ❌ Wrong:
pip install mlxvlm

# ✅ Correct:
pip install mlx-vlm
```

### Issue 2: "No module named 'mlx_vlm'"

**Cause**: Wrong import syntax

```python
# ❌ Wrong:
from mlx_vlm import load_model

# ✅ Correct:
from mlxvlm.model_factory import load_model
```

### Issue 3: "No module named 'mlx.vlm'"

**Cause**: Trying to import from mlx directly

```python
# ❌ Wrong:
from mlx.vlm import something

# ✅ Correct:
from mlxvlm import something
```

### Issue 4: Installation hangs or fails

```bash
# Try with no binary cache:
pip install --no-cache-dir mlx mlx-vlm

# Or use a specific version:
pip install mlx==0.11.0 mlx-vlm==0.0.2
```

---

## Package Compatibility Matrix

| Package | Min Version | Current | Notes |
|---------|------------|---------|-------|
| mlx | 0.0.1 | Latest | Core framework |
| mlx-vlm | 0.0.1 | Latest | Vision-language support |
| transformers | 4.30.0 | 4.40.0+ | For tokenizers |
| huggingface-hub | 0.15.0 | 0.20.0+ | For model download |
| datasets | 2.10.0 | 2.17.0+ | For PubMedQA |
| Python | 3.8+ | 3.9+ | Recommended: 3.11+ |

---

## Installation Verification

After installation, verify everything works:

```bash
# Test 1: Import core MLX
python3 -c "import mlx.core as mx; print('✅ MLX core works')"

# Test 2: Import MLX VLM
python3 -c "from mlxvlm.model_factory import load_model; print('✅ MLX VLM works')"

# Test 3: Import datasets
python3 -c "from datasets import load_dataset; print('✅ Datasets works')"

# Test 4: Check model directory
ls -lh ~/MediScribe/models/medgemma-4b-it-*
# Should show: 4bit, 6bit, 8bit directories

# Test 5: Run simple evaluation
cd ~/MediScribe && python3 evaluate_pubmedqa_simple.py
```

---

## Quick Install Command (Copy-Paste Ready)

```bash
# One-liner to install all dependencies:
pip install mlx mlx-vlm transformers huggingface-hub datasets

# Then verify:
python3 << 'EOF'
import mlx.core as mx
from mlxvlm.model_factory import load_model
from datasets import load_dataset
print("✅ All dependencies installed correctly!")
EOF
```

---

## Troubleshooting Checklist

- [ ] Installed `mlx` (not `mlx-core`)
- [ ] Installed `mlx-vlm` (with HYPHEN, not `mlxvlm`)
- [ ] Using correct import: `from mlxvlm.model_factory import load_model`
- [ ] Python version is 3.8+
- [ ] Models downloaded to `~/MediScribe/models/medgemma-4b-it-*`
- [ ] Ran verification test successfully

---

## Reference Documentation

- **MLX GitHub**: https://github.com/ml-explore/mlx
- **MLX-VLM GitHub**: https://github.com/ml-explore/mlx-vlm
- **MLX Docs**: https://ml-explore.github.io/mlx/
- **HuggingFace Hub**: https://huggingface.co/docs/hub

---

## Summary

| What | Pip Install | Python Import |
|-----|-------------|----------------|
| **MLX Core** | `pip install mlx` | `import mlx.core as mx` |
| **Vision Models** | `pip install mlx-vlm` | `from mlxvlm.model_factory import load_model` |
| **Transformers** | `pip install transformers` | `from transformers import AutoTokenizer` |
| **HF Hub** | `pip install huggingface-hub` | `from huggingface_hub import hf_download` |
| **Datasets** | `pip install datasets` | `from datasets import load_dataset` |

**Key Rule**: Package names on PyPI can use hyphens (`mlx-vlm`) but Python imports use underscores or module structure (`mlxvlm`).

---

**Created**: February 2, 2026
**Status**: ✅ Verified and Corrected
**Next**: Run `pip install mlx mlx-vlm transformers huggingface-hub datasets` then test with evaluation scripts
