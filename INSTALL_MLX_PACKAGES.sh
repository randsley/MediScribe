#!/bin/bash

# MLX Package Installation Script
# Correctly installs all required MLX and supporting packages

echo "╔════════════════════════════════════════════════════════════════════════╗"
echo "║              MLX MedGemma - Python Package Installation               ║"
echo "╚════════════════════════════════════════════════════════════════════════╝"
echo ""

echo "Step 1: Update pip..."
pip install --upgrade pip
echo ""

echo "Step 2: Installing MLX core framework..."
pip install mlx
echo ""

echo "Step 3: Installing MLX Vision-Language Models..."
echo "   (Note: Package name is 'mlx-vlm' with HYPHEN)"
pip install mlx-vlm
echo ""

echo "Step 4: Installing supporting libraries..."
pip install transformers huggingface-hub datasets
echo ""

echo "Step 5: Verifying installation..."
python3 << 'PYEOF'
print("\nVerifying MLX installation...\n")

try:
    import mlx.core as mx
    print("  ✅ mlx.core - Core MLX framework")
except ImportError as e:
    print(f"  ❌ mlx.core failed: {e}")

try:
    from mlxvlm.model_factory import load_model
    print("  ✅ mlxvlm.model_factory - Model loading")
except ImportError as e:
    print(f"  ❌ mlxvlm import failed: {e}")

try:
    from transformers import AutoTokenizer
    print("  ✅ transformers - Tokenizers")
except ImportError as e:
    print(f"  ❌ transformers failed: {e}")

try:
    from huggingface_hub import hf_download
    print("  ✅ huggingface_hub - Model downloads")
except ImportError as e:
    print(f"  ❌ huggingface_hub failed: {e}")

try:
    from datasets import load_dataset
    print("  ✅ datasets - Dataset utilities")
except ImportError as e:
    print(f"  ❌ datasets failed: {e}")

print("\n✅ Installation verification complete!")
PYEOF

echo ""
echo "╔════════════════════════════════════════════════════════════════════════╗"
echo "║                     INSTALLATION COMPLETE ✅                          ║"
echo "╚════════════════════════════════════════════════════════════════════════╝"
echo ""
echo "Correct package names:"
echo "  • mlx (import: mlx.core)"
echo "  • mlx-vlm (import: mlxvlm)"
echo "  • transformers"
echo "  • huggingface-hub"
echo "  • datasets"
echo ""
echo "Ready to run evaluations:"
echo "  cd ~/MediScribe"
echo "  python3 evaluate_pubmedqa_simple.py"
echo ""
