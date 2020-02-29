#!/bin/bash

CapstoneTemp=/CapstoneTemp/nosqlCapstoneBench
CapstoneFetch=$CapstoneTemp/CapstoneFetch
PROFILES=$CapstoneFetch/soc-pokec-profiles.txt.gz
RELATIONS=$CapstoneFetch/soc-pokec-relationships.txt.gz
CapstoneTempPROFILES=$CapstoneFetch/soc-pokec-profiles.txt.gz.CapstoneTemp

mkdir -p $CapstoneFetch

if [ ! -f $PROFILES ]; then
  echo "Downloading PROFILES"
  wget https://snap.stanford.edu/data/soc-pokec-profiles.txt.gz -O $CapstoneTempPROFILES
  gzip -dc $CapstoneTempPROFILES | sed -e 's/\t$//g' | gzip > $PROFILES
fi

if [ ! -f $RELATIONS ]; then
  echo "Downloading RELATIONS"
  wget https://snap.stanford.edu/data/soc-pokec-relationships.txt.gz -O $RELATIONS
fi
