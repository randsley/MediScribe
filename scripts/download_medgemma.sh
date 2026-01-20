#!/bin/bash
# Script to download MedGemma 1.5 4B model from Hugging Face
# Requires: huggingface-cli installed and authenticated

set -e

echo "🏥 MediScribe - MedGemma 1.5 4B Download Script"
echo "================================================"
echo ""

# Configuration
MODEL_NAME="google/medgemma-1.5-4b-it"
QUANTIZED_MODEL="unsloth/medgemma-1.5-4b-it-GGUF"
OUTPUT_DIR="../Models/MedGemma"
USE_QUANTIZED=true

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if huggingface-cli is installed
if ! command -v huggingface-cli &> /dev/null; then
    echo -e "${RED}Error: huggingface-cli not found${NC}"
    echo "Install with: pip install huggingface_hub"
    exit 1
fi

echo -e "${GREEN}✓${NC} huggingface-cli found"

# Check if logged in
if ! huggingface-cli whoami &> /dev/null; then
    echo -e "${YELLOW}⚠${NC}  Not logged in to Hugging Face"
    echo "Please run: huggingface-cli login"
    echo ""
    read -p "Login now? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        huggingface-cli login
    else
        echo "Cannot proceed without authentication"
        exit 1
    fi
fi

echo -e "${GREEN}✓${NC} Authenticated with Hugging Face"

# Check model access
echo ""
echo "⚠️  IMPORTANT: You must accept the license for MedGemma"
echo "Visit: https://huggingface.co/$MODEL_NAME"
echo "Click 'Agree and access repository'"
echo ""
read -p "Have you accepted the license? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Please accept the license before proceeding"
    echo "Opening browser..."
    open "https://huggingface.co/$MODEL_NAME" || true
    exit 1
fi

# Create output directory
mkdir -p "$OUTPUT_DIR"
echo -e "${GREEN}✓${NC} Output directory: $OUTPUT_DIR"

# Download model
echo ""
if [ "$USE_QUANTIZED" = true ]; then
    echo "📥 Downloading quantized model (INT4 GGUF)"
    echo "Model: $QUANTIZED_MODEL"
    echo "Size: ~2-3 GB"
    echo ""

    huggingface-cli download "$QUANTIZED_MODEL" \
        --local-dir "$OUTPUT_DIR/quantized" \
        --local-dir-use-symlinks False

    echo ""
    echo -e "${GREEN}✓${NC} Quantized model downloaded"

    # Find the Q4 quantized file
    Q4_FILE=$(find "$OUTPUT_DIR/quantized" -name "*Q4*.gguf" | head -1)
    if [ -n "$Q4_FILE" ]; then
        echo "   Q4 Model: $Q4_FILE"
        SIZE=$(du -h "$Q4_FILE" | cut -f1)
        echo "   Size: $SIZE"
    fi
else
    echo "📥 Downloading full model"
    echo "Model: $MODEL_NAME"
    echo "Size: ~8 GB"
    echo "⚠️  This will take a while..."
    echo ""

    huggingface-cli download "$MODEL_NAME" \
        --local-dir "$OUTPUT_DIR/full" \
        --local-dir-use-symlinks False

    echo ""
    echo -e "${GREEN}✓${NC} Full model downloaded"
fi

# Summary
echo ""
echo "================================================"
echo -e "${GREEN}✅ Download Complete${NC}"
echo "================================================"
echo ""
echo "Next steps:"
echo "1. Review downloaded files in: $OUTPUT_DIR"
if [ "$USE_QUANTIZED" = false ]; then
    echo "2. Quantize model (run: ./quantize_medgemma.sh)"
    echo "3. Integrate with MediScribe"
else
    echo "2. Integrate with MediScribe (model ready to use)"
fi
echo ""
echo "See ML_INTEGRATION_GUIDE.md for full instructions"
echo ""
