#!/bin/bash
#set -x

DISK_NAME="$1"
PARTITIONS_FILE="$2"

MBR_PARTIIONS=()
MBR_PARTITION_CODES=()
MBR_PARTITIONS_BOOTABLE=()
PARTITIONS_NAMES=()

full_out=""
full_out+="o\n" # clear the in memory partition table and create a new GPT table
full_out+="y\n" # confirm"

i=1

while read line; do
  # trim leading spaces
  line=$(echo "$line" | sed 's/^ *//')
  #echo "line=$line"
  
  if [[ $line =~ ^# ]]; then 
    # echo "line is commented";
    continue
  fi

  # split the line into indexable array
  readarray -d ' ' -t split < <(echo -n $line)

  part_name="${split[0]}"
  part_size="${split[1]}"
  part_gpt_hex_code="${split[2]}"
  part_mbr_hex_code="${split[3]}"
  part_mbr_bootable="${split[4]}"

  full_out+="n\n" # new partition
  full_out+="$i\n" # partition number
  full_out+="\n" # default - start at beginning of empyty space
  if [[ ! -z "$part_size"  ]] && [[ "$part_size" != '-'  ]]; then
    full_out+="+${part_size}\n" # size of new partition
  else
    full_out+="\n" # default - the rest of space
  fi
  full_out+="${part_hex_code}\n" # Hex code of the new partition type\n
  full_out+="c\n" # set GPT partition name\n"
  
  # When there is only  
  if [[ $i > 1 ]]; then
    full_out+="$i\n" # number of partition to rename
  fi
  
  full_out+="${part_name}\n" # new partition name
  
  PARTITION_NAMES+=("$part_name")
  if [[ ! -z "$part_mbr_hex_code"  ]] && [[ "$part_mbr_hex_code" != '-'  ]]; then
    MBR_PARTIIONS+=("$i")
    MBR_PARTITION_CODES+=("$part_mbr_hex_code")
    if [[ ! -z "$part_mbr_bootable"  ]] && [[ "$part_mbr_bootable" != '-'  ]]; then
      MBR_PARTITIONS_BOOTABLE+=("$part_mbr_bootable")
    else
      MBR_PARTITIONS_BOOTABLE+=("-")
    fi
  fi
  i=$((i+1))
done < "$PARTITIONS_FILE"

full_out+="r\n" # switch to MBR mode
full_out+="h\n" # create hybrid MBR record
full_out+="${MBR_PARTIIONS[@]}\n" # partitions to add to MBR record
full_out+="n\n" # don't make GPT partition the first MBR partition

MBR_PARTITIONS_LENGTH=${#MBR_PARTIIONS[@]}
if [[ $MBR_PARTITIONS_LENGTH > 4 ]]; then
  echo "You can't have more than 4 primary MBR partitions!" >&2
  exit 1;
fi
for (( j=0; j<${MBR_PARTITIONS_LENGTH}; j++ )); do
  part_mbr_hex_code="${MBR_PARTITION_CODES[$j]}"
  part_mbr_bootable="${MBR_PARTITIONS_BOOTABLE[$j]}"
  full_out+="${part_mbr_hex_code}\n" # mbr code
  full_out+="${part_mbr_bootable}\n" # mbr bootable
done
if [[ $j < 4 ]]; then
  full_out+="n\n" # no other partirions needed
fi
full_out+="p\n" # print the partition table
full_out+="w\n" # write the partition table
full_out+="y\n" # confirm write
full_out+="q\n" # and we're done

echo -e $full_out | gdisk ${DISK_NAME}

