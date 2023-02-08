#!/bin/bash
#set -x

IMG_NAME="$1"
IMG_SIZE="$2"

# Create an image file
dd bs=1 seek="$IMG_SIZE" of="$IMG_NAME" < /dev/null

# make into sparse file. see https://www.cyberciti.biz/faq/how-to-create-tar-gz-file-in-linux-using-command-line/
fallocate -d "$IMG_NAME"
#zstd --sparse "$IMG_NAME"
#gzip -k "$IMG_NAME"
