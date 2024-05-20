#!/bin/bash

while read -r repository
do
  if [[ -z "${repository}" ]]
  then
    continue
  fi
  echo "Triggering ${repo_owner}/${repository}"
  curl -L \
    -X POST \
    -H "Accept: application/vnd.github+json" \
    -H "Authorization: Bearer ${token}" \
    -H "X-GitHub-Api-Version: 2022-11-28" \
    https://api.github.com/repos/${repo_owner}/${repository}/dispatches \
    -d '{"event_type":"rebuild"}'
done < $(dirname -- $0)/repos
