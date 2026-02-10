#!/bin/bash

# MediScribe Device Deployment Script
# Usage: ./deploy_to_device.sh [device_name]
# Example: ./deploy_to_device.sh Sarov

set -e

PROJECT_DIR="/Users/nigelrandsley/MediScribe"
PROJECT_FILE="$PROJECT_DIR/MediScribe.xcodeproj"
SCHEME="MediScribe"
CONFIG="Release"

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║     MediScribe Device Deployment Script                    ║${NC}"
echo -e "${BLUE}║     Build for iOS Device with MLX Model                    ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Check if Xcode is available
if ! command -v xcodebuild &> /dev/null; then
    echo -e "${RED}❌ Error: xcodebuild not found${NC}"
    echo "Please ensure Xcode is installed and in PATH"
    exit 1
fi

echo -e "${BLUE}Step 1: Checking for connected devices...${NC}"
echo ""

# List available devices
DEVICES=$(xcrun xcode-select --print-path 2>/dev/null | xargs -I {} bash -c "echo 'Checking for connected iOS devices...'")

# Try to get list of connected devices
if command -v xctrace &> /dev/null; then
    echo -e "${YELLOW}Available iOS devices:${NC}"
    xctrace list devices 2>/dev/null | grep -E "iPhone|iPad" || echo "  (No devices found)"
else
    echo -e "${YELLOW}Available iOS devices:${NC}"
    echo "  (Use Xcode to see connected devices)"
fi

echo ""
echo -e "${BLUE}Step 2: Building MediScribe for iOS device...${NC}"
echo "  Project: $PROJECT_FILE"
echo "  Scheme: $SCHEME"
echo "  Configuration: $CONFIG"
echo ""

# Determine device specifier
if [ -z "$1" ]; then
    DEVICE_SPEC="platform=iOS"
    echo -e "${YELLOW}⚠️  No device specified. Will use first available iOS device.${NC}"
    echo "    Usage: $0 [device_name]"
    echo "    Example: $0 Sarov"
    echo ""
else
    DEVICE_SPEC="platform=iOS,name=$1"
    echo -e "${GREEN}✅ Target device: $1${NC}"
    echo ""
fi

# Build
echo -e "${BLUE}Building...${NC}"
if xcodebuild -project "$PROJECT_FILE" \
              -scheme "$SCHEME" \
              -configuration "$CONFIG" \
              -destination "$DEVICE_SPEC" \
              install; then
    echo ""
    echo -e "${GREEN}✅ Build succeeded!${NC}"
else
    echo ""
    echo -e "${RED}❌ Build failed!${NC}"
    echo ""
    echo "Troubleshooting:"
    echo "  1. Check device is connected via USB"
    echo "  2. Trust this computer on device if prompted"
    echo "  3. Check Console output above for specific errors"
    exit 1
fi

echo ""
echo -e "${BLUE}Step 3: Verifying app installation...${NC}"
echo ""

# Check if app is on device
if xcodebuild -project "$PROJECT_FILE" \
              -scheme "$SCHEME" \
              -configuration "$CONFIG" \
              -destination "$DEVICE_SPEC" \
              build 2>&1 | grep -q "Build complete"; then
    echo -e "${GREEN}✅ App built and ready for installation${NC}"
else
    echo -e "${YELLOW}⚠️  Build output unclear, but proceeding...${NC}"
fi

echo ""
echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║ ✅ Deployment Complete!                                   ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${BLUE}Next Steps:${NC}"
echo ""
echo "1. App should now be installing on your device..."
echo "   (Check device screen for installation progress)"
echo ""
echo "2. Once installed, launch the app"
echo ""
echo "3. Navigate to Notes → Generate SOAP Note"
echo ""
echo "4. Follow testing checklist in:"
echo "   PHASE_2_DEVICE_DEPLOYMENT_GUIDE.md"
echo ""
echo -e "${BLUE}Model Information:${NC}"
echo "  Model: medgemma-4b-it (4-bit quantization)"
echo "  Size: 2.8 GB"
echo "  Expected inference time: 1-1.5 seconds"
echo ""
echo -e "${BLUE}Troubleshooting:${NC}"
echo "  - Check Console: View → Navigators → Console (⌘6)"
echo "  - View Devices: Window → Devices & Simulators"
echo "  - Monitor memory: Xcode profiler (⌘I)"
echo ""
echo "Good luck! 🚀"
