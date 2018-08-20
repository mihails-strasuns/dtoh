#!/bin/sh

export DRT_COVOPT="merge:1 dstpath:./cov"
mkdir -p cov

for sample in samples/*.d
do
    echo "Testing '$sample'"
    path="samples/$(basename "$sample" .d)"
    dub run -b cov -q -- -I./samples/ -o "$path.generated" $sample
    diff "$path.generated" "$path.expected"
done

grep -h "covered" ./cov/source-*
