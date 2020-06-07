#!/bin/bash
# Function:       Convert .jpg or .png files to webp format
# Arguments:      Arg1 is a directory, Arg2 quality factor
# Author:         seppe@fushia.be
# Copyright:      2020, seppe@fushia.be
# Version:        0.0.1
# Requires:       cwebp application

# How to use this script
[[ $# -lt 1 || "$1" = "--help" ]] && {
  echo "Usage: $(basename "$0") arg1 arg2 (arg2 is optional, 75 = default)"
  echo "Example: $(basename "$0") ./ 75"
  exit 1
}

# Check dependencies and evaluate arguments
[[ -x "$(command -v cwebp)" ]] || { echo "Error in $0, needs cwebp to run." >&2; exit 1; }
[[ -d $1 ]] || { echo "Error in $0, arg1 needs to be a valid directory" >&2; exit 1; }

# Convert image to webp with cwebp, standard quality 75
function convert() {
  [[ -f "$1" ]] && [[ -n "$1" ]] && [[ -n "$2" ]] && cwebp -q "$2" "$1" -o "${1%.*}.webp" 1>/dev/null
  [[ $? -ne 0 ]] && { echo "Error in $0, cwebp couldn't convert $1" >&2; exit 1; }
}

# Loop over directory (arg1)
for i in "${1/%\//}"/*; do
  [[ -f "$i" ]] && [[ "${i##*.}" == "jpg" ]] || [[ "${i##*.}" == "png" ]] && convert "$i" "${2:-75}"
done

# Exit successful
exit 0;