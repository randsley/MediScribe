#!/bin/bash
#
# MediScribe - MedGemma Model Download Script
#
# Downloads the MedGemma 1.5 4B model in GGUF format for use with llama.cpp.
#
# IMPORTANT: MedGemma is governed by Google's Health AI Developer Foundations
# Terms of Use. You must accept the license before using this model.
#
# License: https://ai.google.dev/gemma/terms
# Model Card: https://developers.google.com/health-ai-developer-foundations/medgemma
#

set -e

echo "════════════════════════════════════════════════════════════════════"
echo "  MediScribe - MedGemma 1.5 4B Download Script"
echo "════════════════════════════════════════════════════════════════════"
echo ""

# Configuration
OFFICIAL_MODEL="google/medgemma-1.5-4b-it"
GGUF_REPO="mradermacher/medgemma-1.5-4b-it-GGUF"

# Files to download (from GGUF repo - mradermacher naming convention)
MODEL_FILE="Q4_K_M.gguf"
MMPROJ_FILE="medgemma-1.5-4b-it.mmproj-Q8_0.gguf"

# Expected filenames in MediScribe code (what MedGemmaModel.swift expects)
EXPECTED_MODEL="medgemma-1.5-4b-it-Q4_K_M.gguf"
EXPECTED_MMPROJ="medgemma-1.5-4b-it.mmproj-Q8_0.gguf"

# Output directory (relative to script location)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
OUTPUT_DIR="$PROJECT_DIR/Models/MedGemma"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m' # No Color

print_step() {
    echo -e "\n${BLUE}[$1]${NC} $2"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

# ============================================================================
# Step 1: Check prerequisites
# ============================================================================
print_step "1/6" "Checking prerequisites..."

# Check for hf CLI (huggingface-cli is deprecated)
if ! command -v hf &> /dev/null; then
    print_error "hf CLI not found"
    echo ""
    echo "Install with:"
    echo "  pip install huggingface_hub[cli]"
    echo ""
    echo "Or upgrade if you have the old huggingface-cli:"
    echo "  pip install --upgrade huggingface_hub[cli]"
    echo ""
    exit 1
fi
print_success "hf CLI found"

# Check authentication
if ! hf whoami &> /dev/null; then
    print_warning "Not logged in to Hugging Face"
    echo ""
    echo "You need a Hugging Face account to download MedGemma."
    echo "Get a token at: https://huggingface.co/settings/tokens"
    echo ""
    read -p "Run 'hf login' now? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        hf login
        if ! hf whoami &> /dev/null; then
            print_error "Login failed"
            exit 1
        fi
    else
        print_error "Cannot proceed without authentication"
        exit 1
    fi
fi

HF_USER=$(hf whoami 2>/dev/null | head -1)
print_success "Authenticated as: $HF_USER"

# ============================================================================
# Step 2: License acceptance
# ============================================================================
print_step "2/6" "License verification..."

echo ""
echo -e "${BOLD}IMPORTANT: MedGemma License Requirements${NC}"
echo ""
echo "MedGemma is released under Google's Health AI Developer Foundations"
echo "Terms of Use. Before proceeding, you must:"
echo ""
echo "  1. Visit the official model page:"
echo -e "     ${BLUE}https://huggingface.co/$OFFICIAL_MODEL${NC}"
echo ""
echo "  2. Click 'Agree and access repository'"
echo ""
echo "  3. Review and accept the license terms"
echo ""
echo "The license includes important usage restrictions for medical AI."
echo ""

read -p "Have you accepted the license at the official model page? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo ""
    echo "Opening the model page in your browser..."
    open "https://huggingface.co/$OFFICIAL_MODEL" 2>/dev/null || \
        xdg-open "https://huggingface.co/$OFFICIAL_MODEL" 2>/dev/null || \
        echo "Please visit: https://huggingface.co/$OFFICIAL_MODEL"
    echo ""
    echo "After accepting the license, run this script again."
    exit 0
fi

print_success "License acknowledged"

# ============================================================================
# Step 3: Create output directory
# ============================================================================
print_step "3/6" "Preparing output directory..."

mkdir -p "$OUTPUT_DIR"
print_success "Output directory: $OUTPUT_DIR"

# ============================================================================
# Step 4: Download main model
# ============================================================================
print_step "4/6" "Downloading main model..."

echo ""
echo "Source: $GGUF_REPO"
echo "File:   $MODEL_FILE (~2.5 GB)"
echo ""

DOWNLOAD_PATH="$OUTPUT_DIR/$MODEL_FILE"

if [[ -f "$OUTPUT_DIR/$EXPECTED_MODEL" ]]; then
    print_warning "Model already exists: $EXPECTED_MODEL"
    read -p "Re-download? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_success "Skipping main model download"
    else
        rm -f "$OUTPUT_DIR/$EXPECTED_MODEL"
    fi
fi

if [[ ! -f "$OUTPUT_DIR/$EXPECTED_MODEL" ]]; then
    hf download "$GGUF_REPO" "$MODEL_FILE" \
        --local-dir "$OUTPUT_DIR" \
        --local-dir-use-symlinks False

    # Rename to match code expectations if needed
    if [[ -f "$DOWNLOAD_PATH" && "$MODEL_FILE" != "$EXPECTED_MODEL" ]]; then
        mv "$DOWNLOAD_PATH" "$OUTPUT_DIR/$EXPECTED_MODEL"
        print_success "Renamed to: $EXPECTED_MODEL"
    fi

    if [[ -f "$OUTPUT_DIR/$EXPECTED_MODEL" ]]; then
        SIZE=$(du -h "$OUTPUT_DIR/$EXPECTED_MODEL" | cut -f1)
        print_success "Main model downloaded ($SIZE)"
    else
        print_error "Download failed"
        exit 1
    fi
fi

# ============================================================================
# Step 5: Download vision encoder (mmproj)
# ============================================================================
print_step "5/6" "Downloading vision encoder (mmproj)..."

echo ""
echo "Source: $GGUF_REPO"
echo "File:   $MMPROJ_FILE (~591 MB)"
echo "Note:   Required for medical image analysis"
echo ""

if [[ -f "$OUTPUT_DIR/$EXPECTED_MMPROJ" ]]; then
    print_warning "Vision encoder already exists: $EXPECTED_MMPROJ"
    read -p "Re-download? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_success "Skipping vision encoder download"
    else
        rm -f "$OUTPUT_DIR/$EXPECTED_MMPROJ"
    fi
fi

if [[ ! -f "$OUTPUT_DIR/$EXPECTED_MMPROJ" ]]; then
    hf download "$GGUF_REPO" "$MMPROJ_FILE" \
        --local-dir "$OUTPUT_DIR" \
        --local-dir-use-symlinks False

    # The mmproj filename already matches expectations
    if [[ -f "$OUTPUT_DIR/$MMPROJ_FILE" ]]; then
        SIZE=$(du -h "$OUTPUT_DIR/$MMPROJ_FILE" | cut -f1)
        print_success "Vision encoder downloaded ($SIZE)"
    else
        print_error "Download failed"
        exit 1
    fi
fi

# ============================================================================
# Step 6: Verify and summarize
# ============================================================================
print_step "6/6" "Verifying downloads..."

echo ""
TOTAL_SIZE=0
ALL_OK=true

if [[ -f "$OUTPUT_DIR/$EXPECTED_MODEL" ]]; then
    SIZE=$(stat -f%z "$OUTPUT_DIR/$EXPECTED_MODEL" 2>/dev/null || stat -c%s "$OUTPUT_DIR/$EXPECTED_MODEL" 2>/dev/null)
    SIZE_MB=$((SIZE / 1024 / 1024))
    TOTAL_SIZE=$((TOTAL_SIZE + SIZE))
    if [[ $SIZE_MB -gt 2400 ]]; then
        print_success "Main model: $EXPECTED_MODEL (${SIZE_MB} MB)"
    else
        print_warning "Main model may be incomplete (${SIZE_MB} MB, expected ~2490 MB)"
        ALL_OK=false
    fi
else
    print_error "Main model not found: $EXPECTED_MODEL"
    ALL_OK=false
fi

if [[ -f "$OUTPUT_DIR/$EXPECTED_MMPROJ" ]]; then
    SIZE=$(stat -f%z "$OUTPUT_DIR/$EXPECTED_MMPROJ" 2>/dev/null || stat -c%s "$OUTPUT_DIR/$EXPECTED_MMPROJ" 2>/dev/null)
    SIZE_MB=$((SIZE / 1024 / 1024))
    TOTAL_SIZE=$((TOTAL_SIZE + SIZE))
    if [[ $SIZE_MB -gt 550 ]]; then
        print_success "Vision encoder: $EXPECTED_MMPROJ (${SIZE_MB} MB)"
    else
        print_warning "Vision encoder may be incomplete (${SIZE_MB} MB, expected ~591 MB)"
        ALL_OK=false
    fi
else
    print_error "Vision encoder not found: $EXPECTED_MMPROJ"
    ALL_OK=false
fi

TOTAL_MB=$((TOTAL_SIZE / 1024 / 1024))
TOTAL_GB=$(echo "scale=2; $TOTAL_MB / 1024" | bc)

echo ""
echo "════════════════════════════════════════════════════════════════════"

if [[ "$ALL_OK" == true ]]; then
    echo -e "${GREEN}${BOLD}Download Complete${NC}"
    echo "════════════════════════════════════════════════════════════════════"
    echo ""
    echo "Total size: ${TOTAL_GB} GB"
    echo "Location:   $OUTPUT_DIR"
    echo ""
    echo "Next steps:"
    echo ""
    echo "  1. Open MediScribe.xcodeproj in Xcode"
    echo ""
    echo "  2. Add model files to the project:"
    echo "     - Right-click project root -> Add Files to 'MediScribe'"
    echo "     - Navigate to: $OUTPUT_DIR"
    echo "     - Select both .gguf files"
    echo "     - Check 'Copy items if needed'"
    echo "     - Check 'Add to targets: MediScribe'"
    echo ""
    echo "  3. Verify in Build Phases -> Copy Bundle Resources"
    echo ""
    echo "  4. Build and run the app"
    echo ""
else
    echo -e "${RED}${BOLD}Download Incomplete${NC}"
    echo "════════════════════════════════════════════════════════════════════"
    echo ""
    echo "Some files are missing or incomplete. Please re-run this script."
    echo ""
    exit 1
fi
