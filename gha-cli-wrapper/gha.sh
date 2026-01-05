#!/bin/bash

# Ensure yq is installed (needed to parse YAML inputs)
if ! command -v yq &> /dev/null; then
    echo "Error: 'yq' is required for this script."
    echo "Install it via: brew install yq (Mac) or dnf install yq (Linux)"
    exit 1
fi

# Ensure yq is installed (needed to parse YAML inputs)
if ! command -v gh &> /dev/null; then
    echo "Error: 'gh' is required for this script."
    echo "Install it via: brew install yq (Mac) or dnf install gh-cli (Linux)"
    exit 1
fi

LOGGED_IN_STATE=$(gh auth status 2>&1)

if ! echo "$LOGGED_IN_STATE" | grep -q "Logged in"; then
    echo "You are not logged in to GitHub. Please run 'gh auth login' to log in."
    exit 1
fi

# Load configuration from YAML
CONFIG_FILE="$(dirname "$0")/config.yaml"

if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "Error: config.yaml not found at $CONFIG_FILE"
    echo "Create a config.yaml file with repositories and their branches."
    exit 1
fi

# Read owner from config
OWNER=$(yq -r '.owner' "$CONFIG_FILE")

if [[ -z "$OWNER" || "$OWNER" == "null" ]]; then
    echo "Error: 'owner' not defined in config.yaml"
    exit 1
fi

# Build repo list from config
REPO_NAMES=$(yq -r '.repositories | keys | .[]' "$CONFIG_FILE")

if [[ -z "$REPO_NAMES" ]]; then
    echo "Error: No repositories defined in config.yaml"
    exit 1
fi

# Format repos with owner prefix for display
REPO_LIST=""
while IFS= read -r repo; do
    REPO_LIST+="${OWNER}/${repo}"$'\n'
done <<< "$REPO_NAMES"

echo "repo list = ${REPO_LIST}"

# Select repository
REPO=$(echo "${REPO_LIST}" | fzf --header "SELECT A REPO:" --header-border)

if [[ -z "$REPO" ]]; then
    echo "No repository selected."
    exit 1
fi

echo "REPO = ${REPO}"

# Extract repo name (without owner prefix) for config lookup
REPO_NAME="${REPO#${OWNER}/}"

# Get branches for the selected repo from config
BRANCH_LIST=$(yq -r ".repositories[\"$REPO_NAME\"].branches | .[]" "$CONFIG_FILE")

if [[ -z "$BRANCH_LIST" ]]; then
    echo "Error: No branches defined for '$REPO_NAME' in config.yaml"
    exit 1
fi

echo "Available branches for $REPO_NAME:"
echo "$BRANCH_LIST"

# Select branch
BRANCH=$(echo "${BRANCH_LIST}" | fzf --header "SELECT A BRANCH:" --header-border)

if [[ -z "$BRANCH" ]]; then
    echo "No branch selected."
    exit 1
fi

echo "BRANCH = ${BRANCH}"

# SELECTED_LINE=$(gh workflow list -R "${REPO}" | fzf --header "NAME    STATUS  ID" --header-border)
#
# WORKFLOW_NAME=$(echo "$SELECTED_LINE" | awk '{$NF=""; $(NF-1)=""; print $0}' | xargs)


# 1. Fetch Name, State, ID using 'tablerow' for perfect alignment
#    We strip the default 'Age' column to keep it clean.
LIST_OUTPUT=$(gh workflow list -R "${REPO}" --all --json name,state,id --template '{{range .}}{{tablerow .name .state .id}}{{end}}')

# 2. Pipe to fzf
#    --with-nth 1..-2 : Tells fzf to display everything EXCLUDING the last column (ID)
#    We keep the ID in the data so we can extract it if needed, even though it's hidden.
# SELECTED_LINE=$(echo "$LIST_OUTPUT" | fzf --header "NAME  STATUS  ID" --header-border --with-nth 1..-2)
SELECTED_LINE=$(echo "$LIST_OUTPUT" | fzf --header "NAME STATUS ID" --header-border)

echo "Selected line : ${SELECTED_LINE}"

# 3. Validation
if [[ -z "$SELECTED_LINE" ]]; then
    echo "No workflow selected."
    exit 1
fi

# 4. Extract the Name
#    NF-=2 : Tells awk to drop the last 2 fields (ID and Status) and print the rest (The Name)
WORKFLOW_NAME=$(echo "$SELECTED_LINE" | awk '{$NF=""; $(NF-1)=""; print $0}' | xargs)

echo "Loading inputs for: $WORKFLOW_NAME..."

# 2. PARSE INPUTS (Bash 3.2 Compatible)
# Cache the workflow YAML to avoid multiple API calls
WORKFLOW_YAML=$(gh workflow view --ref "$BRANCH" "$WORKFLOW_NAME" -R "${REPO}" --yaml 2>/dev/null)

# We read keys into a standard array
INPUT_KEYS_RAW=$(echo "$WORKFLOW_YAML" | yq -r '.on.workflow_dispatch.inputs | keys | .[]' 2>/dev/null)
echo "Input keys raw: $INPUT_KEYS_RAW"

# Convert newline-separated string to array
IFS=$'\n' read -rd '' -a KEY_LIST <<< "$INPUT_KEYS_RAW"

# Initialize arrays for values, types, options, and defaults
VAL_LIST=()
TYPE_LIST=()
OPTIONS_LIST=()
DEFAULT_LIST=()

for i in "${!KEY_LIST[@]}"; do
    k="${KEY_LIST[$i]}"
    
    # Get the type for this input (default to 'string' if not specified)
    input_type=$(echo "$WORKFLOW_YAML" | yq -r ".on.workflow_dispatch.inputs[\"$k\"].type // \"string\"" 2>/dev/null)
    TYPE_LIST[$i]="$input_type"
    
    # Get the default value (empty string if not specified)
    default_val=$(echo "$WORKFLOW_YAML" | yq -r ".on.workflow_dispatch.inputs[\"$k\"].default // \"\"" 2>/dev/null)
    DEFAULT_LIST[$i]="$default_val"
    
    # Pre-populate value with default
    VAL_LIST[$i]="$default_val"
    
    # Get options if it's a choice type
    if [[ "$input_type" == "choice" ]]; then
        options_raw=$(echo "$WORKFLOW_YAML" | yq -r ".on.workflow_dispatch.inputs[\"$k\"].options | .[]" 2>/dev/null)
        OPTIONS_LIST[$i]="$options_raw"
    else
        OPTIONS_LIST[$i]=""
    fi
done

# 3. INTERACTIVE LOOP
while true; do
    MENU_ITEMS="🚀 EXECUTE WORKFLOW"
    
    # Build menu using indices to map keys to values
    if [[ ${#KEY_LIST[@]} -gt 0 ]]; then
        for i in "${!KEY_LIST[@]}"; do
            k="${KEY_LIST[$i]}"
            v="${VAL_LIST[$i]}"
            t="${TYPE_LIST[$i]}"
            d="${DEFAULT_LIST[$i]}"
            opts="${OPTIONS_LIST[$i]}"
            
            # Format type display
            case "$t" in
                "boolean") type_label="[bool]" ;;
                "choice")  type_label="[choice: ${opts//$'\n'/, }]" ;;
                "string")  type_label="[str]" ;;
                *)         type_label="[$t]" ;;
            esac
            
            # Show value with default indicator if using default
            if [[ -z "$v" ]]; then
                val_display="(empty)"
            elif [[ "$v" == "$d" && -n "$d" ]]; then
                val_display="$v (default)"
            else
                val_display="$v"
            fi
            
            # Display: 📝 publish [bool] : true (default)
            MENU_ITEMS+=$'\n'"📝 $k $type_label : $val_display"
        done
    fi

    SELECTION=$(echo "$MENU_ITEMS" | fzf --header "CONFIGURE INPUTS" --header-border)

    if [[ -z "$SELECTION" ]]; then echo "Cancelled."; exit 0; fi
    if [[ "$SELECTION" == "🚀 EXECUTE WORKFLOW" ]]; then break; fi

    # Extract the key name (2nd word)
    SELECTED_KEY_NAME=$(echo "$SELECTION" | awk '{print $2}')

    # Find which index this key belongs to
    TARGET_INDEX=-1
    for i in "${!KEY_LIST[@]}"; do
        if [[ "${KEY_LIST[$i]}" == "$SELECTED_KEY_NAME" ]]; then
            TARGET_INDEX=$i
            break
        fi
    done

    # Prompt for value based on type
    SELECTED_TYPE="${TYPE_LIST[$TARGET_INDEX]}"
    SELECTED_OPTIONS="${OPTIONS_LIST[$TARGET_INDEX]}"

    case "$SELECTED_TYPE" in
        "boolean")
            NEW_VALUE=$(printf "true\nfalse" | fzf --header "Select value for '$SELECTED_KEY_NAME'" --header-border)
            ;;
        "choice")
            NEW_VALUE=$(echo "$SELECTED_OPTIONS" | fzf --header "Select value for '$SELECTED_KEY_NAME'" --header-border)
            ;;
        *)
            read -p "Enter value for '$SELECTED_KEY_NAME': " NEW_VALUE
            ;;
    esac

    # Only update if a value was selected (not cancelled)
    if [[ -n "$NEW_VALUE" ]]; then
        VAL_LIST[$TARGET_INDEX]="$NEW_VALUE"
    fi
done

# 4. BUILD COMMAND ARGUMENTS ARRAY
CMD_ARGS=()
CMD_DISPLAY=""
if [[ ${#KEY_LIST[@]} -gt 0 ]]; then
    for i in "${!KEY_LIST[@]}"; do
        k="${KEY_LIST[$i]}"
        v="${VAL_LIST[$i]}"
        if [[ -n "$v" ]]; then
            CMD_ARGS+=("-f" "$k=$v")
            CMD_DISPLAY+=" -f $k=\"$v\""
        fi
    done
fi

# 5. SHOW COMMAND AND CONFIRM
echo ""
echo "════════════════════════════════════════════════════════════════"
echo "🚀 COMMAND TO EXECUTE:"
echo "────────────────────────────────────────────────────────────────"
echo "gh workflow run \"$WORKFLOW_NAME\" -R \"$REPO\" --ref \"$BRANCH\"$CMD_DISPLAY"
echo "════════════════════════════════════════════════════════════════"

# Show inputs table if there are any configured inputs
if [[ ${#KEY_LIST[@]} -gt 0 ]]; then
    echo ""
    echo "📋 INPUT PARAMETERS:"
    echo "────────────────────────────────────────────────────────────────"
    for i in "${!KEY_LIST[@]}"; do
        k="${KEY_LIST[$i]}"
        v="${VAL_LIST[$i]}"
        if [[ -n "$v" ]]; then
            printf "  %-25s = %s\n" "$k" "$v"
        else
            printf "  %-25s = %s\n" "$k" "(not set)"
        fi
    done
    echo "────────────────────────────────────────────────────────────────"
fi
echo ""

read -p "Do you want to proceed? (y/N): " confirm
if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
    echo "Cancelled."
    exit 0
fi

# 6. EXECUTE
echo "🚀 Triggering Workflow..."
gh workflow run "$WORKFLOW_NAME" -R "$REPO" --ref "$BRANCH" "${CMD_ARGS[@]}"

echo ""
echo "✅ Workflow triggered successfully!"
echo ""

# 7. OFFER TO OPEN IN BROWSER
read -p "Open workflow in browser? (y/N): " open_browser
if [[ "$open_browser" =~ ^[Yy]$ ]]; then
    echo "🌐 Opening workflow in browser..."
    gh workflow view "$WORKFLOW_NAME" -R "$REPO" --web
fi

