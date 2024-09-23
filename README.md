# Ollama LM Studio bridge
Shell script to create symlinks for Ollama models to be used in LM Studio.

Based on powershell script from https://github.com/Les-El/Ollm-Bridge

## Pre-requisites
Ensure you have `jq` installed for JSON parsing.

On macOS with Homebrew: `brew install jq`
On Linux: Use your distribution's package manager

## Usage

   1. Normal execution:
      `./ollama-lmstudio-bridge.sh`

   2. Dry run mode (no changes made):
      `./ollama-lmstudio-bridge.sh --dry-run`

   3. By Default the model symlinks will be stored in  `/home/${USER}/models` directory. 
      You can change the models directory with:
      `MODELS_DIR="/path/to/directory" ./ollama-lmstudio-bridge.sh`

   4. Combine dry run with custom directory:
      `MODELS_DIR="/path/to/directory" ./ollama-lmstudio-bridge.sh --dry-run`