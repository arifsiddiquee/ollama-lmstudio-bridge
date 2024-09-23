#!/bin/bash

# ============================================================================
# Ollama - LM Studio Bridge v0.1
# ============================================================================
#
# Description:
# Ollama LMSTudio Bridge creates a structure of directories and symlinks to make
# Ollama models accessible to LMStudio users.
#
# Based on powershell script from https://github.com/Les-El/Ollm-Bridge
#
# Usage:
#   1. Normal execution:
#      ./ollama-lmstudio-bridge.sh
#
#   2. Dry run mode (no changes made):
#      ./ollama-lmstudio-bridge.sh --dry-run
#
#   3. By Default the symlinks will be stored in 
#      /home/${USER}/models directory. You can change the models
#      directory with:
#      MODELS_DIR="/path/to/directory" ./ollama-lmstudio-bridge.sh
#
#   4. Combine dry run with custom directory:
#      MODELS_DIR="/path/to/directory" ./ollama-lmstudio-bridge.sh --dry-run
#
# Note: Ensure you have 'jq' installed for JSON parsing.
#       On macOS with Homebrew: brew install jq
#       On Linux: Use your distribution's package manager
#
# ============================================================================

# Check for dry run mode
dryrun=false
if [ "$1" = "--dry-run" ]; then
    dryrun=true
    echo "Running in dry run mode. No changes will be made."
fi

# Function to execute or simulate command based on dry run mode
execute_or_simulate() {
    if [ "$dryrun" = true ]; then
        echo "Would execute: $@"
    else
        "$@"
    fi
}

# Define the directory variables
manifest_dir="$HOME/.ollama/models/manifests/registry.ollama.ai"
blob_dir="$HOME/.ollama/models/blobs"
models_dir="${MODELS_DIR:-$HOME/models}"

# Print the base directories to confirm the variables
echo ""
echo "Confirming Directories:"
echo ""
echo "Manifest Directory: $manifest_dir"
echo "Blob Directory: $blob_dir"
echo "Directory for model symlinks: $models_dir"

# Create $publicmodels/lmstudio directory if it doesn't exist
if [ ! -d "$models_dir/lmstudio" ]; then
    echo ""
    echo "LMStudio directory does not exist."
    execute_or_simulate mkdir -p "$models_dir/lmstudio"
else
    echo ""
    echo "LMStudio directory already exists. Proceeding..."
fi

# Explore the manifest directory and record the manifest file locations
echo ""
echo "Exploring Ollama Manifest Directory:"
manifestLocations=$(find "$manifest_dir" -type f)

echo ""
echo "Models found:"
echo ""
echo "$manifestLocations"

# Parse through json files to get model info
for manifest in $manifestLocations; do
    # Use jq to parse JSON
    modelConfig="$blob_dir/$(jq -r '.config.digest' "$manifest" | sed 's/sha256:/sha256-/')"
    modelFile="$blob_dir/$(jq -r '.layers[] | select(.mediaType | endswith("model")) | .digest' "$manifest" | sed 's/sha256:/sha256-/')"
    modelTemplate="$blob_dir/$(jq -r '.layers[] | select(.mediaType | endswith("template")) | .digest' "$manifest" | sed 's/sha256:/sha256-/')"
    modelParams="$blob_dir/$(jq -r '.layers[] | select(.mediaType | endswith("params")) | .digest' "$manifest" | sed 's/sha256:/sha256-/')"

    # Extract variables from $modelConfig
    modelQuant=$(jq -r '.file_type' "$modelConfig")
    modelExt=$(jq -r '.model_format' "$modelConfig")
    modelTrainedOn=$(jq -r '.model_type' "$modelConfig")

    # Get the parent directory of $manifest
    parentDir=$(dirname "$manifest")

    # Set the $modelName variable to the name of the directory
    modelName=$(basename "$parentDir")

    echo ""
    echo "Model: $modelName"
    echo "Quant: $modelQuant"
    echo "Extension: $modelExt"
    echo "Number of Parameters Trained on: $modelTrainedOn"

    # Check if the subdirectory exists and create it if necessary
    if [ ! -d "$models_dir/lmstudio/$modelName" ]; then
        echo ""
        echo "Directory does not exist for $modelName"
        execute_or_simulate mkdir -p "$models_dir/lmstudio/$modelName"
    fi

    # Create the symbolic link if it doesn't already exist
    linkPath="$models_dir/lmstudio/$modelName/$modelName-$modelTrainedOn-$modelQuant.$modelExt"
    if [ ! -L "$linkPath" ]; then
        echo ""
        echo "Symbolic link does not exist."
        execute_or_simulate ln -s "$modelFile" "$linkPath"
    else
        echo ""
        echo "Symbolic link for $modelName already exists. Skipping..."
    fi
done

echo ""
echo "*********************"
echo "Bridge script complete."
if [ "$dryrun" = true ]; then
    echo "Dry run finished. No changes were made."
else
    echo "Set the Models Directory in LMStudio to $models_dir"
fi
