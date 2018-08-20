#!/bin/sh
for sample in samples/*.d
do
    echo "Testing '$sample'"
    path="samples/$(basename "$sample" .d)"
    dub run -q -- -I./samples/ -o "$path.generated" $sample
    diff "$path.generated" "$path.expected"
done
