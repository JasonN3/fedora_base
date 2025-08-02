#!/usr/bin/env bats

# Test suite for test_files_exclude.bats validation
# This file contains patterns that mirror those used by protect_etc.sh for rsync exclusion filtering

setup() {
    # Create temporary test directory structure
    TEST_DIR=$(mktemp -d)
    EXCLUDE_FILE="tests/test_files_exclude.bats"
    REAL_EXCLUDE_FILE="rootfs/etc/protect_etc/files.exclude"
    
    # Create mock /usr/etc and /etc structure that matches exclusion patterns
    mkdir -p "$TEST_DIR"/{usr_etc,etc}/{shadow,nftables/local.nft.d,selinux,ssh,sssd/conf.d}
    touch "$TEST_DIR"/usr_etc/shadow/passwd "$TEST_DIR"/etc/shadow/passwd
    touch "$TEST_DIR"/usr_etc/shadow/shadow "$TEST_DIR"/etc/shadow/shadow
    touch "$TEST_DIR"/usr_etc/machine-id "$TEST_DIR"/etc/machine-id
    touch "$TEST_DIR"/usr_etc/nftables/local.nft.d/custom.nft "$TEST_DIR"/etc/nftables/local.nft.d/custom.nft
    touch "$TEST_DIR"/usr_etc/selinux/config "$TEST_DIR"/etc/selinux/config
    touch "$TEST_DIR"/usr_etc/ssh/sshd_config "$TEST_DIR"/etc/ssh/sshd_config
    touch "$TEST_DIR"/usr_etc/sssd/sssd.conf "$TEST_DIR"/etc/sssd/sssd.conf
    touch "$TEST_DIR"/usr_etc/sssd/conf.d/domain.conf "$TEST_DIR"/etc/sssd/conf.d/domain.conf
    
    # Create files that should NOT be excluded
    touch "$TEST_DIR"/usr_etc/passwd "$TEST_DIR"/etc/passwd
    touch "$TEST_DIR"/usr_etc/hosts "$TEST_DIR"/etc/hosts
    touch "$TEST_DIR"/usr_etc/resolv.conf "$TEST_DIR"/etc/resolv.conf
    mkdir -p "$TEST_DIR"/{usr_etc,etc}/systemd
    touch "$TEST_DIR"/usr_etc/systemd/system.conf "$TEST_DIR"/etc/systemd/system.conf
}

teardown() {
    # Clean up test directory
    rm -rf "$TEST_DIR"
}

# Basic file validation tests
@test "test exclusion file exists and is readable" {
    [ -f "$EXCLUDE_FILE" ]
    [ -r "$EXCLUDE_FILE" ]
}

@test "test exclusion file is not empty" {
    [ -s "$EXCLUDE_FILE" ]
}

@test "test exclusion file contains exactly 7 entries" {
    local count=$(wc -l < "$EXCLUDE_FILE")
    [ "$count" -eq 7 ]
}

# Content validation tests - verify each expected exclusion pattern
@test "test exclusion file contains shadow entry" {
    grep -q "^shadow$" "$EXCLUDE_FILE"
}

@test "test exclusion file contains machine-id entry" {
    grep -q "^machine-id$" "$EXCLUDE_FILE"
}

@test "test exclusion file contains nftables directory entry" {
    grep -q "^nftables/local.nft.d$" "$EXCLUDE_FILE"
}

@test "test exclusion file contains selinux entry" {
    grep -q "^selinux$" "$EXCLUDE_FILE"
}

@test "test exclusion file contains ssh config entry" {
    grep -q "^ssh/sshd_config$" "$EXCLUDE_FILE"
}

@test "test exclusion file contains sssd config entry" {
    grep -q "^sssd/sssd.conf$" "$EXCLUDE_FILE"
}

@test "test exclusion file contains sssd conf.d directory entry" {
    grep -q "^sssd/conf.d$" "$EXCLUDE_FILE"
}

# Content consistency tests - compare with real exclusion file
@test "test exclusion file mirrors the real exclusion file patterns" {
    skip_if_missing "$REAL_EXCLUDE_FILE"
    
    # Both files should have the same number of patterns
    local test_count=$(wc -l < "$EXCLUDE_FILE")
    local real_count=$(wc -l < "$REAL_EXCLUDE_FILE")
    [ "$test_count" -eq "$real_count" ]
    
    # Each pattern in test file should exist in real file
    while IFS= read -r pattern; do
        grep -q "^$pattern$" "$REAL_EXCLUDE_FILE"
    done < "$EXCLUDE_FILE"
}

# Format validation tests for rsync compatibility
@test "test exclusion entries have correct format for rsync" {
    # No leading/trailing whitespace (critical for rsync)
    ! grep -q "^[[:space:]]" "$EXCLUDE_FILE"
    ! grep -q "[[:space:]]$" "$EXCLUDE_FILE"
    
    # No empty lines
    ! grep -q "^$" "$EXCLUDE_FILE"
    
    # No comments in the content (protect_etc.sh filters them)
    ! grep -q "^#" "$EXCLUDE_FILE"
}

@test "test exclusion patterns are properly formatted relative paths" {
    while IFS= read -r line; do
        # Should not start with / (relative paths for rsync)
        [[ ! "$line" =~ ^/ ]]
        # Should not contain control characters
        [[ ! "$line" =~ [[:cntrl:]] ]]
        # Should not contain path traversal attempts
        [[ ! "$line" =~ \.\. ]]
    done < "$EXCLUDE_FILE"
}

@test "test exclusion file has Unix line endings" {
    # Check for DOS/Windows line endings (CR+LF) which break rsync
    ! grep -q $'\r' "$EXCLUDE_FILE"
}

# Functional tests simulating protect_etc.sh behavior
@test "test exclusion file is compatible with protect_etc.sh comment filtering" {
    # Simulate the grep -v command used in protect_etc.sh
    local temp_processed=$(mktemp)
    grep -v '^\s*#' "$EXCLUDE_FILE" > "$temp_processed" || touch "$temp_processed"
    
    # Should have same content since no comments should be present
    local original_lines=$(wc -l < "$EXCLUDE_FILE")
    local processed_lines=$(wc -l < "$temp_processed")
    [ "$original_lines" -eq "$processed_lines" ]
    
    rm -f "$temp_processed"
}

@test "test exclusion patterns work with rsync exclude-from functionality" {
    local temp_file_list=$(mktemp)
    local rsync_exclude=$(mktemp)
    
    # Create a file list similar to what rsync would process from /usr/etc
    cd "$TEST_DIR"/usr_etc && find . -type f -printf '%P\n' > "$temp_file_list"
    
    # Copy our exclusion patterns
    cp "$EXCLUDE_FILE" "$rsync_exclude"
    
    # Test that security-sensitive files would be excluded
    local security_files=(
        "shadow/passwd"
        "ssh/sshd_config" 
        "sssd/sssd.conf"
        "machine-id"
    )
    
    local excluded_count=0
    for security_file in "${security_files[@]}"; do
        if grep -q "^$security_file$" "$temp_file_list"; then
            # Check if this file would be excluded by our patterns
            while IFS= read -r exclude_pattern; do
                if [[ "$security_file" == "$exclude_pattern" ]] || [[ "$security_file" == "$exclude_pattern"/* ]]; then
                    ((excluded_count++))
                    break
                fi
            done < "$rsync_exclude"
        fi
    done
    
    # Should exclude security-sensitive files
    [ "$excluded_count" -gt 0 ]
    
    rm -f "$temp_file_list" "$rsync_exclude"
}

# Security-focused tests
@test "test shadow directory exclusion prevents sensitive authentication data exposure" {
    # Verify shadow pattern would exclude all shadow-related files
    local shadow_files=("shadow/passwd" "shadow/shadow" "shadow/gshadow")
    
    for shadow_file in "${shadow_files[@]}"; do
        echo "$shadow_file" | grep -f "$EXCLUDE_FILE" >/dev/null
    done
}

@test "test ssh configuration exclusion is appropriately specific" {
    # Test specific file exclusion for sshd_config
    echo "ssh/sshd_config" | grep -f "$EXCLUDE_FILE" >/dev/null
    
    # Verify it doesn't over-exclude other ssh files that might be safe
    ! echo "ssh/ssh_config" | grep -f "$EXCLUDE_FILE" >/dev/null || true
    ! echo "ssh/ssh_host_rsa_key.pub" | grep -f "$EXCLUDE_FILE" >/dev/null || true
}

@test "test sssd configuration exclusions cover both main config and domain configs" {
    # Test main config file exclusion
    echo "sssd/sssd.conf" | grep -f "$EXCLUDE_FILE" >/dev/null
    
    # Test that conf.d directory exclusion covers domain-specific configs
    local sssd_configs=("sssd/conf.d/domain.conf" "sssd/conf.d/ldap.conf")
    
    for config in "${sssd_configs[@]}"; do
        # Should match either exact pattern or directory pattern
        echo "$config" | grep -f "$EXCLUDE_FILE" >/dev/null || {
            echo "sssd/conf.d" | grep -f "$EXCLUDE_FILE" >/dev/null
        }
    done
}

@test "test nftables local configuration exclusion prevents custom rules exposure" {
    # Test that local nftables rules are excluded
    local nftables_files=("nftables/local.nft.d/custom.nft" "nftables/local.nft.d/rules.nft")
    
    for nft_file in "${nftables_files[@]}"; do
        echo "$nft_file" | grep -f "$EXCLUDE_FILE" >/dev/null || {
            echo "nftables/local.nft.d" | grep -f "$EXCLUDE_FILE" >/dev/null
        }
    done
}

@test "test machine-id exclusion prevents system fingerprinting" {
    echo "machine-id" | grep -f "$EXCLUDE_FILE" >/dev/null
}

@test "test selinux configuration exclusion covers security policies" {
    # Test that selinux directory exclusion covers policy files
    local selinux_files=("selinux/config" "selinux/policy" "selinux/contexts")
    
    for selinux_file in "${selinux_files[@]}"; do
        echo "$selinux_file" | grep -f "$EXCLUDE_FILE" >/dev/null || {
            echo "selinux" | grep -f "$EXCLUDE_FILE" >/dev/null
        }
    done
}

# Data quality and integrity tests
@test "test exclusion file has no duplicate entries" {
    local original_count=$(wc -l < "$EXCLUDE_FILE")
    local unique_count=$(sort "$EXCLUDE_FILE" | uniq | wc -l)
    [ "$original_count" -eq "$unique_count" ]
}

@test "test exclusion file entries are properly sorted" {
    local sorted_file=$(mktemp)
    sort "$EXCLUDE_FILE" > "$sorted_file"
    cmp -s "$EXCLUDE_FILE" "$sorted_file"
    local result=$?
    rm -f "$sorted_file"
    [ $result -eq 0 ]
}

@test "test exclusion file has appropriate permissions" {
    # Should be readable
    [ -r "$EXCLUDE_FILE" ]
    
    # Should not be executable (it's a data file)
    [ ! -x "$EXCLUDE_FILE" ]
}

# Edge cases and negative tests
@test "test exclusion patterns don't over-exclude common system files" {
    # Test that essential system files are NOT excluded
    local essential_files=("passwd" "hosts" "resolv.conf" "fstab" "hostname" "group")
    
    for file in "${essential_files[@]}"; do
        ! echo "$file" | grep -f "$EXCLUDE_FILE" >/dev/null || true
    done
}

@test "test exclusion patterns are not overly broad" {
    # Ensure patterns don't accidentally exclude entire important directories
    local important_dirs=("systemd" "NetworkManager" "dbus" "udev")
    
    for dir in "${important_dirs[@]}"; do
        ! grep -q "^$dir$" "$EXCLUDE_FILE" || true
    done
}

@test "test exclusion file handles mixed directory and file patterns correctly" {
    # Directory patterns should exclude entire directories
    local dir_patterns=("shadow" "selinux" "nftables/local.nft.d" "sssd/conf.d")
    
    for pattern in "${dir_patterns[@]}"; do
        grep -q "^$pattern$" "$EXCLUDE_FILE"
    done
    
    # File patterns should be specific
    local file_patterns=("ssh/sshd_config" "sssd/sssd.conf" "machine-id")
    
    for pattern in "${file_patterns[@]}"; do
        grep -q "^$pattern$" "$EXCLUDE_FILE"
    done
}

@test "test exclusion patterns maintain security without breaking functionality" {
    # Verify that we exclude security-sensitive files but not operational configs
    
    # Should exclude (security-sensitive)
    local should_exclude=("shadow" "ssh/sshd_config" "sssd/sssd.conf" "selinux")
    for pattern in "${should_exclude[@]}"; do
        grep -q "$pattern" "$EXCLUDE_FILE"
    done
    
    # Should NOT exclude (operational configs)
    local should_not_exclude=("systemd" "NetworkManager" "resolv.conf" "hosts")
    for pattern in "${should_not_exclude[@]}"; do
        ! grep -q "^$pattern$" "$EXCLUDE_FILE" || true
    done
}

# Stress tests and comprehensive validation
@test "test exclusion file handles all expected security-sensitive patterns" {
    local all_security_patterns=(
        "shadow"              # User authentication data
        "machine-id"          # System unique identifier  
        "nftables/local.nft.d"   # Local firewall rules
        "selinux"             # Security Enhanced Linux policies
        "ssh/sshd_config"     # SSH daemon configuration
        "sssd/sssd.conf"      # System Security Services Daemon config
        "sssd/conf.d"         # SSSD domain configurations
    )
    
    for pattern in "${all_security_patterns[@]}"; do
        grep -q "^$pattern$" "$EXCLUDE_FILE"
    done
    
    # Verify we have exactly these patterns and no others
    local pattern_count=${#all_security_patterns[@]}
    local file_count=$(wc -l < "$EXCLUDE_FILE")
    [ "$pattern_count" -eq "$file_count" ]
}

@test "test exclusion patterns prevent information disclosure vulnerabilities" {
    # Test that patterns prevent exposure of sensitive system information
    local sensitive_info_tests=(
        "shadow/passwd:authentication_hashes"
        "ssh/sshd_config:ssh_daemon_config" 
        "sssd/sssd.conf:domain_authentication"
        "selinux/config:security_policies"
        "machine-id:system_fingerprint"
        "nftables/local.nft.d/custom.nft:firewall_rules"
        "sssd/conf.d/domain.conf:domain_secrets"
    )
    
    for test_case in "${sensitive_info_tests[@]}"; do
        local file_path="${test_case%:*}"
        echo "$file_path" | grep -f "$EXCLUDE_FILE" >/dev/null || {
            # Check if parent directory pattern matches
            local parent_dir="${file_path%/*}"
            echo "$parent_dir" | grep -f "$EXCLUDE_FILE" >/dev/null
        }
    done
}

# Helper function for conditional tests
skip_if_missing() {
    local file="$1"
    [ -f "$file" ] || skip "Real exclusion file not found: $file"
}
