#!/bin/bash

# Master Evaluation Script
# Runs complete PubMedQA evaluation across all quantization levels

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RESULTS_DIR="$SCRIPT_DIR/evaluation_results"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

# Color codes
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}"
echo "╔════════════════════════════════════════════════════════════════════════╗"
echo "║           PUBMEDQA COMPLETE EVALUATION SUITE                          ║"
echo "║              MLX MedGemma Quantization Benchmark                      ║"
echo "╚════════════════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# Parse command line arguments
EVALUATE_TYPE="simple"  # simple or full
NUM_SAMPLES=10
COMPARE_ONLY=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --full)
            EVALUATE_TYPE="full"
            shift
            ;;
        --samples)
            NUM_SAMPLES="$2"
            shift 2
            ;;
        --compare)
            COMPARE_ONLY=true
            shift
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Create results directory
mkdir -p "$RESULTS_DIR"

echo -e "${GREEN}✅ Setup${NC}"
echo "   Script Directory: $SCRIPT_DIR"
echo "   Results Directory: $RESULTS_DIR"
echo "   Evaluation Type: $EVALUATE_TYPE"
echo "   Samples per Model: $NUM_SAMPLES"
echo "   Timestamp: $TIMESTAMP"
echo ""

# Verify models exist
echo -e "${BLUE}Verifying Models...${NC}"
for quant in 4bit 6bit 8bit; do
    model_dir="$HOME/MediScribe/models/medgemma-4b-it-$quant"
    if [ -d "$model_dir" ]; then
        model_file="$model_dir/model.safetensors"
        if [ -f "$model_file" ]; then
            size_gb=$(du -sh "$model_file" 2>/dev/null | awk '{print $1}')
            echo -e "${GREEN}✅${NC} $quant model found ($size_gb)"
        else
            echo -e "${YELLOW}❌${NC} $quant model weights missing"
        fi
    else
        echo -e "${YELLOW}❌${NC} $quant model directory not found"
    fi
done
echo ""

# Run evaluations
if [ "$EVALUATE_TYPE" = "simple" ]; then
    echo -e "${BLUE}Running Simple Evaluations...${NC}"
    echo ""

    if [ "$COMPARE_ONLY" = false ]; then
        for quant in 4bit 6bit 8bit; do
            echo -e "${YELLOW}[$(date +'%H:%M:%S')] Testing $quant...${NC}"
            python3 "$SCRIPT_DIR/evaluate_pubmedqa_simple.py" \
                --model "$quant" \
                --samples "$NUM_SAMPLES" \
                --output "$RESULTS_DIR/${quant}_simple_${TIMESTAMP}.json" \
                || echo "⚠️  $quant evaluation failed"
            echo ""
        done
    else
        echo -e "${YELLOW}[$(date +'%H:%M:%S')] Running Comparison...${NC}"
        python3 "$SCRIPT_DIR/evaluate_pubmedqa_simple.py" \
            --compare \
            --samples "$NUM_SAMPLES" \
            || echo "⚠️  Comparison failed"
        echo ""
    fi

else  # full evaluation
    echo -e "${BLUE}Running Full Evaluations...${NC}"
    echo ""

    if [ "$COMPARE_ONLY" = false ]; then
        for quant in 4bit 6bit 8bit; do
            echo -e "${YELLOW}[$(date +'%H:%M:%S')] Testing $quant...${NC}"
            python3 "$SCRIPT_DIR/evaluate_pubmedqa.py" \
                --model "$quant" \
                --samples "$NUM_SAMPLES" \
                --output "$RESULTS_DIR/${quant}_full_${TIMESTAMP}.json" \
                || echo "⚠️  $quant evaluation failed"
            echo ""
        done
    else
        echo -e "${YELLOW}[$(date +'%H:%M:%S')] Running Comparison...${NC}"
        python3 "$SCRIPT_DIR/evaluate_pubmedqa.py" \
            --compare \
            --samples "$NUM_SAMPLES" \
            || echo "⚠️  Comparison failed"
        echo ""
    fi
fi

# Display results summary
echo -e "${BLUE}════════════════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}Results Summary${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════════════════════════${NC}"
echo ""

if [ -d "$RESULTS_DIR" ] && [ "$(ls -A $RESULTS_DIR)" ]; then
    echo "Available Results:"
    ls -lh "$RESULTS_DIR" | tail -10
    echo ""

    echo "Quick Analysis:"
    python3 << 'EOF'
import json
from pathlib import Path
from collections import defaultdict

results_dir = Path("$RESULTS_DIR")
results_by_model = defaultdict(list)

for json_file in sorted(results_dir.glob("*.json")):
    try:
        with open(json_file) as f:
            data = json.load(f)
        model = data.get('model', 'unknown')
        results_by_model[model].append({
            'file': json_file.name,
            'accuracy': data.get('accuracy', 0),
            'time': data.get('avg_inference_time_ms', 0)
        })
    except Exception as e:
        print(f"Error reading {json_file}: {e}")

if results_by_model:
    print("Results by Model:")
    print("")
    for model in sorted(results_by_model.keys()):
        print(f"{model}:")
        for result in results_by_model[model]:
            print(f"  {result['file']}")
            print(f"    Accuracy: {result['accuracy']:.1f}%, Time: {result['time']:.0f}ms")
        print("")
else:
    print("No results found yet.")
EOF
else
    echo "No results saved yet. Results will be saved to: $RESULTS_DIR"
fi

echo ""
echo -e "${GREEN}✅ Evaluation Complete${NC}"
echo ""
echo "Next steps:"
echo "  1. Review results in: $RESULTS_DIR"
echo "  2. Compare accuracy vs inference time"
echo "  3. Choose optimal quantization for your use case"
echo "  4. For detailed guide, see: PUBMEDQA_EVALUATION_GUIDE.md"
echo ""
