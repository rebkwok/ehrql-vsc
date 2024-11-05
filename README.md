# ehrQL in VS Code

Contains a script, setup-vscode.sh which:

1. Extracts site-packages and ehrql source code from the ehrql docker image and copies them to
   a local .vscode/ folder
2. Updates PYTHONPATH in a .env file (creating a new one if necessary) to point to the .vscode/ python
3. Updates VS Code settings to add the copied paths as extra python paths (using jq to merge with existing settings if possible)
4. Reloads the VS code window


To use it:

1. Clone this repo and open the folder in VS Code (add folder to workspace)
1. Ensure there's no virtual env activated (i.e. no local ehrql)
1. Open dataset_definition.py in the VS code editor and verify it doesn't recognise the ehrql imports
1. In a VS Code terminal, run ./setup-vscode.sh (doesn't have to be in VS code terminal, but if it is, it will do the autoreload for you)
1. dataset_definition.py now has autocomplete (sortof) for ehrQL
