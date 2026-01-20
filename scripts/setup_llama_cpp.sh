#!/bin/bash
# Script to setup llama.cpp for iOS integration
# This will clone and build llama.cpp with iOS support

set -e

echo "🦙 Setting up llama.cpp for iOS"
echo "================================"
echo ""

# Configuration
LLAMA_DIR="./llama.cpp"
LLAMA_REPO="https://github.com/ggerganov/llama.cpp"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Check if already exists
if [ -d "$LLAMA_DIR" ]; then
    echo -e "${YELLOW}⚠${NC}  llama.cpp directory already exists"
    read -p "Remove and re-clone? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        rm -rf "$LLAMA_DIR"
    else
        echo "Using existing directory"
    fi
fi

# Clone if needed
if [ ! -d "$LLAMA_DIR" ]; then
    echo "📥 Cloning llama.cpp..."
    git clone "$LLAMA_REPO" "$LLAMA_DIR"
    echo -e "${GREEN}✓${NC} Cloned llama.cpp"
fi

cd "$LLAMA_DIR"

echo ""
echo "🔨 Building llama.cpp for iOS..."
echo ""

# Build for iOS
mkdir -p build-ios
cd build-ios

# Configure with CMake for iOS
cmake .. \
    -DCMAKE_SYSTEM_NAME=iOS \
    -DCMAKE_OSX_DEPLOYMENT_TARGET=17.0 \
    -DCMAKE_OSX_ARCHITECTURES="arm64" \
    -DLLAMA_METAL=ON \
    -DLLAMA_BUILD_EXAMPLES=OFF \
    -DLLAMA_BUILD_TESTS=OFF

# Build
make -j$(sysctl -n hw.ncpu)

echo ""
echo -e "${GREEN}✓${NC} llama.cpp built for iOS"

cd ../..

# Create integration notes
cat > llama_cpp_integration.md << 'EOF'
# llama.cpp Integration Notes

## Built Libraries

- **Location**: `llama.cpp/build-ios/`
- **Key files**:
  - `libllama.a` - Core inference library
  - `libggml.a` - Matrix operations library
  - `libggml-metal.a` - Metal acceleration (GPU)

## Integration Steps

### 1. Add to Xcode Project

1. Drag `libllama.a`, `libggml.a`, `libggml-metal.a` into Xcode project
2. Add to "Link Binary With Libraries" build phase
3. Add header search path: `$(PROJECT_DIR)/llama.cpp`

### 2. Create Swift Wrapper

See `Domain/ML/MedGemmaModel.swift` template for integration example.

You'll need to:
- Import C headers (create bridging header)
- Wrap llama.cpp C API in Swift
- Handle memory management carefully
- Pass image data to model

### 3. Add Model File

- Copy quantized model (`.gguf`) to Xcode project
- Add to "Copy Bundle Resources"
- Access via `Bundle.main.path(forResource:ofType:)`

## Metal Acceleration

llama.cpp with Metal support will use the GPU for faster inference:
- M-series iPad: 2-3x faster
- Requires Metal framework linked

## Memory Management

- Model stays in memory until unloaded
- Call `unloadModel()` when switching models
- Monitor memory usage with Instruments

## Performance Tips

1. **First inference is slow** (model load + compile)
2. **Subsequent inferences faster** (cache warm)
3. **Batch if possible** (multiple images, reuse context)
4. **Use quantized models** (INT4 is best balance)

EOF

echo ""
echo "================================================"
echo -e "${GREEN}✅ llama.cpp Setup Complete${NC}"
echo "================================================"
echo ""
echo "Created: llama_cpp_integration.md"
echo ""
echo "Next steps:"
echo "1. Add built libraries to Xcode project"
echo "2. Create bridging header for C API"
echo "3. Implement MedGemmaModel using llama.cpp"
echo ""
echo "See ML_INTEGRATION_GUIDE.md for full instructions"
echo ""
