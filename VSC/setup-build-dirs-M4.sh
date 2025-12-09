#!/bin/bash

# Base directory for builds
BUILD_BASE="/Volumes/MacMini4/tmp/vscodebuilds"

# Array of project names
PROJECTS=("DecodeEncodeGeneric" "ParseRsyncOutput" "ProcessCommand" "RsyncArguments" "RsyncProcess" "RsyncUIDeepLinks" "SSHCreateKey" "RsyncUI")

# Create base directory if it doesn't exist
mkdir -p "$BUILD_BASE"

# Process each project
for project in "${PROJECTS[@]}"; do
    echo "Processing $project..."
    
    # Create the build directory in the target location
    mkdir -p "$BUILD_BASE/$project"
    
    # Navigate to project directory
    if [ -d "$project" ]; then
        cd "$project"
        
        # Remove existing .build (file, directory, or symlink)
        if [ -e .build ] || [ -L .build ]; then
            rm -rf .build
            echo "  Removed existing .build"
        fi
        
        # Create symlink
        ln -s "$BUILD_BASE/$project" .build
        echo "  Created symlink: .build -> $BUILD_BASE/$project"
        
        cd ..
    else
        echo "  Warning: Directory $project not found, skipping..."
    fi
done

echo "Done! All projects configured."
