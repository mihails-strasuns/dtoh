#!/bin/sh
for sample in samples/*.d
do
    echo "Testing '$sample'"
    path="samples/$(basename "$sample" .d)"
    dub run -q -- -o "$path.generated" $sample
    diff "$path.generated" "$path.expected"
done
