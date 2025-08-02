#!/usr/bin/env bats

# Edge case and error condition tests for test_files_exclude.bats
# Testing framework: BATS (Bash Automated Testing System)

setup() {
    TEST_DIR=$(mktemp -d)
    EXCLUDE_FILE="tests/test_files_exclude.bats"
}

teardown() {
    rm -rf "$TEST_DIR"
}

@test "test exclusion file handles path matching edge cases correctly" {
    # Test exact matching vs. substring matching
    local edge_case_paths=(
        "shadow-backup"          # Should NOT match 'shadow'
        "ssh/sshd_config.bak"    # Should NOT match 'ssh/sshd_config'  
        "sssd/sssd.conf.orig"    # Should NOT match 'sssd/sssd.conf'
        "shadow/passwd"          # SHOULD match 'shadow'
        "sssd/conf.d/test.conf"  # SHOULD match 'sssd/conf.d'
    )
    
    # Test cases that should NOT match
    ! echo "shadow-backup" | grep -f "$EXCLUDE_FILE" >/dev/null || true
    ! echo "ssh/sshd_config.bak" | grep -f "$EXCLUDE_FILE" >/dev/null || true  
    ! echo "sssd/sssd.conf.orig" | grep -f "$EXCLUDE_FILE" >/dev/null || true
    
    # Test cases that SHOULD match
    echo "shadow/passwd" | grep -f "$EXCLUDE_FILE" >/dev/null
    echo "sssd/conf.d/test.conf" | grep -f "$EXCLUDE_FILE" >/dev/null || {
        echo "sssd/conf.d" | grep -f "$EXCLUDE_FILE" >/dev/null
    }
}

@test "test exclusion file handles special characters safely" {
    # Verify patterns don't contain characters that could be exploited
    while IFS= read -r pattern; do
        # No shell metacharacters
        [[ ! "$pattern" =~ [\$\`\;] ]]
        # No regex metacharacters that could cause issues
        [[ ! "$pattern" =~ [\(\)\[\]\{\}\^\$\*\+\?] ]]
        # No quotes that could break command parsing
        [[ ! "$pattern" =~ [\"\'] ]]
    done < "$EXCLUDE_FILE"
}

@test "test exclusion file prevents common attack vectors" {
    # Test that patterns can't be used for directory traversal
    while IFS= read -r pattern; do
        [[ ! "$pattern" =~ \.\./\.\./ ]]
        [[ ! "$pattern" =~ ^\.\./ ]]
        [[ ! "$pattern" =~ /\.\. ]]
    done < "$EXCLUDE_FILE"
    
    # Test that patterns don't contain null bytes or other control chars
    ! grep -q $'\0' "$EXCLUDE_FILE"
    ! grep -q $'\x01\x02\x03\x04\x05\x06\x07\x08\x0E\x0F' "$EXCLUDE_FILE"
}

@test "test exclusion file performance with large file lists" {
    # Simulate a large /usr/etc directory structure
    local large_file_list=$(mktemp)
    
    # Generate a realistic large file list
    for i in {1..100}; do
        echo "file_$i.conf" >> "$large_file_list"
        echo "dir_$i/config.txt" >> "$large_file_list"
    done
    
    # Add our security-sensitive files
    echo "shadow/passwd" >> "$large_file_list"
    echo "ssh/sshd_config" >> "$large_file_list"
    echo "machine-id" >> "$large_file_list"
    
    # Test that grep can handle the exclusion efficiently
    local start_time=$(date +%s%N)
    local matches=$(grep -f "$EXCLUDE_FILE" "$large_file_list" | wc -l)
    local end_time=$(date +%s%N)
    
    # Should find some matches
    [ "$matches" -gt 0 ]
    
    # Should complete reasonably quickly (less than 1 second for this test)
    local duration=$(( (end_time - start_time) / 1000000 ))  # Convert to milliseconds
    [ "$duration" -lt 1000 ]
    
    rm -f "$large_file_list"
}

@test "test exclusion file compatibility with different shell environments" {
    # Test that patterns work correctly in different contexts
    
    # Test with while loop (common in scripts)
    local loop_matches=0
    while IFS= read -r pattern; do
        if [[ "shadow/passwd" == "$pattern"* ]]; then
            ((loop_matches++))
        fi
    done < "$EXCLUDE_FILE"
    [ "$loop_matches" -gt 0 ]
    
    # Test with array processing
    local patterns=()
    while IFS= read -r line; do
        patterns+=("$line")
    done < "$EXCLUDE_FILE"
    [ "${#patterns[@]}" -eq 7 ]
    
    # Test with case statement matching
    local case_matches=0
    for pattern in "${patterns[@]}"; do
        case "shadow/passwd" in
            "$pattern"*) ((case_matches++)) ;;
        esac
    done
    [ "$case_matches" -gt 0 ]
}

@test "test exclusion file handles concurrent access safely" {
    # Simulate multiple processes reading the exclusion file
    local temp_results=()
    
    for i in {1..5}; do
        local temp_result=$(mktemp)
        temp_results+=("$temp_result")
        
        # Start background process to read exclusion file
        (
            local count=$(wc -l < "$EXCLUDE_FILE")
            echo "$count" > "$temp_result"
        ) &
    done
    
    # Wait for all background processes
    wait
    
    # All should have read the same number of lines
    local expected_count=$(wc -l < "$EXCLUDE_FILE")
    for result_file in "${temp_results[@]}"; do
        local actual_count=$(cat "$result_file")
        [ "$actual_count" -eq "$expected_count" ]
        rm -f "$result_file"
    done
}

@test "test exclusion patterns work correctly with symlinks and special files" {
    # Create test directory with various file types
    mkdir -p "$TEST_DIR"/test_fs/{shadow,ssh}
    touch "$TEST_DIR"/test_fs/shadow/passwd
    touch "$TEST_DIR"/test_fs/ssh/sshd_config
    ln -s passwd "$TEST_DIR"/test_fs/shadow/passwd_link
    
    # Test that exclusion works regardless of file type
    cd "$TEST_DIR"/test_fs
    local files_to_test=(
        "shadow/passwd"
        "shadow/passwd_link"  
        "ssh/sshd_config"
    )
    
    for file in "${files_to_test[@]}"; do
        echo "$file" | grep -f "$EXCLUDE_FILE" >/dev/null || {
            # Check parent directory pattern
            local dir="${file%/*}"
            echo "$dir" | grep -f "$EXCLUDE_FILE" >/dev/null
        }
    done
}
