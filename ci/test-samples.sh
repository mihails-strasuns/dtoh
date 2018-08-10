#!/bin/sh
for sample in samples/*.d
do
    echo "Testing '$sample'"
    path="samples/$(basename "$sample" .d)"
    dub run -q -- $sample > "$path.generated"
    diff "$path.generated" "$path.expected"
done
