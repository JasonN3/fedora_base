#!/bin/bash
set -euo pipefail

## Syncs files from /usr/etc back to /etc so future updates can update the files
## 
## Configuration:
## /etc/protect_etc/files.exclude = Files to exclude from syncing
## /etc/protect_etc/files.include = Files to include from syncing
## Processes exclude and then include

# Filter out comments
if [ -f /etc/protect_etc/files.include ]
then
  grep -v '^\s*#' /etc/protect_etc/files.exclude > /tmp/files.exclude || touch /tmp/files.exclude
else
  touch /tmp/files.exclude
fi

if [ -f /etc/protect_etc/files.include ]
then
  grep -v '^\s*#' /etc/protect_etc/files.include > /tmp/files.include || touch /tmp/files.include
else
  touch /tmp/files.include
fi

# c = checksum
# r = recursive
# l = copy symlinks
# o = copy owner
# g = copy group
# D = preserve devices and special
# I = ignore times
# i = itemize result
rsync -crlogDIi --include-from=/tmp/files.include --exclude-from=/tmp/files.exclude /usr/etc/ /etc/
