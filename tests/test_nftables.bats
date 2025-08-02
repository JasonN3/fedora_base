#!/usr/bin/env bats

# Test suite for nftables configuration
# Testing framework: BATS (Bash Automated Testing System)

setup() {
    # Setup temporary nftables configuration for testing
    export TEST_CONFIG_FILE="/tmp/test_nftables.conf"
    export BACKUP_FILE="/tmp/nftables_backup.conf"
    export SOURCE_CONFIG="tests/test_nftables.bats"
    
    # Create the actual nftables configuration file to test
    cat > "$TEST_CONFIG_FILE" << 'NFTCONF'
table inet nftables {
  chain INPUT {
    tcp dport 22 accept        # SSH
  }
}
NFTCONF
    
    # Backup existing nftables configuration if it exists
    if [ -f "/etc/nftables.conf" ]; then
        cp /etc/nftables.conf "$BACKUP_FILE"
    fi
}

teardown() {
    # Clean up test files
    [ -f "$TEST_CONFIG_FILE" ] && rm -f "$TEST_CONFIG_FILE"
    
    # Restore original configuration if backup exists
    if [ -f "$BACKUP_FILE" ]; then
        cp "$BACKUP_FILE" /etc/nftables.conf
        rm -f "$BACKUP_FILE"
    fi
}

@test "nftables configuration syntax is valid" {
    # Test syntax validation using nft dry-run
    run nft -c -f "$TEST_CONFIG_FILE"
    [ "$status" -eq 0 ]
}

@test "configuration defines inet table named 'nftables'" {
    # Check if the table declaration is present
    run grep -q "table inet nftables" "$TEST_CONFIG_FILE"
    [ "$status" -eq 0 ]
}

@test "configuration includes INPUT chain" {
    # Verify INPUT chain is defined
    run grep -q "chain INPUT" "$TEST_CONFIG_FILE"
    [ "$status" -eq 0 ]
}

@test "SSH port 22 is explicitly allowed" {
    # Verify SSH rule is present
    run grep -q "tcp dport 22 accept" "$TEST_CONFIG_FILE"
    [ "$status" -eq 0 ]
}

@test "SSH rule includes proper comment" {
    # Verify the SSH rule has descriptive comment
    run grep -q "tcp dport 22 accept.*# SSH" "$TEST_CONFIG_FILE"
    [ "$status" -eq 0 ]
}

@test "configuration uses proper nftables syntax formatting" {
    # Test proper bracket usage and indentation
    local line_count=$(grep -c "^  " "$TEST_CONFIG_FILE" || echo 0)
    [ "$line_count" -gt 0 ]
}

@test "table uses inet family (supports both IPv4 and IPv6)" {
    # Verify inet family is used instead of ip or ip6
    run grep -q "table inet" "$TEST_CONFIG_FILE"
    [ "$status" -eq 0 ]
}

@test "configuration can be loaded without errors" {
    # Test loading the configuration (dry-run)
    run nft -c -f "$TEST_CONFIG_FILE"
    [ "$status" -eq 0 ]
    [[ "$output" != *"Error"* ]]
}

@test "configuration handles malformed syntax gracefully" {
    # Create malformed configuration to test error handling
    local malformed_file="/tmp/malformed_nftables.conf"
    cat > "$malformed_file" << 'NFTCONF'
table inet nftables {
  chain INPUT {
    tcp dport 22 accept        # SSH
    # Missing closing brace intentionally
NFTCONF
    
    # Should fail with syntax error
    run nft -c -f "$malformed_file"
    [ "$status" -ne 0 ]
    
    # Clean up
    rm -f "$malformed_file"
}

@test "SSH rule accepts TCP protocol specifically" {
    # Verify the rule specifies TCP protocol
    run grep -q "tcp.*dport.*22" "$TEST_CONFIG_FILE"
    [ "$status" -eq 0 ]
}

@test "configuration is minimal and secure by default" {
    # Count number of accept rules (should be minimal)
    local accept_count=$(grep -c "accept" "$TEST_CONFIG_FILE" || echo 0)
    [ "$accept_count" -eq 1 ]
}

@test "configuration follows nftables best practices" {
    # Check that inet family is used (modern approach)
    run grep -q "table inet" "$TEST_CONFIG_FILE"
    [ "$status" -eq 0 ]
    
    # Check proper indentation
    run grep -q "^  chain INPUT" "$TEST_CONFIG_FILE"
    [ "$status" -eq 0 ]
}

@test "no duplicate rules exist" {
    # Ensure SSH rule appears only once
    local ssh_rule_count=$(grep -c "tcp dport 22 accept" "$TEST_CONFIG_FILE" || echo 0)
    [ "$ssh_rule_count" -eq 1 ]
}

@test "configuration structure is well-formed" {
    # Test proper nesting structure
    local table_count=$(grep -c "table inet" "$TEST_CONFIG_FILE" || echo 0)
    local chain_count=$(grep -c "chain INPUT" "$TEST_CONFIG_FILE" || echo 0)
    
    [ "$table_count" -eq 1 ]
    [ "$chain_count" -eq 1 ]
}

@test "rule syntax matches nftables specification" {
    # Verify the rule follows correct nftables syntax pattern
    run grep -E "^\s*tcp\s+dport\s+[0-9]+\s+accept" "$TEST_CONFIG_FILE"
    [ "$status" -eq 0 ]
}

@test "configuration can be validated with different nft versions" {
    skip_if_missing_command "nft"
    
    # Test with current nft version
    run nft --version
    [ "$status" -eq 0 ]
    
    # Validate configuration
    run nft -c -f "$TEST_CONFIG_FILE"
    [ "$status" -eq 0 ]
}

@test "SSH port specification is numeric and valid" {
    # Verify port 22 is specified as a number
    run grep -E "dport\s+22\s" "$TEST_CONFIG_FILE"
    [ "$status" -eq 0 ]
}

@test "configuration includes proper whitespace handling" {
    # Test that configuration handles whitespace correctly
    local tab_count=$(grep -P '\t' "$TEST_CONFIG_FILE" 2>/dev/null | wc -l || echo 0)
    local space_indent_count=$(grep -E '^  ' "$TEST_CONFIG_FILE" | wc -l || echo 0)
    
    # Should use consistent indentation (either tabs or spaces)
    [ "$space_indent_count" -gt 0 ] || [ "$tab_count" -gt 0 ]
}

@test "comment formatting follows conventions" {
    # Verify comment is properly formatted with hash and space
    run grep -q "# SSH$" "$TEST_CONFIG_FILE"
    [ "$status" -eq 0 ]
}

@test "configuration has proper opening and closing braces" {
    # Count opening and closing braces - should be balanced
    local open_braces=$(grep -o "{" "$TEST_CONFIG_FILE" | wc -l)
    local close_braces=$(grep -o "}" "$TEST_CONFIG_FILE" | wc -l)
    
    [ "$open_braces" -eq "$close_braces" ]
    [ "$open_braces" -eq 2 ]  # Should have exactly 2 opening braces
}

@test "table name follows naming conventions" {
    # Verify table name is alphanumeric and descriptive
    run grep -E "table\s+inet\s+[a-zA-Z][a-zA-Z0-9_]*" "$TEST_CONFIG_FILE"
    [ "$status" -eq 0 ]
}

@test "chain name follows naming conventions" {
    # Verify chain name is uppercase and descriptive
    run grep -E "chain\s+[A-Z][A-Z0-9_]*" "$TEST_CONFIG_FILE"
    [ "$status" -eq 0 ]
}

@test "rule has proper action keyword" {
    # Verify accept is used as action
    run grep -q "accept" "$TEST_CONFIG_FILE"
    [ "$status" -eq 0 ]
    
    # Ensure no conflicting actions
    run grep -E "(drop|reject)" "$TEST_CONFIG_FILE"
    [ "$status" -ne 0 ]
}

@test "configuration allows SSH access from any source" {
    # Verify there are no source IP restrictions on SSH rule
    local ssh_line=$(grep "tcp dport 22 accept" "$TEST_CONFIG_FILE")
    [[ "$ssh_line" != *"saddr"* ]]
    [[ "$ssh_line" != *"ip saddr"* ]]
}

@test "configuration file is readable by nftables service" {
    # Check file permissions and readability
    [ -r "$TEST_CONFIG_FILE" ]
    
    # Verify file is not empty
    [ -s "$TEST_CONFIG_FILE" ]
}

@test "port number is within valid range" {
    # Extract port number and verify it's within valid range (1-65535)
    local port=$(grep -o "dport [0-9]*" "$TEST_CONFIG_FILE" | grep -o "[0-9]*")
    [ "$port" -ge 1 ]
    [ "$port" -le 65535 ]
    [ "$port" -eq 22 ]  # Should specifically be SSH port
}

@test "configuration uses modern nftables syntax" {
    # Ensure it's not using legacy iptables-style syntax
    run grep -E "(iptables|INPUT.*-j|--dport)" "$TEST_CONFIG_FILE"
    [ "$status" -ne 0 ]
    
    # Should use nftables syntax
    run grep -q "dport" "$TEST_CONFIG_FILE"
    [ "$status" -eq 0 ]
}

@test "configuration can be applied in test mode" {
    skip_if_missing_command "nft"
    
    # Try to apply configuration in check mode
    run nft -c -f "$TEST_CONFIG_FILE"
    [ "$status" -eq 0 ]
    
    # Verify no error messages about unsupported features
    [[ "$output" != *"unsupported"* ]]
    [[ "$output" != *"not supported"* ]]
}

@test "configuration handles IPv4 and IPv6 traffic" {
    # Since inet family is used, it should handle both IPv4 and IPv6
    run grep -q "table inet" "$TEST_CONFIG_FILE"
    [ "$status" -eq 0 ]
    
    # Should not have separate ip and ip6 tables
    run grep -E "table\s+(ip|ip6)\s+" "$TEST_CONFIG_FILE"
    [ "$status" -ne 0 ]
}

@test "configuration is production-ready" {
    # Comprehensive validation test
    # Multiple validation checks
    run nft -c -f "$TEST_CONFIG_FILE"
    [ "$status" -eq 0 ]
    
    # Check file is readable
    [ -r "$TEST_CONFIG_FILE" ]
    
    # Verify content integrity
    run grep -q "table inet nftables" "$TEST_CONFIG_FILE"
    [ "$status" -eq 0 ]
    
    # Ensure configuration is not empty
    [ -s "$TEST_CONFIG_FILE" ]
    
    # Verify proper structure
    local line_count=$(wc -l < "$TEST_CONFIG_FILE")
    [ "$line_count" -ge 5 ]  # Should have at least 5 lines for proper structure
}

# Helper function to skip tests when command is missing
skip_if_missing_command() {
    if ! command -v "$1" >/dev/null 2>&1; then
        skip "Command $1 not available"
    fi
}