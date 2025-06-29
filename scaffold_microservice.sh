#!/bin/bash

# scaffold_microservice.sh
# Automates the creation of a new ASP.NET Core microservice structure.

# Exit immediately if a command exits with a non-zero status.
set -e

# --- Configuration ---
MICROSERVICE_NAME="" # This will be set by user input

# --- Functions ---

# Function to display error message and exit
error_exit() {
  echo "Error: $1" >&2
  exit 1
}

# Function to create a C# class library project and add it to the solution
create_classlib() {
  local project_name=$1
  local solution_file=$2
  local src_dir=$3

  echo "  - Creating Class Library: $project_name"
  dotnet new classlib -n "$project_name" -o "$src_dir/$project_name" || error_exit "Failed to create classlib $project_name"
  dotnet sln "$solution_file" add "$src_dir/$project_name/$project_name.csproj" || error_exit "Failed to add $project_name to solution"
}

# Function to create a Web API project and add it to the solution
create_webapi() {
  local project_name=$1
  local solution_file=$2
  local src_dir=$3

  echo "  - Creating Web API Project: $project_name"
  dotnet new webapi -n "$project_name" -o "$src_dir/$project_name" --use-controllers || error_exit "Failed to create webapi $project_name"
  dotnet sln "$solution_file" add "$src_dir/$project_name/$project_name.csproj" || error_exit "Failed to add $project_name to solution"
}

# --- Main Script Execution ---

echo "==================================================="
echo "ASP.NET Core Microservice Scaffolding Script"
echo "==================================================="

# Get microservice name from user
read -p "Enter the name for your new microservice (e.g., MessagingService): " MICROSERVICE_NAME

if [ -z "$MICROSERVICE_NAME" ]; then
  error_exit "Microservice name cannot be empty."
fi

echo "Creating microservice: $MICROSERVICE_NAME"

# Create the root directory for the microservice
mkdir -p "$MICROSERVICE_NAME" || error_exit "Failed to create root directory $MICROSERVICE_NAME"
cd "$MICROSERVICE_NAME" || error_exit "Failed to change to directory $MICROSERVICE_NAME"

# Create the src directory
mkdir -p src || error_exit "Failed to create src directory"

# Define paths
SOLUTION_FILE="$MICROSERVICE_NAME.sln"
SRC_DIR="src"

CORE_PROJECT="${MICROSERVICE_NAME}.Core"
INFRA_PROJECT="${MICROSERVICE_NAME}.Infrastructure"
API_PROJECT="${MICROSERVICE_NAME}.Api"

# --- Create Solution File ---
echo ""
echo "--- Creating solution file: $SOLUTION_FILE ---"
dotnet new sln -n "$MICROSERVICE_NAME" || error_exit "Failed to create solution file"

# --- Create Projects and Add to Solution ---
echo ""
echo "--- Creating core projects ---"
create_classlib "$CORE_PROJECT" "$SOLUTION_FILE" "$SRC_DIR"
create_classlib "$INFRA_PROJECT" "$SOLUTION_FILE" "$SRC_DIR"
create_webapi "$API_PROJECT" "$SOLUTION_FILE" "$SRC_DIR"

# --- Add Project References ---
echo ""
echo "--- Adding project references ---"

# Infrastructure -> Core
echo "  - Adding reference from $INFRA_PROJECT to $CORE_PROJECT"
dotnet add "$SRC_DIR/$INFRA_PROJECT/$INFRA_PROJECT.csproj" reference "$SRC_DIR/$CORE_PROJECT/$CORE_PROJECT.csproj" || error_exit "Failed to add infra to core ref"

# API -> Core
echo "  - Adding reference from $API_PROJECT to $CORE_PROJECT"
dotnet add "$SRC_DIR/$API_PROJECT/$API_PROJECT.csproj" reference "$SRC_DIR/$CORE_PROJECT/$CORE_PROJECT.csproj" || error_exit "Failed to add api to core ref"

# API -> Infrastructure
echo "  - Adding reference from $API_PROJECT to $INFRA_PROJECT"
dotnet add "$SRC_DIR/$API_PROJECT/$API_PROJECT.csproj" reference "$SRC_DIR/$INFRA_PROJECT/$INFRA_PROJECT.csproj" || error_exit "Failed to add api to infra ref"

# --- Add .gitignore file ---
echo ""
echo "--- Creating .gitignore file ---"
cat <<EOF > .gitignore
# Visual Studio
.vs/
*.sln.docstates
*.user
*.suo
*.opensdf
*.VC.db

# Build results
[Dd]ebug/
[Rr]elease/
[Bb]in/
[Oo]bj/
*.exe
*.dll
*.pdb
*.tmp
*.log
*.bak
*.old
*.obj
*.user
*.ide
*.kproj
*.swo
*.swp
*.bak
publish/ # Directory for published output
artifacts/ # Common directory for build artifacts

# NuGet packages
*.nupkg
packages/
*.nuget.log

# Test results
TestResults/
*.trx

# Node.js (if applicable)
node_modules/
npm-debug.log
yarn-error.log

# Editors/OS
.DS_Store
Thumbs.db
*.exe.config
*.bat
*.cmd
.terraform/
terraform.tfstate*

# VS Code
.vscode/

# Rider
.idea/

# DotNet tool files
.config/
EOF
echo ".gitignore created."

# --- Add build.sh script ---
echo ""
echo "--- Creating build.sh script ---"
cat <<EOF > build.sh
#!/bin/bash

# build.sh
# Automates the build, test, and publish process for this microservice.

set -e

echo "=========================================="
echo "Starting build process for \$MICROSERVICE_NAME"
echo "=========================================="

# Define variables
SOLUTION_PATH="\$MICROSERVICE_NAME.sln"
API_PROJECT_PATH="src/\$API_PROJECT/\$API_PROJECT.csproj"
PUBLISH_OUTPUT_DIR="./publish"
BUILD_CONFIGURATION="Release"

# --- Step 1: Restore NuGet packages ---
echo ""
echo "--- Step 1: Restoring NuGet packages ---"
dotnet restore "\$SOLUTION_PATH"
echo "NuGet packages restored successfully."

# --- Step 2: Build the entire solution ---
echo ""
echo "--- Step 2: Building solution (Configuration: \$BUILD_CONFIGURATION) ---"
dotnet build "\$SOLUTION_PATH" --configuration "\$BUILD_CONFIGURATION"
echo "Solution built successfully."

# --- Step 3: Run tests (Optional, uncomment if you have a test project) ---
# echo ""
# echo "--- Step 3: Running tests ---"
# dotnet test "src/${CORE_PROJECT}.Tests/${CORE_PROJECT}.Tests.csproj" --configuration "\$BUILD_CONFIGURATION" --no-build
# dotnet test "src/${INFRA_PROJECT}.Tests/${INFRA_PROJECT}.Tests.csproj" --configuration "\$BUILD_CONFIGURATION" --no-build
# dotnet test "src/${API_PROJECT}.Tests/${API_PROJECT}.Tests.csproj" --configuration "\$BUILD_CONFIGURATION" --no-build

# --- Step 4: Publish the API project ---
echo ""
echo "--- Step 4: Publishing \${API_PROJECT} to '\$PUBLISH_OUTPUT_DIR' ---"
if [ -d "\$PUBLISH_OUTPUT_DIR" ]; then
  echo "Cleaning existing publish directory: \$PUBLISH_OUTPUT_DIR"
  rm -rf "\$PUBLISH_OUTPUT_DIR"
fi

dotnet publish "\$API_PROJECT_PATH" --configuration "\$BUILD_CONFIGURATION" --output "\$PUBLISH_OUTPUT_DIR" --no-build
echo "\${API_PROJECT} published successfully."

echo ""
echo "=========================================="
echo "Build process for \$MICROSERVICE_NAME completed successfully!"
echo "Published artifacts are located in: \$PUBLISH_OUTPUT_DIR"
echo "=========================================="
EOF

chmod +x build.sh
echo "build.sh script created and made executable."

echo ""
echo "==================================================="
echo "Microservice '\$MICROSERVICE_NAME' scaffolded successfully!"
echo "Navigate to './\$MICROSERVICE_NAME' to get started."
echo "==================================================="