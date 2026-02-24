#!/bin/bash

OLD_APP="$1"
NEW_APP="$2"

if [ -z "$OLD_APP" ] || [ -z "$NEW_APP" ]; then
    echo "Usage: $0 <old_app_path> <new_app_path>"
    exit 1
fi

echo "Waiting for application to quit..."
sleep 2

while pgrep -f "$OLD_APP" > /dev/null 2>&1; do
    echo "Application still running, waiting..."
    sleep 1
done

echo "Removing old application..."
rm -rf "$OLD_APP"

echo "Installing new application..."
cp -R "$NEW_APP" "$OLD_APP"

echo "Launching new application..."
open "$OLD_APP"

echo "Update completed!"
