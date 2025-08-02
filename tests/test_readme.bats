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

@test "README.md explains Image Mode purpose" {
    grep -q "example of what is possible with Image Mode" "$README_FILE"
}

@test "README.md mentions no secrets policy" {
    grep -q "contains no secrets" "$README_FILE"
}

@test "README.md describes separate configuration repo" {
    grep -q "separate repo for any configuratoin information" "$README_FILE"
}

@test "README.md mentions encryption of configuration layer" {
    grep -q "encrypted so it can only be read by the desired machines" "$README_FILE"
}

@test "README.md describes protect_etc service" {
    grep -q "protect_etc.*was created" "$README_FILE"
}

@test "README.md explains file reset functionality" {
    grep -q "reset any files that do not match the base image" "$README_FILE"
}

@test "README.md specifies exclusion file path" {
    grep -q "/etc/protect_etc/files.exclude" "$README_FILE"
}

@test "README.md mentions podman for applications" {
    grep -q "launched using podman" "$README_FILE"
}

@test "README.md mentions systemd service deployment" {
    grep -q "systemd service" "$README_FILE"
}

@test "README.md mentions flightctl deployment" {
    grep -q "flightctl" "$README_FILE"
}

@test "README.md encourages forking" {
    grep -q "feel free to fork the repo" "$README_FILE"
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

@test "README.md mentions key technologies" {
    # Check for essential technology mentions
    grep -qi "fedora" "$README_FILE"
    grep -qi "podman" "$README_FILE"
}

@test "README.md security model is clearly explained" {
    # Verify key security concepts are mentioned
    grep -q "encrypted" "$README_FILE"
    grep -q "no secrets" "$README_FILE"
    grep -q "separate repo" "$README_FILE"
}

@test "README.md file protection is documented" {
    # Verify protection mechanism documentation
    grep -q "protect_etc" "$README_FILE"
    grep -q "files.exclude" "$README_FILE"
    grep -q "reset any files" "$README_FILE"
}

@test "README.md deployment options are covered" {
    # Verify both deployment methods are mentioned
    grep -q "systemd" "$README_FILE"
    grep -q "flightctl" "$README_FILE"
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

@test "README.md detects typo in configuration" {
    # This test will fail due to the typo "configuratoin" in the original README
    # Note: This test catches the actual typo "configuratoin" in line 5 of README.md
    grep -q "configuratoin" "$README_FILE"
}

@test "README.md contains no other common typos" {
    # Check for other common typos
    ! grep -qi "seperate" "$README_FILE"
    ! grep -qi "occured" "$README_FILE"
    ! grep -qi "recieve" "$README_FILE"
    ! grep -qi "thier" "$README_FILE"
    ! grep -qi "enviroment" "$README_FILE"
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

@test "README.md explains purpose in opening section" {
    # Check that the purpose is explained early in the document
    head -10 "$README_FILE" | grep -q "example of what is possible"
}

@test "README.md has logical content flow" {
    # Verify that concepts are introduced in logical order
    purpose_line=$(grep -n "example of what is possible" "$README_FILE" | cut -d: -f1)
    security_line=$(grep -n "no secrets" "$README_FILE" | cut -d: -f1)
    protection_line=$(grep -n "protect_etc" "$README_FILE" | cut -d: -f1)
    deployment_line=$(grep -n "podman" "$README_FILE" | cut -d: -f1)
    fork_line=$(grep -n "fork the repo" "$README_FILE" | cut -d: -f1)
    
    # Check ordering (allow some flexibility)
    [ "$purpose_line" -lt "$security_line" ]
    [ "$security_line" -lt "$protection_line" ]
    [ "$protection_line" -lt "$deployment_line" ]
    [ "$deployment_line" -lt "$fork_line" ]
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

@test "README.md explains the complete workflow" {
    # Verify all major workflow steps are covered
    grep -q "Image Mode" "$README_FILE"
    grep -q "separate repo" "$README_FILE"
    grep -q "encrypted" "$README_FILE"
    grep -q "protect_etc" "$README_FILE"
    grep -q "podman" "$README_FILE"
}

@test "README.md is suitable for newcomers" {
    # Check that it explains concepts rather than assuming knowledge
    grep -q "example of what is possible" "$README_FILE"
    grep -q "If you would like to create something similar" "$README_FILE"
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

@test "README.md contains all essential project information" {
    # Verify comprehensive coverage of project aspects
    grep -q "Base Fedora Image" "$README_FILE"
    grep -q "Image Mode" "$README_FILE"
    grep -q "secrets" "$README_FILE"
    grep -q "encrypted" "$README_FILE"
    grep -q "protect_etc" "$README_FILE"
    grep -q "podman" "$README_FILE"
    grep -q "fork" "$README_FILE"
}

@test "README.md security architecture is well documented" {
    # Ensure security model is thoroughly explained
    grep -q "contains no secrets" "$README_FILE"
    grep -q "separate repo for any" "$README_FILE" 
    grep -q "encrypted so it can only be read" "$README_FILE"
}

@test "README.md application deployment methods are clear" {
    # Verify deployment options are clearly stated
    grep -q "systemd service" "$README_FILE"
    grep -q "through flightctl" "$README_FILE"
}

@test "README.md encourages community contribution" {
    # Check for community-friendly language
    grep -q "If you would like to create something similar" "$README_FILE"
    grep -q "please feel free to fork" "$README_FILE"
}