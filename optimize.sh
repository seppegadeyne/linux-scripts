# /bin/bash

for png in `find . -type f -name "*.png"`; do
        optipng $png
done

for jpg in `find . -type f \( -name "*.jpg" -o -name "*.jpeg" \)`; do
        jpegoptim $jpg
done
