#!/bin/bash
set -e

# ============================================================================
# Agentize SDK Installation Script
# ============================================================================

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Parse arguments
MASTER_PROJ="${1:?Error: Missing AGENTIZE_MASTER_PROJ argument}"
PROJ_NAME="${2:-MyProject}"
PROJ_DESC="${3:-A software project}"
MODE="${4:-init}"
LANG="${5:-}"
IMPL_DIR="${6:-src}"

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AGENTIZE_ROOT="$(dirname "$SCRIPT_DIR")"

# ============================================================================
# Helper Functions
# ============================================================================

log_info() {
    echo -e "${BLUE}ℹ${NC}  $1"
}

log_success() {
    echo -e "${GREEN}✓${NC}  $1"
}

log_warning() {
    echo -e "${YELLOW}⚠${NC}  $1"
}

log_error() {
    echo -e "${RED}✗${NC}  $1"
}

# Transform project name to snake_case for Python/Rust packages
transform_project_name() {
    echo "$PROJ_NAME" | tr '[:upper:]' '[:lower:]' | tr ' -' '_' | sed 's/[^a-z0-9_]//g'
}

# Transform project name to alphanumeric for CMake
transform_project_name_cmake() {
    echo "$PROJ_NAME" | sed 's/[^a-zA-Z0-9_]//g'
}

# Detect languages and set flags
detect_languages() {
    HAS_PYTHON=false
    HAS_C=false
    HAS_CPP=false
    HAS_RUST=false

    # Default to C++ if no language specified
    if [ -z "$LANG" ]; then
        HAS_CPP=true
        log_info "No language specified, defaulting to C++"
        return
    fi

    # Parse comma-separated language list
    IFS=',' read -ra LANGS <<< "$LANG"
    for lang in "${LANGS[@]}"; then
        # Trim whitespace
        lang=$(echo "$lang" | tr -d ' ')
        case "$lang" in
            python|py)
                HAS_PYTHON=true
                ;;
            c)
                HAS_C=true
                ;;
            cpp|cxx|c++)
                HAS_CPP=true
                ;;
            rust|rs)
                HAS_RUST=true
                ;;
            *)
                log_warning "Unknown language: $lang (ignoring)"
                ;;
        esac
    done

    # Log detected languages
    local detected=""
    $HAS_PYTHON && detected="${detected}Python "
    $HAS_C && detected="${detected}C "
    $HAS_CPP && detected="${detected}C++ "
    $HAS_RUST && detected="${detected}Rust "

    if [ -n "$detected" ]; then
        log_info "Detected languages: $detected"
    fi
}

# ============================================================================
# Validation
# ============================================================================

validate_target_project() {
    log_info "Validating target project: $MASTER_PROJ"

    if [ ! -d "$MASTER_PROJ" ]; then
        log_error "Target directory does not exist: $MASTER_PROJ"
        exit 1
    fi

    # Check if .claude already exists
    if [ -d "$MASTER_PROJ/.claude" ]; then
        log_warning ".claude directory already exists at $MASTER_PROJ/.claude"
        read -p "Overwrite? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_info "Installation cancelled by user"
            exit 0
        fi
        rm -rf "$MASTER_PROJ/.claude"
    fi

    # Validate mode
    if [ "$MODE" != "init" ] && [ "$MODE" != "port" ]; then
        log_error "Invalid mode: $MODE (must be 'init' or 'port')"
        exit 1
    fi

    log_success "Validation complete"
}

# ============================================================================
# Directory Structure Creation
# ============================================================================

create_directory_structure() {
    log_info "Creating .claude/ directory structure..."

    mkdir -p "$MASTER_PROJ/.claude"
    mkdir -p "$MASTER_PROJ/.claude/agents"
    mkdir -p "$MASTER_PROJ/.claude/commands"
    mkdir -p "$MASTER_PROJ/.claude/rules"
    mkdir -p "$MASTER_PROJ/.claude/skills"
    mkdir -p "$MASTER_PROJ/.claude/hooks"

    log_success "Directory structure created"
}

# ============================================================================
# Component Copying
# ============================================================================

copy_components() {
    log_info "Copying AI workflow components..."

    # Copy agents
    if [ -d "$AGENTIZE_ROOT/claude/agents" ]; then
        cp "$AGENTIZE_ROOT/claude/agents"/*.md "$MASTER_PROJ/.claude/agents/" 2>/dev/null || true
        local agent_count=$(ls -1 "$AGENTIZE_ROOT/claude/agents"/*.md 2>/dev/null | wc -l | tr -d ' ')
        log_success "Copied $agent_count agents"
    fi

    # Copy commands
    if [ -d "$AGENTIZE_ROOT/claude/commands" ]; then
        cp "$AGENTIZE_ROOT/claude/commands"/*.md "$MASTER_PROJ/.claude/commands/" 2>/dev/null || true
        local cmd_count=$(ls -1 "$AGENTIZE_ROOT/claude/commands"/*.md 2>/dev/null | wc -l | tr -d ' ')
        log_success "Copied $cmd_count commands"
    fi

    # Copy rules
    if [ -d "$AGENTIZE_ROOT/claude/rules" ]; then
        cp "$AGENTIZE_ROOT/claude/rules"/*.md "$MASTER_PROJ/.claude/rules/" 2>/dev/null || true
        local rule_count=$(ls -1 "$AGENTIZE_ROOT/claude/rules"/*.md 2>/dev/null | wc -l | tr -d ' ')
        log_success "Copied $rule_count rules"
    fi

    # Copy skills
    if [ -d "$AGENTIZE_ROOT/claude/skills" ]; then
        cp "$AGENTIZE_ROOT/claude/skills"/*.md "$MASTER_PROJ/.claude/skills/" 2>/dev/null || true
        local skill_count=$(ls -1 "$AGENTIZE_ROOT/claude/skills"/*.md 2>/dev/null | wc -l | tr -d ' ')
        log_success "Copied $skill_count skills"
    fi

    # Copy hooks
    if [ -d "$AGENTIZE_ROOT/claude/hooks" ]; then
        cp -r "$AGENTIZE_ROOT/claude/hooks"/* "$MASTER_PROJ/.claude/hooks/" 2>/dev/null || true
        log_success "Copied hooks"
    fi

    # Copy README
    if [ -f "$AGENTIZE_ROOT/claude/README.md" ]; then
        cp "$AGENTIZE_ROOT/claude/README.md" "$MASTER_PROJ/.claude/README.md"
        log_success "Copied README.md"
    fi
}

# ============================================================================
# Language Template Copying
# ============================================================================

copy_language_template() {
    if [ "$MODE" != "init" ]; then
        return
    fi

    log_info "Copying language-specific project templates..."

    # Get transformed project names
    local proj_snake=$(transform_project_name)
    local proj_cmake=$(transform_project_name_cmake)
    local proj_upper=$(echo "$proj_snake" | tr '[:lower:]' '[:upper:]')

    # Escape special characters for sed
    local proj_name_escaped=$(echo "$PROJ_NAME" | sed 's/[\/&]/\\&/g')
    local proj_desc_escaped=$(echo "$PROJ_DESC" | sed 's/[\/&]/\\&/g')
    local proj_snake_escaped=$(echo "$proj_snake" | sed 's/[\/&]/\\&/g')
    local proj_cmake_escaped=$(echo "$proj_cmake" | sed 's/[\/&]/\\&/g')
    local proj_upper_escaped=$(echo "$proj_upper" | sed 's/[\/&]/\\&/g')

    # Helper function to process a single file
    process_template_file() {
        local src_file="$1"
        local dest_file="$2"

        # Replace directory names
        dest_file=$(echo "$dest_file" | sed "s/__NAME__/$proj_snake/g")

        # Create parent directory if needed
        mkdir -p "$(dirname "$dest_file")"

        # Skip if destination already exists
        if [ -f "$dest_file" ]; then
            log_info "Skipping existing file: $(basename "$dest_file")"
            return
        fi

        # Process file content with substitutions
        sed -e "s/\${PROJECT_NAME}/$proj_name_escaped/g" \
            -e "s/\${PROJ_DESC}/$proj_desc_escaped/g" \
            -e "s/__PROJECT_NAME__/$proj_cmake_escaped/g" \
            -e "s/__NAME_UPPER__/$proj_upper_escaped/g" \
            -e "s/__NAME__/$proj_snake_escaped/g" \
            "$src_file" > "$dest_file"

        # Preserve executable bit
        [ -x "$src_file" ] && chmod +x "$dest_file"
    }

    # Copy Python template
    if $HAS_PYTHON; then
        log_info "Copying Python project template..."
        local template_dir="$AGENTIZE_ROOT/templates/python"

        if [ -d "$template_dir" ]; then
            # Find all files in template directory
            while IFS= read -r -d '' file; do
                local rel_path="${file#$template_dir/}"
                local dest_path="$MASTER_PROJ/$rel_path"
                process_template_file "$file" "$dest_path"
            done < <(find "$template_dir" -type f -print0)

            log_success "Python template copied"
        else
            log_warning "Python template directory not found: $template_dir"
        fi
    fi

    # Copy C++ template
    if $HAS_CPP; then
        log_info "Copying C++ project template..."
        local template_dir="$AGENTIZE_ROOT/templates/cxx"

        if [ -d "$template_dir" ]; then
            while IFS= read -r -d '' file; do
                local rel_path="${file#$template_dir/}"
                local dest_path="$MASTER_PROJ/$rel_path"
                process_template_file "$file" "$dest_path"
            done < <(find "$template_dir" -type f -print0)

            log_success "C++ template copied"
        else
            log_warning "C++ template directory not found: $template_dir"
        fi
    fi

    # Copy C template
    if $HAS_C; then
        log_info "Copying C project template..."
        local template_dir="$AGENTIZE_ROOT/templates/c"

        if [ -d "$template_dir" ]; then
            while IFS= read -r -d '' file; do
                local rel_path="${file#$template_dir/}"
                local dest_path="$MASTER_PROJ/$rel_path"
                process_template_file "$file" "$dest_path"
            done < <(find "$template_dir" -type f -print0)

            log_success "C template copied"
        else
            log_warning "C template directory not found: $template_dir"
        fi
    fi

    # Initialize Rust project
    if $HAS_RUST; then
        log_info "Initializing Rust project with cargo..."

        if command -v cargo &> /dev/null; then
            (cd "$MASTER_PROJ" && cargo init --name "$proj_snake" --quiet 2>/dev/null || cargo init --name "$proj_snake")
            log_success "Rust project initialized"
        else
            log_warning "cargo not found, skipping Rust initialization"
            log_warning "Install Rust from https://rustup.rs/"
        fi
    fi
}

# ============================================================================
# Template Processing
# ============================================================================

process_templates() {
    log_info "Processing templates with project-specific values..."

    # Escape special characters for sed
    PROJ_NAME_ESCAPED=$(echo "$PROJ_NAME" | sed 's/[\/&]/\\&/g')
    PROJ_DESC_ESCAPED=$(echo "$PROJ_DESC" | sed 's/[\/&]/\\&/g')
    MASTER_PROJ_ESCAPED=$(echo "$MASTER_PROJ" | sed 's/[\/&]/\\&/g')

    # Process CLAUDE.md template
    if [ -f "$AGENTIZE_ROOT/claude/templates/CLAUDE.md.template" ]; then
        sed -e "s/\${PROJECT_NAME}/$PROJ_NAME_ESCAPED/g" \
            -e "s/\${PROJ_DESC}/$PROJ_DESC_ESCAPED/g" \
            "$AGENTIZE_ROOT/claude/templates/CLAUDE.md.template" \
            > "$MASTER_PROJ/.claude/CLAUDE.md"
        log_success "Created .claude/CLAUDE.md"
    fi

    # Process git-tags.template.md
    if [ -f "$AGENTIZE_ROOT/claude/templates/git-tags.template.md" ]; then
        sed -e "s/\${PROJECT_NAME}/$PROJ_NAME_ESCAPED/g" \
            "$AGENTIZE_ROOT/claude/templates/git-tags.template.md" \
            > "$MASTER_PROJ/.claude/git-tags.md"
        log_success "Created .claude/git-tags.md"
    fi

    # Process settings.json template
    if [ -f "$AGENTIZE_ROOT/claude/templates/settings.json.template" ]; then
        sed -e "s/\${PROJECT_NAME}/$PROJ_NAME_ESCAPED/g" \
            -e "s|\${MASTER_PROJ}|$MASTER_PROJ_ESCAPED|g" \
            "$AGENTIZE_ROOT/claude/templates/settings.json.template" \
            > "$MASTER_PROJ/.claude/settings.json"
        log_success "Created .claude/settings.json"
    fi

    # Copy PROJECT_CONFIG.md (no substitution needed)
    if [ -f "$AGENTIZE_ROOT/claude/templates/PROJECT_CONFIG.md" ]; then
        cp "$AGENTIZE_ROOT/claude/templates/PROJECT_CONFIG.md" \
           "$MASTER_PROJ/.claude/PROJECT_CONFIG.md"
        log_success "Created .claude/PROJECT_CONFIG.md"
    fi
}

# ============================================================================
# Mode-Specific Initialization
# ============================================================================

initialize_project() {
    if [ "$MODE" = "init" ]; then
        log_info "Initializing new project structure (mode: init)..."

        # Create docs/ folder with docs/CLAUDE.md
        mkdir -p "$MASTER_PROJ/docs"
        if [ -f "$AGENTIZE_ROOT/claude/templates/docs-CLAUDE.md.template" ]; then
            sed -e "s/\${PROJECT_NAME}/$PROJ_NAME_ESCAPED/g" \
                -e "s/\${PROJ_DESC}/$PROJ_DESC_ESCAPED/g" \
                "$AGENTIZE_ROOT/claude/templates/docs-CLAUDE.md.template" \
                > "$MASTER_PROJ/docs/CLAUDE.md"
            log_success "Created docs/CLAUDE.md"
        fi

        # Create README.md stub
        if [ ! -f "$MASTER_PROJ/README.md" ] && [ -f "$AGENTIZE_ROOT/claude/templates/project-README.md.template" ]; then
            sed -e "s/\${PROJECT_NAME}/$PROJ_NAME_ESCAPED/g" \
                -e "s/\${PROJ_DESC}/$PROJ_DESC_ESCAPED/g" \
                "$AGENTIZE_ROOT/claude/templates/project-README.md.template" \
                > "$MASTER_PROJ/README.md"
            log_success "Created README.md"
        else
            log_info "README.md already exists, skipping"
        fi

        # Create .gitignore
        if [ ! -f "$MASTER_PROJ/.gitignore" ] && [ -f "$AGENTIZE_ROOT/claude/templates/project-gitignore.template" ]; then
            cp "$AGENTIZE_ROOT/claude/templates/project-gitignore.template" \
               "$MASTER_PROJ/.gitignore"
            log_success "Created .gitignore"
        else
            log_info ".gitignore already exists, skipping"
        fi

        # Create setup.sh template
        if [ ! -f "$MASTER_PROJ/setup.sh" ] && [ -f "$AGENTIZE_ROOT/claude/templates/project-setup.sh.template" ]; then
            cp "$AGENTIZE_ROOT/claude/templates/project-setup.sh.template" \
               "$MASTER_PROJ/setup.sh"
            chmod +x "$MASTER_PROJ/setup.sh"
            log_success "Created setup.sh"
        else
            log_info "setup.sh already exists, skipping"
        fi

    elif [ "$MODE" = "port" ]; then
        log_info "Porting to existing project (mode: port) - .claude/ only"
    fi
}

# ============================================================================
# Enhanced Makefile Generation
# ============================================================================

generate_enhanced_makefile() {
    if [ "$MODE" != "init" ]; then
        return
    fi

    if [ -f "$MASTER_PROJ/Makefile" ]; then
        log_info "Makefile already exists, skipping generation"
        return
    fi

    log_info "Generating language-aware Makefile..."

    # Build language flags
    local lang_flags=""
    $HAS_PYTHON && lang_flags="${lang_flags}HAS_PYTHON := true\n"
    $HAS_C && lang_flags="${lang_flags}HAS_C := true\n"
    $HAS_CPP && lang_flags="${lang_flags}HAS_CPP := true\n"
    $HAS_RUST && lang_flags="${lang_flags}HAS_RUST := true\n"

    # Build help targets
    local help_targets=""
    $HAS_PYTHON && help_targets="${help_targets}\t@echo \"  py-test     - Run Python tests with pytest\"\n"
    $HAS_CPP && help_targets="${help_targets}\t@echo \"  cmake-build - Build C/C++ project with CMake\"\n"
    $HAS_C && help_targets="${help_targets}\t@echo \"  cmake-build - Build C/C++ project with CMake\"\n"
    $HAS_RUST && help_targets="${help_targets}\t@echo \"  cargo-build - Build Rust project with cargo\"\n"

    # Build environment setup
    local env_setup=""
    if $HAS_PYTHON; then
        env_setup="${env_setup}# Python environment\n"
        env_setup="${env_setup}export PYTHONPATH=\"\\\$\\\$PWD/${IMPL_DIR}:\\\$\\\$PYTHONPATH\"\n\n"
    fi
    if $HAS_RUST; then
        env_setup="${env_setup}# Rust environment\n"
        env_setup="${env_setup}export PATH=\"\\\$\\\$PWD/target/release:\\\$\\\$PATH\"\n\n"
    fi
    if $HAS_CPP || $HAS_C; then
        env_setup="${env_setup}# C/C++ build environment\n"
        env_setup="${env_setup}export PATH=\"\\\$\\\$PWD/build/bin:\\\$\\\$PATH\"\n\n"
    fi

    # Build commands
    local build_deps=""
    local build_commands=""
    if $HAS_CPP || $HAS_C; then
        build_deps="${build_deps} cmake-build"
        build_commands="${build_commands}\t@\$(MAKE) -s cmake-build\n"
    fi
    if $HAS_PYTHON; then
        build_deps="${build_deps} py-build"
        build_commands="${build_commands}\t@\$(MAKE) -s py-build\n"
    fi
    if $HAS_RUST; then
        build_deps="${build_deps} cargo-build"
        build_commands="${build_commands}\t@\$(MAKE) -s cargo-build\n"
    fi

    # Test commands
    local test_deps=""
    local test_commands=""
    if $HAS_CPP || $HAS_C; then
        test_deps="${test_deps} cmake-test"
        test_commands="${test_commands}\t@\$(MAKE) -s cmake-test\n"
    fi
    if $HAS_PYTHON; then
        test_deps="${test_deps} py-test"
        test_commands="${test_commands}\t@\$(MAKE) -s py-test\n"
    fi
    if $HAS_RUST; then
        test_deps="${test_deps} cargo-test"
        test_commands="${test_commands}\t@\$(MAKE) -s cargo-test\n"
    fi

    # Lint commands
    local lint_commands=""
    if $HAS_PYTHON; then
        lint_commands="${lint_commands}\t@echo \"Linting Python code...\"\n"
        lint_commands="${lint_commands}\t@command -v ruff >/dev/null 2>&1 && ruff check ${IMPL_DIR} || echo \"  (install ruff for Python linting)\"\n"
    fi
    if $HAS_RUST; then
        lint_commands="${lint_commands}\t@echo \"Linting Rust code...\"\n"
        lint_commands="${lint_commands}\t@cargo clippy --all-targets --all-features 2>/dev/null || echo \"  (cargo clippy not available)\"\n"
    fi
    if $HAS_CPP || $HAS_C; then
        lint_commands="${lint_commands}\t@echo \"Linting C/C++ code...\"\n"
        lint_commands="${lint_commands}\t@command -v clang-tidy >/dev/null 2>&1 && echo \"  (run clang-tidy manually)\" || echo \"  (install clang-tidy for C/C++ linting)\"\n"
    fi
    [ -z "$lint_commands" ] && lint_commands="\t@echo \"No linters configured\"\n"

    # Clean commands
    local clean_commands=""
    if $HAS_CPP || $HAS_C; then
        clean_commands="${clean_commands}\t@rm -rf \$(BUILD_DIR)\n"
    fi
    if $HAS_PYTHON; then
        clean_commands="${clean_commands}\t@find . -type d -name '__pycache__' -exec rm -rf {} + 2>/dev/null || true\n"
        clean_commands="${clean_commands}\t@find . -type f -name '*.pyc' -delete 2>/dev/null || true\n"
    fi
    if $HAS_RUST; then
        clean_commands="${clean_commands}\t@cargo clean 2>/dev/null || true\n"
    fi

    # Language-specific targets
    local language_targets=""

    if $HAS_PYTHON; then
        language_targets="${language_targets}.PHONY: py-build\npy-build:\n"
        language_targets="${language_targets}\t@echo \"Building Python project...\"\n"
        language_targets="${language_targets}\t@pip install -e . 2>/dev/null || echo \"  (run 'pip install -e .' manually)\"\n\n"

        language_targets="${language_targets}.PHONY: py-test\npy-test:\n"
        language_targets="${language_targets}\t@echo \"Running Python tests...\"\n"
        language_targets="${language_targets}\t@pytest \$(TEST_DIR) -v 2>/dev/null || echo \"  (install pytest: pip install pytest)\"\n\n"
    fi

    if $HAS_CPP || $HAS_C; then
        language_targets="${language_targets}.PHONY: cmake-build\ncmake-build:\n"
        language_targets="${language_targets}\t@echo \"Building with CMake...\"\n"
        language_targets="${language_targets}\t@cmake -B \$(BUILD_DIR) -DCMAKE_BUILD_TYPE=Release 2>/dev/null || echo \"  (CMake not found)\"\n"
        language_targets="${language_targets}\t@cmake --build \$(BUILD_DIR) 2>/dev/null || true\n\n"

        language_targets="${language_targets}.PHONY: cmake-test\ncmake-test:\n"
        language_targets="${language_targets}\t@echo \"Running CMake tests...\"\n"
        language_targets="${language_targets}\t@cd \$(BUILD_DIR) && ctest --output-on-failure 2>/dev/null || echo \"  (no tests configured)\"\n\n"
    fi

    if $HAS_RUST; then
        language_targets="${language_targets}.PHONY: cargo-build\ncargo-build:\n"
        language_targets="${language_targets}\t@echo \"Building with Cargo...\"\n"
        language_targets="${language_targets}\t@cargo build --release\n\n"

        language_targets="${language_targets}.PHONY: cargo-test\ncargo-test:\n"
        language_targets="${language_targets}\t@echo \"Running Cargo tests...\"\n"
        language_targets="${language_targets}\t@cargo test\n\n"
    fi

    # Generate Makefile from template
    if [ -f "$AGENTIZE_ROOT/claude/templates/project-Makefile.template" ]; then
        sed -e "s/\${PROJECT_NAME}/$PROJ_NAME_ESCAPED/g" \
            -e "s/\${IMPL_DIR}/$IMPL_DIR/g" \
            -e "s/\${LANG_FLAGS}/$lang_flags/g" \
            -e "s/\${HELP_TARGETS}/$help_targets/g" \
            -e "s/\${ENV_SETUP}/$env_setup/g" \
            -e "s/\${BUILD_DEPS}/$build_deps/g" \
            -e "s/\${BUILD_COMMANDS}/$build_commands/g" \
            -e "s/\${TEST_DEPS}/$test_deps/g" \
            -e "s/\${TEST_COMMANDS}/$test_commands/g" \
            -e "s/\${LINT_COMMANDS}/$lint_commands/g" \
            -e "s/\${CLEAN_COMMANDS}/$clean_commands/g" \
            -e "s/\${LANGUAGE_TARGETS}/$language_targets/g" \
            "$AGENTIZE_ROOT/claude/templates/project-Makefile.template" \
            > "$MASTER_PROJ/Makefile"
        log_success "Created language-aware Makefile"
    fi
}

# ============================================================================
# Gitignore Enhancement
# ============================================================================

append_gitignore_patterns() {
    if [ "$MODE" != "init" ]; then
        return
    fi

    if [ ! -f "$MASTER_PROJ/.gitignore" ]; then
        return
    fi

    log_info "Appending language-specific .gitignore patterns..."

    local patterns_added=false

    # Python patterns
    if $HAS_PYTHON; then
        if ! grep -q "__pycache__" "$MASTER_PROJ/.gitignore" 2>/dev/null; then
            cat >> "$MASTER_PROJ/.gitignore" <<'EOF'

# Python
__pycache__/
*.py[cod]
*$py.class
*.so
.Python
venv/
env/
ENV/
.pytest_cache/
.coverage
htmlcov/
dist/
build/
*.egg-info/
EOF
            patterns_added=true
        fi
    fi

    # C/C++ patterns
    if $HAS_CPP || $HAS_C; then
        if ! grep -q "CMakeCache.txt" "$MASTER_PROJ/.gitignore" 2>/dev/null; then
            cat >> "$MASTER_PROJ/.gitignore" <<'EOF'

# C/C++
*.o
*.a
*.so
*.exe
*.out
build/
CMakeCache.txt
CMakeFiles/
cmake_install.cmake
Makefile.cmake
CTestTestfile.cmake
compile_commands.json
EOF
            patterns_added=true
        fi
    fi

    # Rust patterns
    if $HAS_RUST; then
        if ! grep -q "target/" "$MASTER_PROJ/.gitignore" 2>/dev/null; then
            cat >> "$MASTER_PROJ/.gitignore" <<'EOF'

# Rust
target/
Cargo.lock
**/*.rs.bk
EOF
            patterns_added=true
        fi
    fi

    if $patterns_added; then
        log_success "Added language-specific .gitignore patterns"
    else
        log_info "Language-specific patterns already present in .gitignore"
    fi
}

# ============================================================================
# Summary
# ============================================================================

print_summary() {
    echo ""
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}Installation Complete!${NC}"
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo "Project: $PROJ_NAME"
    echo "Location: $MASTER_PROJ"
    echo "Mode: $MODE"
    echo ""
    echo "Installed components:"
    echo "  • $(ls -1 "$MASTER_PROJ/.claude/agents"/*.md 2>/dev/null | wc -l | tr -d ' ') agents"
    echo "  • $(ls -1 "$MASTER_PROJ/.claude/commands"/*.md 2>/dev/null | wc -l | tr -d ' ') commands"
    echo "  • $(ls -1 "$MASTER_PROJ/.claude/rules"/*.md 2>/dev/null | wc -l | tr -d ' ') rules"
    echo "  • $(ls -1 "$MASTER_PROJ/.claude/skills"/*.md 2>/dev/null | wc -l | tr -d ' ') skills"

    if [ "$MODE" = "init" ]; then
        echo ""
        echo "Initialized project files:"
        [ -d "$MASTER_PROJ/docs" ] && echo "  • docs/ folder"
        [ -f "$MASTER_PROJ/docs/CLAUDE.md" ] && echo "  • docs/CLAUDE.md"
        [ -f "$MASTER_PROJ/Makefile" ] && echo "  • Makefile"
        [ -f "$MASTER_PROJ/README.md" ] && echo "  • README.md"
        [ -f "$MASTER_PROJ/.gitignore" ] && echo "  • .gitignore"
        [ -f "$MASTER_PROJ/setup.sh" ] && echo "  • setup.sh"
    fi

    echo ""
    echo -e "${BLUE}Next steps:${NC}"
    echo "  1. cd $MASTER_PROJ"
    echo "  2. Review .claude/CLAUDE.md and customize for your project"
    echo "  3. Customize .claude/git-tags.md with your project's component tags"
    echo "  4. Check .claude/PROJECT_CONFIG.md for configuration guide"
    if [ "$MODE" = "init" ]; then
        echo "  5. Run 'make build' to build your project"
        echo "  6. Run 'make test' to run tests"
        echo "  7. Update docs/CLAUDE.md with your project documentation"
    else
        echo "  5. Ensure your project has: make build, make test, source setup.sh"
    fi
    echo ""
}

# ============================================================================
# Main Execution
# ============================================================================

main() {
    echo ""
    echo "Agentize SDK Installer"
    echo "======================"
    echo ""

    validate_target_project
    detect_languages
    create_directory_structure
    copy_components
    process_templates
    copy_language_template
    initialize_project
    generate_enhanced_makefile
    append_gitignore_patterns
    print_summary
}

main
