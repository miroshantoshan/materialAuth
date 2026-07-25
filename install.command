#!/bin/zsh

set -u
set -o pipefail

REPOSITORY_ARCHIVE="https://codeload.github.com/miroshantoshan/materialAuth/tar.gz/refs/heads/main"
REPOSITORY_ARCHIVE_FALLBACK="https://github.com/miroshantoshan/materialAuth/archive/refs/heads/main.tar.gz"
USER_APPS_DIR="$HOME/Applications"
TARGET_APP="$USER_APPS_DIR/MaterialAuth.app"
WORK_DIR="$(mktemp -d -t materialauth-installer)"
LOG_FILE="$WORK_DIR/installer.log"
ARCHIVE_PATH="$WORK_DIR/materialAuth.tar.gz"
PROJECT_DIR="$WORK_DIR/materialAuth-main"
SOURCE_APP="$WORK_DIR/MaterialAuth.app"
STATUS_FILE="$WORK_DIR/status"

if [[ -d /Applications/Xcode.app/Contents/Developer ]] && \
    DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcrun --find swiftc >/dev/null 2>&1; then
    export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
fi

export CLANG_MODULE_CACHE_PATH="$WORK_DIR/module-cache"
export SWIFTPM_MODULECACHE_OVERRIDE="$WORK_DIR/swift-module-cache"
mkdir -p "$CLANG_MODULE_CACHE_PATH" "$SWIFTPM_MODULECACHE_OVERRIDE"

RESET=$'\e[0m'
BOLD=$'\e[1m'
DIM=$'\e[2m'
LIGHT_PURPLE=$'\e[38;5;183m'
PURPLE=$'\e[38;5;135m'
LIME=$'\e[38;5;154m'
RED=$'\e[38;5;203m'
GRAY=$'\e[38;5;245m'
BANNER_WIDTH=48

cleanup() {
    if [[ -d "$WORK_DIR" && "${WORK_DIR:t}" == materialauth-installer.* ]]; then
        rm -rf -- "$WORK_DIR"
    fi
}

trap cleanup EXIT

fail() {
    print ""
    print -- "${RED}${BOLD}  ✕ Installation failed${RESET}"
    print -- "${RED}  $1${RESET}"

    if [[ -s "$LOG_FILE" ]]; then
        print ""
        print -- "${LIGHT_PURPLE}  Last messages:${RESET}"
        tail -n 12 "$LOG_FILE" | sed 's/^/    /'
    fi

    print ""
    print -n -- "${GRAY}Press Enter to close this window...${RESET}"
    read -r
    exit 1
}

banner_border() {
    local left_corner="$1"
    local right_corner="$2"
    local rule
    printf -v rule '%*s' "$BANNER_WIDTH" ''
    rule="${rule// /─}"
    print -- "${LIGHT_PURPLE}${left_corner}${rule}${right_corner}${RESET}"
}

banner_line() {
    local text="${1:-}"
    local color="${2:-$RESET}"
    (( ${#text} <= BANNER_WIDTH )) || text="${text[1,$BANNER_WIDTH]}"
    local text_width=${#text}
    local left_padding=$(( (BANNER_WIDTH - text_width) / 2 ))
    local right_padding=$(( BANNER_WIDTH - text_width - left_padding ))

    print -n -- "${LIGHT_PURPLE}│${RESET}"
    printf '%*s' "$left_padding" ''
    print -n -- "${color}${text}${RESET}"
    printf '%*s' "$right_padding" ''
    print -- "${LIGHT_PURPLE}│${RESET}"
}

header() {
    if [[ -t 1 ]]; then
        print -n -- $'\e]0;MaterialAuth Installer\a'
        if [[ "${TERM_PROGRAM:-}" == "Apple_Terminal" ]]; then
            print -n -- $'\e[8;31;58t'
            sleep 0.15
        fi
        clear
    fi
    banner_border "╭" "╮"
    banner_line
    banner_line "MaterialAuth Installer" "${PURPLE}${BOLD}"
    banner_line "Secure verification codes for macOS" "$LIME"
    banner_line
    banner_border "╰" "╯"
    print ""
}

step() {
    print -- "${PURPLE}${BOLD}  $1${RESET} ${LIGHT_PURPLE}${BOLD}$2${RESET}"
    print -- "${GRAY}      $3${RESET}"
}

run_with_spinner() {
    local label="$1"
    local minimum_seconds="$2"
    shift 2

    local frames=("⠋" "⠙" "⠹" "⠸" "⠼" "⠴" "⠦" "⠧" "⠇" "⠏")
    local frame=1
    local started=$SECONDS
    local current_label status_line status_path bytes megabytes

    : >"$LOG_FILE"
    : >"$STATUS_FILE"
    "$@" >"$LOG_FILE" 2>&1 &
    local task_pid=$!

    while kill -0 "$task_pid" 2>/dev/null || (( SECONDS - started < minimum_seconds )); do
        current_label="$label"
        if [[ -s "$STATUS_FILE" ]]; then
            status_line="$(<"$STATUS_FILE")"
            current_label="${status_line%%|*}"
            status_path="${status_line#*|}"
            if [[ "$status_path" != "$status_line" && -f "$status_path" ]]; then
                bytes="$(stat -f %z "$status_path" 2>/dev/null || print 0)"
                megabytes=$(( bytes / 1024 / 1024 ))
                current_label="$current_label · ${megabytes} MB"
            fi
        fi
        print -n -- "\r\e[K${LIGHT_PURPLE}      ${frames[$frame]} $current_label · $((SECONDS - started))s${RESET}"
        frame=$((frame % ${#frames[@]} + 1))
        sleep 0.12
    done

    if wait "$task_pid"; then
        print -- "\r\e[K${LIME}      ✓ $label${RESET}"
        return 0
    fi

    print -- "\r\e[K${RED}      ✕ $label${RESET}"
    return 1
}

animate_progress() {
    local start="$1"
    local finish="$2"
    local index empty bar part

    for ((index = start; index <= finish; index++)); do
        empty=$((20 - index))
        bar=""
        for ((part = 0; part < index; part++)); do bar+="█"; done
        for ((part = 0; part < empty; part++)); do bar+="░"; done
        print -n -- "\r${PURPLE}      [${LIGHT_PURPLE}$bar${PURPLE}]${RESET}  $((index * 5))%"
        sleep 0.08
    done
    print ""
}

ensure_swift() {
    if command -v swift >/dev/null 2>&1 && swift --version >/dev/null 2>&1; then
        return 0
    fi

    step "SETUP" "Developer Tools" "Installing Apple's free Swift compiler"
    xcode-select --install >/dev/null 2>&1 || true

    local frames=("⠋" "⠙" "⠹" "⠸" "⠼" "⠴" "⠦" "⠧" "⠇" "⠏")
    local frame=1
    local started=$SECONDS

    while ! swift --version >/dev/null 2>&1; do
        (( SECONDS - started < 1200 )) || fail "Developer Tools installation timed out."
        print -n -- "\r${LIGHT_PURPLE}      ${frames[$frame]} Waiting for Developer Tools...${RESET}   "
        frame=$((frame % ${#frames[@]} + 1))
        sleep 2
    done

    print -- "\r${LIME}      ✓ Developer Tools are ready${RESET}             "
    print ""
}

download_source() {
    print -r -- "Downloading source code|$ARCHIVE_PATH" >"$STATUS_FILE"
    print -- "Downloading MaterialAuth source from GitHub codeload..."
    if curl --fail --location --silent --show-error \
        --user-agent "MaterialAuth-Installer/2.0" \
        --connect-timeout 8 --max-time 45 \
        --retry 1 --retry-delay 1 \
        "$REPOSITORY_ARCHIVE" --output "$ARCHIVE_PATH"; then
        return 0
    fi

    print -- "The direct source endpoint failed. Trying the GitHub archive URL..."
    print -r -- "Trying source mirror|$ARCHIVE_PATH" >"$STATUS_FILE"
    curl --fail --location --silent --show-error \
        --user-agent "MaterialAuth-Installer/2.0" \
        --connect-timeout 10 --max-time 60 \
        --retry 1 --retry-delay 1 \
        "$REPOSITORY_ARCHIVE_FALLBACK" --output "$ARCHIVE_PATH"
}

build_application() {
    cd "$PROJECT_DIR" || return 1
    swift build -c release || return 1

    local bin_dir contents macos resources
    bin_dir="$(swift build -c release --show-bin-path)" || return 1
    contents="$SOURCE_APP/Contents"
    macos="$contents/MacOS"
    resources="$contents/Resources"

    mkdir -p "$macos" "$resources" || return 1
    ditto "$bin_dir/MaterialAuth" "$macos/MaterialAuth" || return 1
    ditto "$PROJECT_DIR/Info.plist" "$contents/Info.plist" || return 1
    ditto "$PROJECT_DIR/Resources/MaterialAuth.icns" "$resources/MaterialAuth.icns" || return 1
    chmod +x "$macos/MaterialAuth" || return 1

    xattr -cr "$SOURCE_APP" || return 1
    codesign --force --deep --sign - "$SOURCE_APP" || return 1
}

close_terminal_window() {
    if [[ "${TERM_PROGRAM:-}" == "Apple_Terminal" ]]; then
        nohup /usr/bin/osascript \
            -e 'delay 0.5' \
            -e 'tell application "Terminal" to close front window' \
            >/dev/null 2>&1 &
    fi
}

header

for dependency in curl tar ditto codesign open; do
    command -v "$dependency" >/dev/null 2>&1 || fail "Required command not found: $dependency"
done
ensure_swift

step "1/4" "Download MaterialAuth" "Fetching the latest source code from GitHub"
if ! run_with_spinner "Downloading source code..." 2 download_source; then
    fail "Could not download MaterialAuth. Check your internet connection or VPN."
fi

tar -xzf "$ARCHIVE_PATH" -C "$WORK_DIR" >"$LOG_FILE" 2>&1 \
    || fail "The downloaded source archive could not be unpacked."
[[ -f "$PROJECT_DIR/Package.swift" ]] || fail "The downloaded project is incomplete or has an unexpected structure."
print ""

step "2/4" "Build application" "Creating an optimized MaterialAuth build for this Mac"
run_with_spinner "Compiling Swift and packaging the app..." 5 build_application \
    || fail "Could not build MaterialAuth."
[[ -d "$SOURCE_APP" ]] || fail "The application bundle was not created."
print ""

step "3/4" "Install application" "Copying MaterialAuth to your Applications folder"
animate_progress 0 12
mkdir -p "$USER_APPS_DIR" || fail "Could not create $USER_APPS_DIR."

if [[ -e "$TARGET_APP" ]]; then
    [[ "$TARGET_APP" == "$HOME/Applications/MaterialAuth.app" ]] || fail "Unsafe installation path."
    rm -rf -- "$TARGET_APP" || fail "Could not replace the previous installation."
fi

ditto "$SOURCE_APP" "$TARGET_APP" || fail "Could not copy the application."
animate_progress 13 20
print -- "${LIME}      ✓ Installed in ~/Applications${RESET}"
print ""

step "4/4" "Launch" "Starting MaterialAuth"
sleep 1
open "$TARGET_APP" || fail "The application was installed but could not be opened."
print -- "${LIME}      ✓ MaterialAuth is ready${RESET}"
print ""
banner_border "╭" "╮"
banner_line "Installation completed successfully" "${LIME}${BOLD}"
banner_border "╰" "╯"
print ""
print -- "${DIM}  Temporary installation files will now be removed.${RESET}"
sleep 1

cleanup
trap - EXIT
close_terminal_window
exit 0
