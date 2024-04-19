#!/bin/bash

# Description:
#   This script converts all .avi files in a specified directory to .mp4 format using ffmpeg.
#   It uses pushd and popd to change to the directory where the .avi files are located,
#   ensuring that the user's current working directory remains unchanged after the script runs.
#   If no .avi files are found in the specified directory, the script will inform the user and exit.

# Usage:
#   ./convert-avi-to-mp4.sh /path/to/directory

# Check if the user provided a directory as an argument
if [ $# -eq 0 ]; then
    echo "Please provide a directory."
    exit 1
fi

# Change to the specified directory using pushd to save the current directory
pushd "$1" > /dev/null || exit

# Check if there are any .avi files in the specified directory
shopt -s nullglob
avi_files=(*.avi)

# If no .avi files are found, print a message, pop directory, and exit
if [ ${#avi_files[@]} -eq 0 ]; then
    echo "No .avi files found in the specified directory."
    popd > /dev/null
    exit 1
fi

# Loop through all .avi files
for file in "${avi_files[@]}"; do
    # Set the output filename by replacing .avi with .mp4
    output="${file%.avi}.mp4"
    # Use ffmpeg to convert from .avi to .mp4
    ffmpeg -i "$file" "$output"
done

# Restore the previous directory using popd
popd > /dev/null
