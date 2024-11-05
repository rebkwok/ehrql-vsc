#!/bin/bash

# Configuration
DOCKER_IMAGE="your-image-name"
SOURCE_PACKAGE_PATH="/app/ehrql"  # Add your source code paths here
PYTHON_VERSION="3.11"  # Adjust to match your Python version

# Create directories
mkdir -p .vscode/python-packages/site-packages
mkdir -p .vscode/python-packages/source


# Run the container and copy site-packages
docker create --name temp-container ghcr.io/opensafely-core/ehrql:v1 
docker cp temp-container:/opt/venv/lib/python3.11/site-packages .vscode/python-packages/
docker cp temp-container:$SOURCE_PACKAGE_PATH .vscode/python-packages/source/
docker rm temp-container

# Create the new PYTHONPATH value
NEW_PYTHONPATH="${PWD}/.vscode/python-packages/site-packages:${PWD}/.vscode/python-packages/source"

# Update .env file while preserving other variables
if [ -f .env ]; then
    # Create a temporary file
    touch .env.tmp
    
    # Process each line in the existing .env
    while IFS= read -r line || [ -n "$line" ]; do
        if [[ $line =~ ^PYTHONPATH= ]]; then
            # Replace existing PYTHONPATH line
            echo "PYTHONPATH=$NEW_PYTHONPATH" >> .env.tmp
        else
            # Keep other lines unchanged
            echo "$line" >> .env.tmp
        fi
    done < .env
    
    # If PYTHONPATH wasn't found, add it
    if ! grep -q "^PYTHONPATH=" .env; then
        echo "PYTHONPATH=$NEW_PYTHONPATH" >> .env.tmp
    fi
    
    # Replace original .env with our updated version
    mv .env.tmp .env
else
    # Create new .env if it doesn't exist
    echo "PYTHONPATH=$NEW_PYTHONPATH" > .env
fi

# Update VS Code settings
mkdir -p .vscode
if [ -f .vscode/settings.json ]; then
    # Backup existing settings
    cp .vscode/settings.json .vscode/settings.json.bak
    
    if command -v jq >/dev/null 2>&1; then
        # Create a temporary array of paths
        paths_array=$(jq -n \
            --arg site "${PWD}/.vscode/python-packages/site-packages" \
            --arg source "${PWD}/.vscode/python-packages/source" \
            '[$ARGS.named.site, $ARGS.named.source]')
        
        # Merge with existing settings
        jq --argjson paths "$paths_array" '.["python.analysis.extraPaths"] += $paths' .vscode/settings.json > .vscode/settings.json.tmp
        mv .vscode/settings.json.tmp .vscode/settings.json
    else
        echo "jq not found - creating new settings file. Your previous settings are backed up as settings.json.bak"
        cat > .vscode/settings.json << EOL
{
    "python.analysis.extraPaths": [
        "${PWD}/.vscode/python-packages/site-packages",
        "${PWD}/.vscode/python-packages/source"
    ],
    "python.analysis.typeCheckingMode": "basic"
}
EOL
    fi
else
    # Create new settings file
    cat > .vscode/settings.json << EOL
{
    "python.analysis.extraPaths": [
        "${PWD}/.vscode/python-packages/site-packages",
        "${PWD}/.vscode/python-packages/source"
    ],
    "python.analysis.typeCheckingMode": "basic"
}
EOL
fi

# Reload VS code settings:
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    osascript -e 'tell application "Visual Studio Code" to activate' -e 'tell application "System Events" to keystroke "r" using command down'
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    # Linux
    if command -v xdotool >/dev/null 2>&1; then
        xdotool search --name "Visual Studio Code" windowactivate --sync key --clearmodifiers ctrl+r
    else
        echo "For automatic reload on Linux, please install xdotool or reload manually with Ctrl+R"
    fi
elif [[ "$OSTYPE" == "msys"* ]] || [[ "$OSTYPE" == "cygwin"* ]]; then
    # Windows
    if command -v pwsh >/dev/null 2>&1; then
        pwsh -Command "Add-Type -AssemblyName System.Windows.Forms; [System.Windows.Forms.SendKeys]::SendWait('^{R}')"
    else
        echo "For automatic reload on Windows, please install PowerShell or reload manually with Ctrl+R"
    fi
fi

echo "Setup complete! If window didn't reload automatically, use Cmd+R (Mac) or Ctrl+R (Windows/Linux) to reload VS Code"
