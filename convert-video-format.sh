#!/bin/bash

# Description:
#   This script converts all video files in a given directory to a specified output format using ffmpeg.
#   It uses pushd and popd to change to the directory where the video files are located,
#   ensuring that the user's current working directory remains unchanged after the script runs.
#   
#   NOTE:
#     If no video files are found in the directory, the script will inform the user and exit.
#     If there are non-video files in the directory, this script will not gracefully handle them.

# Usage:
#   ./convert-video-format.sh --directory /path/to/directory --output-extension mp4

# Default values
DIRECTORY=""
OUTPUT_EXTENSION="mp4"

# Process command line arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
    --directory|-d)
        DIRECTORY="$2"
        shift 2
        ;;
    --output-extension|-o)
        OUTPUT_EXTENSION="$2"
        shift 2
        ;;
    *)
        echo "Unknown option: $1"
        exit 1
        ;;
    esac
done

# Check if a directory argument was provided
if [ -z "${DIRECTORY}" ]; then
    echo "Error: No directory provided."
    echo "Usage: $0 --directory /path/to/files --output-extension mp4"
    exit 1
fi

# Change to the specified directory using pushd to save the current directory
pushd "$DIRECTORY" > /dev/null || exit

# Find all video files in the directory, assuming video files have extensions common in video formats
shopt -s nullglob
video_files=(*.*)

# If no video files are found, print a message, pop directory, and exit
if [ ${#video_files[@]} -eq 0 ]; then
    echo "No video files found in the specified directory."
    popd > /dev/null
    exit 1
fi

# Loop through all video files
for file in "${video_files[@]}"; do
    # Set the output filename by changing the extension to the specified output extension
    output="${file%.*}.${OUTPUT_EXTENSION}"
    # Use ffmpeg to convert the video to the specified format
    ffmpeg -i "$file" "$output"
done

# Restore the previous directory using popd
popd > /dev/null

