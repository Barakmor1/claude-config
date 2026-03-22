#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="$HOME/.claude"
REPOS_DIR="$HOME/Work"

# ═══════════════════════════════════════════════════════════════════════
# COVERAGE DECLARATIONS
# ═══════════════════════════════════════════════════════════════════════

EXCLUDED_REPOS=(claude-config)

# --- User-level (~/.claude/) ---

HANDLED_USER_ENTRIES=(
    CLAUDE.md settings.json
    agents commands rules hooks
)

EXCLUDED_USER_ENTRIES=(
    .credentials.json .git .last-memory-cleanup
    projects plans cache backups debug file-history
    paste-cache shell-snapshots session-env sessions
    tasks teams todos ide handoffs agent-memory
    stats-cache.json history.jsonl
    image-cache plugins lib mcp-servers
)

MD_ONLY_USER_DIRS=(agents commands rules)
FLAT_GLOB_USER_DIRS=(hooks)

# --- Project-level (<repo>/.claude/) ---

HANDLED_PROJECT_ENTRIES=(
    settings.json settings.local.json
    agents commands rules hooks docs skills
)
EXCLUDED_PROJECT_ENTRIES=()

MD_ONLY_PROJECT_DIRS=(agents commands rules)
FLAT_GLOB_PROJECT_DIRS=(hooks docs)
RECURSIVE_PROJECT_DIRS=(skills)

# ═══════════════════════════════════════════════════════════════════════
# HELPERS
# ═══════════════════════════════════════════════════════════════════════

ADDED=0
MODIFIED=0
UNCHANGED=0
REMOVED=0
declare -a STALE_FILES=()
declare -a NEW_REPOS=()
declare -a DISAPPEARED_REPOS=()

in_array() {
    local needle="$1"; shift
    for item in "$@"; do
        [[ "$item" == "$needle" ]] && return 0
    done
    return 1
}

sync_file() {
    local src="$1" dst="$2"
    mkdir -p "$(dirname "$dst")"
    if [[ ! -f "$dst" ]]; then
        cp -p "$src" "$dst"
        ((ADDED++)) || true
    elif ! cmp -s "$src" "$dst"; then
        cp -p "$src" "$dst"
        ((MODIFIED++)) || true
    else
        ((UNCHANGED++)) || true
    fi
}

remove_stale() {
    local path="$1" label="$2"
    STALE_FILES+=("$label")
    rm -f "$path"
    ((REMOVED++)) || true
    local parent
    parent=$(dirname "$path")
    while [[ "$parent" != "$SCRIPT_DIR" ]] && [[ -d "$parent" ]] && [[ -z "$(ls -A "$parent" 2>/dev/null)" ]]; do
        rmdir "$parent"
        parent=$(dirname "$parent")
    done
}

is_excluded_repo() {
    [[ ${#EXCLUDED_REPOS[@]} -eq 0 ]] && return 1
    in_array "$1" "${EXCLUDED_REPOS[@]}"
}

map_project_name() {
    local dirname="$1"
    local repos_prefix="-home-bmordeha-Work-"

    if [[ "$dirname" == "${repos_prefix}"* ]]; then
        local remainder="${dirname#$repos_prefix}"
        local best=""
        for repo_dir in "$REPOS_DIR"/*/; do
            [[ -d "$repo_dir" ]] || continue
            local repo_name
            repo_name=$(basename "$repo_dir")
            if [[ "$remainder" == "$repo_name" ]]; then
                echo "$repo_name"
                return
            fi
            if [[ "$remainder" == "$repo_name"-* ]] && (( ${#repo_name} > ${#best} )); then
                best="$repo_name"
            fi
        done
        echo "${best:-$remainder}"
    elif [[ "$dirname" == "-home-bmordeha--claude" ]]; then
        echo "claude"
    else
        echo ""
    fi
}

# ═══════════════════════════════════════════════════════════════════════
# AUDIT
# ═══════════════════════════════════════════════════════════════════════

audit() {
    local gaps=0
    echo "Running coverage audit..."

    # User-level top-level entries
    while IFS= read -r entry; do
        if ! in_array "$entry" "${HANDLED_USER_ENTRIES[@]}" && \
           ! in_array "$entry" "${EXCLUDED_USER_ENTRIES[@]}"; then
            echo "  GAP: ~/.claude/$entry — not classified"
            ((gaps++)) || true
        fi
    done < <(find "$CLAUDE_DIR" -maxdepth 1 -mindepth 1 -printf '%f\n' | sort)

    # Project-level entries
    for repo_dir in "$REPOS_DIR"/*/; do
        [[ -d "$repo_dir" ]] || continue
        local repo_name
        repo_name=$(basename "$repo_dir")
        is_excluded_repo "$repo_name" && continue
        [[ -d "$repo_dir/.claude" ]] || continue

        while IFS= read -r entry; do
            if ! in_array "$entry" "${HANDLED_PROJECT_ENTRIES[@]}" && \
               ! ( [[ ${#EXCLUDED_PROJECT_ENTRIES[@]} -gt 0 ]] && in_array "$entry" "${EXCLUDED_PROJECT_ENTRIES[@]}" ); then
                echo "  GAP: $repo_name/.claude/$entry — not classified"
                ((gaps++)) || true
            fi
        done < <(find "$repo_dir/.claude" -maxdepth 1 -mindepth 1 -printf '%f\n' 2>/dev/null)
    done

    echo ""
    if [[ $gaps -gt 0 ]]; then
        echo "AUDIT FAILED: $gaps gap(s) found. Update the script declarations."
        return 1
    else
        echo "Audit passed."
        return 0
    fi
}

# ═══════════════════════════════════════════════════════════════════════
# BACKUP
# ═══════════════════════════════════════════════════════════════════════

backup_user_level() {
    local dst="$SCRIPT_DIR/user-level"

    # Individual files
    for f in CLAUDE.md settings.json; do
        [[ -f "$CLAUDE_DIR/$f" ]] && sync_file "$CLAUDE_DIR/$f" "$dst/$f"
    done

    # MD-only dirs
    for dir in "${MD_ONLY_USER_DIRS[@]}"; do
        [[ -d "$CLAUDE_DIR/$dir" ]] || continue
        for f in "$CLAUDE_DIR/$dir/"*.md; do
            [[ -f "$f" ]] && sync_file "$f" "$dst/$dir/$(basename "$f")"
        done
    done

    # Flat-glob dirs
    for dir in "${FLAT_GLOB_USER_DIRS[@]}"; do
        [[ -d "$CLAUDE_DIR/$dir" ]] || continue
        for f in "$CLAUDE_DIR/$dir/"*; do
            [[ -f "$f" ]] && sync_file "$f" "$dst/$dir/$(basename "$f")"
        done
    done
}

backup_project_level() {
    local dst="$SCRIPT_DIR/project-level"
    declare -a active_repos=()

    for repo_dir in "$REPOS_DIR"/*/; do
        [[ -d "$repo_dir" ]] || continue
        local repo_name
        repo_name=$(basename "$repo_dir")
        is_excluded_repo "$repo_name" && continue

        local has_config=false
        [[ -f "$repo_dir/CLAUDE.md" ]] && has_config=true
        [[ -d "$repo_dir/.claude" ]] && has_config=true
        $has_config || continue

        active_repos+=("$repo_name")
        [[ -d "$dst/$repo_name" ]] || NEW_REPOS+=("$repo_name")

        local repo_dst="$dst/$repo_name"

        # Root CLAUDE.md
        [[ -f "$repo_dir/CLAUDE.md" ]] && sync_file "$repo_dir/CLAUDE.md" "$repo_dst/CLAUDE.md"

        [[ -d "$repo_dir/.claude" ]] || continue

        # Individual files
        for f in settings.json settings.local.json; do
            [[ -f "$repo_dir/.claude/$f" ]] && sync_file "$repo_dir/.claude/$f" "$repo_dst/.claude/$f"
        done

        # MD-only dirs
        for dir in "${MD_ONLY_PROJECT_DIRS[@]}"; do
            [[ -d "$repo_dir/.claude/$dir" ]] || continue
            for f in "$repo_dir/.claude/$dir/"*.md; do
                [[ -f "$f" ]] && sync_file "$f" "$repo_dst/.claude/$dir/$(basename "$f")"
            done
        done

        # Flat-glob dirs
        for dir in "${FLAT_GLOB_PROJECT_DIRS[@]}"; do
            [[ -d "$repo_dir/.claude/$dir" ]] || continue
            for f in "$repo_dir/.claude/$dir/"*; do
                [[ -f "$f" ]] && sync_file "$f" "$repo_dst/.claude/$dir/$(basename "$f")"
            done
        done

        # Recursive dirs (skills)
        for dir in "${RECURSIVE_PROJECT_DIRS[@]}"; do
            [[ -d "$repo_dir/.claude/$dir" ]] || continue
            while IFS= read -r f; do
                local rel="${f#"$repo_dir/"}"
                sync_file "$f" "$repo_dst/$rel"
            done < <(find "$repo_dir/.claude/$dir" -name "SKILL.md" -type f 2>/dev/null)
        done
    done

    # Detect disappeared repos
    if [[ -d "$dst" ]]; then
        for backed_repo in "$dst"/*/; do
            [[ -d "$backed_repo" ]] || continue
            local backed_name
            backed_name=$(basename "$backed_repo")
            if ! in_array "$backed_name" "${active_repos[@]}"; then
                DISAPPEARED_REPOS+=("$backed_name")
            fi
        done
    fi
}

backup_memory() {
    local dst="$SCRIPT_DIR/memory"

    for proj_dir in "$CLAUDE_DIR/projects"/*/; do
        [[ -d "$proj_dir/memory" ]] || continue

        local has_content=false
        for f in "$proj_dir/memory/"*.md; do
            [[ -f "$f" ]] && [[ -s "$f" ]] && has_content=true && break
        done
        $has_content || continue

        local proj_name
        proj_name=$(map_project_name "$(basename "$proj_dir")")
        [[ -n "$proj_name" ]] || continue

        for f in "$proj_dir/memory/"*.md; do
            [[ -f "$f" ]] && [[ -s "$f" ]] && sync_file "$f" "$dst/$proj_name/$(basename "$f")"
        done
    done
}

detect_stale_files() {
    local dst="$SCRIPT_DIR/user-level"

    # User-level stale files
    for dir in "${MD_ONLY_USER_DIRS[@]}" "${FLAT_GLOB_USER_DIRS[@]}"; do
        [[ -d "$dst/$dir" ]] || continue
        for backed in "$dst/$dir/"*; do
            [[ -f "$backed" ]] || continue
            local fname
            fname=$(basename "$backed")
            [[ ! -f "$CLAUDE_DIR/$dir/$fname" ]] && remove_stale "$backed" "user-level/$dir/$fname"
        done
    done

    for f in CLAUDE.md settings.json; do
        [[ -f "$dst/$f" ]] && [[ ! -f "$CLAUDE_DIR/$f" ]] && remove_stale "$dst/$f" "user-level/$f"
    done

    # Project-level stale files
    local proj_dst="$SCRIPT_DIR/project-level"
    [[ -d "$proj_dst" ]] || return 0
    for repo_dst in "$proj_dst"/*/; do
        [[ -d "$repo_dst" ]] || continue
        local repo_name
        repo_name=$(basename "$repo_dst")
        in_array "$repo_name" "${DISAPPEARED_REPOS[@]+"${DISAPPEARED_REPOS[@]}"}" && continue
        local repo_src="$REPOS_DIR/$repo_name"

        while IFS= read -r backed; do
            local rel="${backed#"$repo_dst"}"
            if [[ "$rel" == "CLAUDE.md" ]]; then
                [[ -f "$repo_src/CLAUDE.md" ]] || remove_stale "$backed" "project-level/$repo_name/$rel"
            else
                [[ -f "$repo_src/$rel" ]] || remove_stale "$backed" "project-level/$repo_name/$rel"
            fi
        done < <(find "$repo_dst" -type f 2>/dev/null)
    done
}

# ═══════════════════════════════════════════════════════════════════════
# SUMMARY
# ═══════════════════════════════════════════════════════════════════════

print_summary() {
    echo ""
    echo "═══════════════════════════════════════════"
    echo "  Backup Summary"
    echo "═══════════════════════════════════════════"
    echo "  Files: $ADDED added, $MODIFIED modified, $UNCHANGED unchanged, $REMOVED removed"

    if [[ ${#NEW_REPOS[@]} -gt 0 ]]; then
        echo "  New repos: ${NEW_REPOS[*]}"
    fi
    if [[ ${#DISAPPEARED_REPOS[@]} -gt 0 ]]; then
        echo "  WARNING — Disappeared repos (backup retained): ${DISAPPEARED_REPOS[*]}"
    fi
    if [[ ${#STALE_FILES[@]} -gt 0 ]]; then
        echo "  Removed stale:"
        for f in "${STALE_FILES[@]}"; do echo "    - $f"; done
    fi

    echo ""
    echo "  Review with 'git diff' and commit."
    echo "═══════════════════════════════════════════"
}

# ═══════════════════════════════════════════════════════════════════════
# MAIN
# ═══════════════════════════════════════════════════════════════════════

main() {
    case "${1:-}" in
        --check) audit; exit $? ;;
        --force) echo "Skipping audit..."; ;;
        --help|-h)
            echo "Usage: $0 [--check|--force]"
            echo "  (default)  Audit + backup"
            echo "  --check    Audit only"
            echo "  --force    Skip audit"
            exit 0 ;;
        *) audit || exit 1 ;;
    esac

    echo "Starting backup..."
    backup_user_level
    backup_project_level
    backup_memory
    detect_stale_files
    print_summary
}

main "$@"
