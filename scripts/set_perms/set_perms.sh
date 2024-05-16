#!/bin/bash

while read -r line
do
  chmod ${line}
done < $(dirname -- $0)/files