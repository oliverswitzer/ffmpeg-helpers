#!/bin/bash

# Description:
#   This script compresses images in a specified directory that exceed a maximum file size.
#   Images smaller than the maximum size are copied without compression and marked as not compressed.
#   The script supports custom file extensions and outputs the processed files into a 'compressed'
#   subdirectory within the specified directory.

# Usage:
#   ./compress-images.sh [--extension jpeg] <path_to_folder>

# Default file extension
EXTENSION="jpg"

# Process command line arguments
while [[ "$#" -gt 0 ]]; do
	case $1 in
	--extension)
		EXTENSION="$2"
		shift
		;;
	*)
		DIRECTORY="$1"
		;;
	esac
	shift
done

# Check if a directory argument was provided
if [ -z "${DIRECTORY}" ]; then
	echo "Error: No directory provided."
	echo "Usage: $0 [--extension <extension>] /path/to/files"
	exit 1
fi

# Temporary directory for compressed files
TEMP_DIR="${DIRECTORY}/compressed"
mkdir -p "${TEMP_DIR}"

# Check if the temporary directory was created successfully
if [ $? -ne 0 ]; then
	echo "Error: Failed to create the temporary directory '${TEMP_DIR}'."
	echo "Make sure you have write permissions for '${DIRECTORY}'."
	exit 1
fi

# Maximum allowed filesize in bytes (4MB)
MAXSIZE=$((4 * 1024 * 1024))

# Compression quality
QUALITY=85

# Loop through files with specified extension
for file in "${DIRECTORY}"/*.${EXTENSION}; do
	# macOS `stat` command uses a different syntax
	FILESIZE=$(stat -f%z "$file")

	# Skip non-existent files (e.g., if no files with specified extension are present)
	if [ -z "$FILESIZE" ]; then
		continue
	fi

	filename=$(basename -- "$file")
	extension="${filename##*.}"
	filename="${filename%.*}"

	# Check if the file is smaller than the MAXSIZE
	if [ $FILESIZE -le $MAXSIZE ]; then
		# Copy the file to the temporary directory with NOT_COMPRESSED in the filename
		cp "$file" "${TEMP_DIR}/${filename}_NOT_COMPRESSED.${extension}"
	else
		# If the file is larger than the MAXSIZE, compress it
		while [ $FILESIZE -gt $MAXSIZE ]; do
			echo "Compressing $file because it is larger than 4MB."

			# Compress the image
			ffmpeg -i "$file" -q:v $QUALITY "${TEMP_DIR}/${filename}_compressed.${extension}" -y

			# Check the filesize of the compressed image
			FILESIZE=$(stat -f%z "${TEMP_DIR}/${filename}_compressed.${extension}")

			# If the filesize is still too large, decrease the quality and try again
			if [ $FILESIZE -gt $MAXSIZE ]; then
				QUALITY=$((QUALITY - 5))
			fi

			# Prevent infinite loops by setting a lower limit on quality
			if [ $QUALITY -le 10 ]; then
				echo "Cannot compress $file to under 4MB without significant quality loss."
				break
			fi
		done
	fi

	# Reset the quality for the next image
	QUALITY=85
done

echo "Compression completed. Compressed and copied files are located in $TEMP_DIR"
