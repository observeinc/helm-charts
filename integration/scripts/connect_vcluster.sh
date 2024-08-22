#!/bin/bash

# Check if VCLUSTER_NAME is set
if [ -z "$VCLUSTER_NAME" ]; then
  echo "Error: VCLUSTER_NAME environment variable is not set."
  exit 1
fi

# Run the vcluster connect command in the foreground and wait for it to finish
echo "Connecting to vcluster: $VCLUSTER_NAME"
vcluster connect --debug --background-proxy "$VCLUSTER_NAME"

# Once the connect command has finished, run the vcluster list command
echo "Listing vclusters..."
vcluster list
