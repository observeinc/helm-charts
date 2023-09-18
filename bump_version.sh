#!/bin/bash

CHART_PATH=$1

if [ -z "$CHART_PATH" ]; then
    echo "Usage: $0 <path_to_chart>"
    exit 1
fi

# Get the specific version line (excluding appVersion or dependencies)
CURRENT_VERSION_LINE=$(awk '/^version:/ {print $0}' $CHART_PATH/Chart.yaml)
CURRENT_VERSION=$(echo $CURRENT_VERSION_LINE | awk '{print $2}')
BUMPED_VERSION=$(echo $CURRENT_VERSION | awk -F. '{$NF = $NF + 1;} 1' OFS=.)

# Replace the version in Chart.yaml
sed -i "s/^version: $CURRENT_VERSION/version: $BUMPED_VERSION/" $CHART_PATH/Chart.yaml
