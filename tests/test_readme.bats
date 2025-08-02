#!/usr/bin/env bats

# BATS tests for README.md validation
# Testing framework: BATS (Bash Automated Testing System)

setup() {
    # Set up test environment
    README_FILE="README.md"
    TEMP_DIR=$(mktemp -d)
}

teardown() {
    # Clean up test environment
    rm -rf "$TEMP_DIR" 2>/dev/null || true
}

@test "README.md file exists and is readable" {
    [ -f "$README_FILE" ]
    [ -r "$README_FILE" ]
}

@test "README.md is not empty" {
    [ -s "$README_FILE" ]
}

@test "README.md contains required main title" {
    grep -q "^# Base Fedora Image$" "$README_FILE"
}

@test "README.md contains Codacy badge" {
    grep -q "Codacy Badge" "$README_FILE"
}

@test "README.md badge has correct repository reference" {
    grep -q "JasonN3/fedora_base" "$README_FILE"
}

@test "README.md badge uses proper markdown syntax" {
    grep -q "^\[![Codacy Badge\].*\](.*)$" "$README_FILE"
}

@test "README.md has consistent line endings" {
    # Check for Unix line endings (no carriage returns)
    ! grep -q $'\r' "$README_FILE"
}

@test "README.md contains no obviously broken markdown" {
    # Check for unmatched brackets that could indicate broken links
    bracket_count=$(grep -o '\[' "$README_FILE" | wc -l)
    closing_bracket_count=$(grep -o '\]' "$README_FILE" | wc -l)
    [ "$bracket_count" -eq "$closing_bracket_count" ]
}

@test "README.md has proper heading hierarchy" {
    # Main title should be h1
    grep -q "^# " "$README_FILE"
    # No broken heading syntax
    ! grep -q "^#{7,}" "$README_FILE"
}

@test "README.md has reasonable line lengths" {
    # Check that lines don't exceed 200 characters (allowing for URLs)
    max_length=0
    while IFS= read -r line; do
        length=${#line}
        if [ "$length" -gt "$max_length" ]; then
            max_length="$length"
        fi
        # Allow longer lines if they contain URLs
        if [[ ! "$line" =~ https?:// ]] && [ "$length" -gt 200 ]; then
            echo "Line too long ($length chars): ${line:0:50}..."
            return 1
        fi
    done < "$README_FILE"
}

@test "README.md badge URL structure is valid" {
    # Extract and validate badge URL structure
    badge_url=$(grep -o 'https://app\.codacy\.com[^)]*' "$README_FILE" | head -1)
    [ -n "$badge_url" ]
    [[ "$badge_url" =~ ^https://app\.codacy\.com/project/badge/Grade/[a-f0-9]+$ ]]
}

@test "README.md dashboard URL structure is valid" {
    # Extract and validate dashboard URL structure
    dashboard_url=$(grep -o 'https://app\.codacy\.com/gh/[^)]*' "$README_FILE" | head -1)
    [ -n "$dashboard_url" ]
    [[ "$dashboard_url" =~ ^https://app\.codacy\.com/gh/JasonN3/fedora_base/dashboard ]]
}


@test "README.md uses consistent terminology" {
    # Check for consistent use of technical terms
    # "Image Mode" should be capitalized consistently
    ! grep -q "image mode" "$README_FILE"  # Should be "Image Mode"
    # Check that protect_etc is consistently formatted
    protect_etc_mentions=$(grep -c "protect_etc" "$README_FILE")
    [ "$protect_etc_mentions" -ge 1 ]
}

@test "README.md provides actionable information" {
    # Verify that the README provides concrete paths and commands
    grep -q "/etc/protect_etc/files.exclude" "$README_FILE"
    grep -q "systemd service" "$README_FILE"
    grep -q "flightctl" "$README_FILE"
}

@test "README.md file permissions are appropriate" {
    # README should be readable by all
    [ -r "$README_FILE" ]
    # Check that it's not executable (common mistake)
    [ ! -x "$README_FILE" ]
}

@test "README.md contains proper markdown backticks for code" {
    # Check that protect_etc is properly formatted as code
    grep -q '`protect_etc`' "$README_FILE"
    grep -q '`/etc/protect_etc/files.exclude`' "$README_FILE"
}

@test "README.md has appropriate paragraph structure" {
    # Check that there are blank lines between paragraphs
    blank_lines=$(grep -c '^$' "$README_FILE")
    [ "$blank_lines" -ge 3 ]  # Should have at least a few paragraph breaks
}
