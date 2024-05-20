#!/bin/bash

while read -r line
do
  if [[ -z "${line}" ]]
  then
    continue
  fi
  chmod "${line[@]}"
done < "$(dirname -- "$0")/files"