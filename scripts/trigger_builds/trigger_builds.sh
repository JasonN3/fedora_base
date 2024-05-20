#!/bin/bash

while read -r repository
do
  if [[ -z "${repository}" ]]
  then
    continue
  fi
  echo "Triggering ${{ github.repository_owner }}/${repository}"
  curl -L \
    -X POST \
    -H "Accept: application/vnd.github+json" \
    -H "Authorization: Bearer ${{ secrets.TRIGGER_PAT }}" \
    -H "X-GitHub-Api-Version: 2022-11-28" \
    https://api.github.com/repos/${{ github.repository_owner }}/${repository}/dispatches \
    -d '{"event_type":"rebuild"}'
done < $(dirname -- $0)/repos
