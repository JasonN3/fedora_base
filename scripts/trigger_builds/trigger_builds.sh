#!/bin/bash

while read -r repository
do
  if [[ -z "${line}" ]]
  then
    continue
  fi
  curl -L \
    -X POST \
    -H "Accept: application/vnd.github+json" \
    -H "Authorization: Bearer ${{ secrets.TRIGGER_PAT }}" \
    -H "X-GitHub-Api-Version: 2022-11-28" \
    https://api.github.com/repos/${{ github.repository_owner }}/${repository}/dispatches \
    -d '{"event_type":"rebuild"}'
done < $(dirname -- $0)/repos