#!/bin/bash

CHART_PATH=$1

if [ -z "$CHART_PATH" ]; then
    echo "Usage: $0 <path_to_chart>"
    exit 1
fi

# Check for unstaged, staged, and committed changes to the Chart.yaml
UNSTAGED_CHANGES=$(git diff --name-only $CHART_PATH/Chart.yaml)
STAGED_CHANGES=$(git diff --cached --name-only $CHART_PATH/Chart.yaml)
COMMITTED_CHANGES=$(git diff --name-only origin/main...HEAD $CHART_PATH/Chart.yaml)

# If no changes in any of the categories, exit
if [ -z "$UNSTAGED_CHANGES" ] && [ -z "$STAGED_CHANGES" ] && [ -z "$COMMITTED_CHANGES" ]; then
    echo "No changes detected in $CHART_PATH/Chart.yaml, skipping bump."
    exit 0
fi

# Get the specific version line (excluding appVersion or dependencies) for the current branch and main branch
CURRENT_VERSION_LINE=$(awk '/^version:/ {print $0}' $CHART_PATH/Chart.yaml)
CURRENT_VERSION=$(echo $CURRENT_VERSION_LINE | awk '{print $2}')
MAIN_VERSION=$(git show origin/main:$CHART_PATH/Chart.yaml | awk '/^version:/ {print $2}')

# If the version has already been bumped compared to main, exit
if [ "$CURRENT_VERSION" != "$MAIN_VERSION" ]; then
    echo "Version in $CHART_PATH/Chart.yaml has already been bumped, skipping bump."
    exit 0
fi

BUMPED_VERSION=$(echo $CURRENT_VERSION | awk -F. '{$NF = $NF + 1;} 1' OFS=.)

# Replace the version in Chart.yaml
sed -i "s/^version: $CURRENT_VERSION/version: $BUMPED_VERSION/" $CHART_PATH/Chart.yaml
