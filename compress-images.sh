#!/bin/bash

# Usage:
#   ./compress-images.sh <path_to_folder_with_jpgs>

# Check if a directory argument was provided
if [ -z "$1" ]; then
	echo "Error: No directory provided."
	echo "Usage: $0 /path/to/jpeg/files"
	exit 1
fi

# Directory containing the jpeg files
DIRECTORY="$1"

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

for file in "${DIRECTORY}"/*.JPG; do
	# macOS `stat` command uses a different syntax
	FILESIZE=$(stat -f%z "$file")

	# Skip non-existent files (e.g., if no .jpg files are present)
	if [ -z "$FILESIZE" ]; then
		continue
	fi

	filename=$(basename -- "$file")
	extension="${filename##*.}"
	filename="${filename%.*}"

	# If the file is larger than the MAXSIZE
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

	# Reset the quality for the next image
	QUALITY=85
done

echo "Compression completed. Compressed files are located in $TEMP_DIR"
