# HuggingFace Hub Package - Correct Names & Functions

## Package Name Reference

### Pip Installation vs Python Import

| Purpose | Pip Install | Python Import | Current Version |
|---------|------------|---------------|-----------------|
| HF Hub API | `huggingface-hub` | `import huggingface_hub` | 1.3.5+ |

⚠️ **KEY**: Pip uses **HYPHEN** (`huggingface-hub`), Python uses **UNDERSCORE** (`huggingface_hub`)

### Installation Command

```bash
# ✅ CORRECT - Use hyphen for pip:
pip install huggingface-hub

# ✅ Also correct (pip accepts both):
pip install "huggingface-hub>=0.15.0"

# ❌ WRONG - Don't use underscore for pip:
pip install huggingface_hub    # This won't work!
```

---

## Correct Import Statements

### Valid Imports

```python
# ✅ CORRECT - All of these work:
import huggingface_hub
from huggingface_hub import snapshot_download
from huggingface_hub import HfApi
from huggingface_hub import model_info
from huggingface_hub import hf_api
```

### Common Use Cases

#### Download a Model Repository

```python
# ✅ BEST PRACTICE (current):
from huggingface_hub import snapshot_download

model_path = snapshot_download(
    repo_id="mlx-community/medgemma-4b-it-4bit",
    repo_type="model",
    local_dir="./medgemma-4b-it-4bit"
)
```

#### Access HF API

```python
# ✅ CURRENT STANDARD:
from huggingface_hub import HfApi

api = HfApi()
model_info = api.model_info("mlx-community/medgemma-4b-it-4bit")
print(model_info.description)
```

#### Get Model Information

```python
# ✅ DIRECT APPROACH:
from huggingface_hub import model_info

info = model_info("mlx-community/medgemma-4b-it-4bit")
print(f"Model size: {info.siblings}")  # List of files
```

---

## Deprecated Functions (AVOID)

⚠️ **These are deprecated and should not be used:**

```python
# ❌ DEPRECATED - Don't use:
from huggingface_hub import hf_download       # Deprecated
from huggingface_hub import hf_file_download  # Doesn't exist
from huggingface_hub import cached_download   # Deprecated
```

**Migration Guide:**

```python
# OLD (deprecated):
from huggingface_hub import hf_download
file_path = hf_download(repo_id="...", filename="model.safetensors")

# NEW (current):
from huggingface_hub import snapshot_download
dir_path = snapshot_download(repo_id="...")
```

---

## Complete API Reference

### snapshot_download()

Downloads entire repository/directory

```python
from huggingface_hub import snapshot_download

model_dir = snapshot_download(
    repo_id="mlx-community/medgemma-4b-it-4bit",
    repo_type="model",              # "model", "dataset", or "space"
    local_dir="/path/to/download",  # Where to save
    revision="main",                 # Branch/tag/commit
    resume_download=True,            # Resume interrupted downloads
    force_download=False,            # Don't re-download existing
    token=None                       # HF API token (if needed)
)
```

### HfApi()

Direct API access for advanced operations

```python
from huggingface_hub import HfApi

api = HfApi()

# Get model info
model_info = api.model_info("mlx-community/medgemma-4b-it-4bit")

# List files in repo
files = api.list_repo_files("mlx-community/medgemma-4b-it-4bit")

# Get repo tree
tree = api.get_repo_tree("mlx-community/medgemma-4b-it-4bit")
```

### model_info()

Get information about a specific model

```python
from huggingface_hub import model_info

info = model_info("mlx-community/medgemma-4b-it-4bit")

print(f"Model ID: {info.model_id}")
print(f"Downloaded: {info.downloads}")
print(f"Last modified: {info.last_modified}")
print(f"Files: {info.siblings}")  # List of files in repo
```

---

## Complete Example: Download & Use Model

```python
from huggingface_hub import snapshot_download, model_info
from pathlib import Path

# 1. Get model information
model_id = "mlx-community/medgemma-4b-it-4bit"
info = model_info(model_id)

print(f"Model: {info.model_id}")
print(f"Size: {len(info.siblings)} files")

# 2. Download model
model_dir = snapshot_download(
    repo_id=model_id,
    repo_type="model",
    local_dir=Path.home() / "MediScribe" / "models" / "medgemma-4b-it-4bit"
)

print(f"Downloaded to: {model_dir}")

# 3. Verify files
files = list(Path(model_dir).glob("*"))
print(f"Files in directory: {len(files)}")
for file in sorted(files):
    if file.is_file():
        size_mb = file.stat().st_size / (1024*1024)
        print(f"  {file.name}: {size_mb:.1f} MB")
```

---

## Evaluation Scripts - Corrected Usage

### Current Issue in evaluate_pubmedqa.py

The script references deprecated `hf_download` function:

```python
# ❌ OLD (from earlier version):
from huggingface_hub import hf_download
```

### Corrected Version

```python
# ✅ NEW (use this instead):
from huggingface_hub import snapshot_download

# For downloading PubMedQA dataset:
dataset_dir = snapshot_download(
    repo_id="pubmedqa/pubmedqa",
    repo_type="dataset",
    local_dir="./pubmedqa"
)
```

---

## Installation Verification Script

```bash
python3 << 'EOF'
print("Verifying huggingface_hub installation...\n")

try:
    import huggingface_hub
    print(f"✅ huggingface_hub version: {huggingface_hub.__version__}")
except ImportError:
    print("❌ huggingface_hub not installed")
    print("   Run: pip install huggingface-hub")

# Test available functions
functions_to_test = [
    ("snapshot_download", "from huggingface_hub import snapshot_download"),
    ("HfApi", "from huggingface_hub import HfApi"),
    ("model_info", "from huggingface_hub import model_info"),
    ("hf_api", "from huggingface_hub import hf_api"),
]

print("\nAvailable functions:")
for name, import_stmt in functions_to_test:
    try:
        exec(import_stmt)
        print(f"  ✅ {name}")
    except ImportError:
        print(f"  ❌ {name} (not available)")

# Check deprecated functions
print("\nDeprecated functions (avoid):")
deprecated = [
    ("hf_download", "from huggingface_hub import hf_download"),
    ("cached_download", "from huggingface_hub import cached_download"),
]

for name, import_stmt in deprecated:
    try:
        exec(import_stmt)
        print(f"  ⚠️  {name} (exists but deprecated)")
    except ImportError:
        print(f"  ✅ {name} (not available - good!)")

print("\n✅ Verification complete!")
EOF
```

---

## Common Mistakes & Corrections

| Mistake | What Went Wrong | Fix |
|---------|-----------------|-----|
| `pip install huggingface_hub` | Using underscore instead of hyphen | Use `pip install huggingface-hub` |
| `from huggingface_hub import hf_download` | Function deprecated in newer versions | Use `snapshot_download()` instead |
| `from huggingface_hub import hf_file_download` | Function doesn't exist | Use `snapshot_download()` instead |
| `from huggingface_hub import cached_download` | Function deprecated | Use `snapshot_download()` instead |

---

## Migration Path for Old Code

If you have old code using deprecated functions:

**Before (Old Code)**:
```python
from huggingface_hub import hf_download

# Download a single file
file = hf_download(
    repo_id="username/repo",
    filename="model.safetensors"
)
```

**After (New Code)**:
```python
from huggingface_hub import snapshot_download
from pathlib import Path

# Download entire repo
repo_dir = snapshot_download(
    repo_id="username/repo",
    local_dir="./repo"
)

# Access the file
model_file = Path(repo_dir) / "model.safetensors"
```

---

## Quick Reference

```
Package Name (pip):     huggingface-hub
Import Name (Python):   huggingface_hub
Current Version:        1.3.5+

Modern Functions:
  ✅ snapshot_download()  - Download repos/datasets
  ✅ HfApi()              - Direct API access
  ✅ model_info()         - Get model information
  ✅ hf_api               - hf_api object

Deprecated Functions:
  ❌ hf_download()        - Use snapshot_download()
  ❌ cached_download()    - Use snapshot_download()
  ❌ hf_file_download()   - Use snapshot_download()
```

---

## Summary

| Item | Value | Notes |
|------|-------|-------|
| Pip Package | `huggingface-hub` | With HYPHEN |
| Python Module | `huggingface_hub` | With UNDERSCORE |
| Current Version | 1.3.5+ | Check with `pip show huggingface-hub` |
| Primary Function | `snapshot_download()` | For downloading models/datasets |
| API Access | `HfApi()` | For direct API calls |
| Info Lookup | `model_info()` | For model details |

---

**Status**: ✅ Verified with huggingface-hub v1.3.5
**Last Updated**: February 2, 2026
**Note**: The package follows the same pattern as mlx-vlm (hyphen in pip, underscore in Python)
