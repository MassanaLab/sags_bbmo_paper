#!/usr/bin/env bash

set -euo pipefail

read -rp "Project name: " W

if [[ -z "$W" ]]; then
    echo "ERROR: Project name cannot be empty"
    exit 1
fi

echo "Running waterfall for project: $W"

bash scripts/3-use_parser_and_sorter.sh

bash scripts/4-cat_all_together.sh

bash scripts/5-make_AF_from_ANI_length.sh

bash scripts/6-full_report.sh "$W"

# make sure you are in marbit's R enviroemnt -> conda activate R-4.5.1

Rscript scripts/7-histograms_ANI_review.R "$W"
