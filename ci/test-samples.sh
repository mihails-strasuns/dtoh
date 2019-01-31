#!/bin/sh
set -e

$bindir/dub build -b cov -q

export DRT_COVOPT="merge:1 dstpath:./cov"
rm -rf cov && mkdir cov

for sample in samples/*.d
do
    echo "Testing '$sample'"
    path="samples/$(basename "$sample" .d)"
    ./dtoh -I./samples/ -o "$path.generated" $sample
    diff "$path.generated" "$path.expected"
done

for sample in samples_errors/*.d
do
    echo "Testing '$sample' (error messages)"
    path="samples_errors/$(basename "$sample" .d)"
    set +e
    ./dtoh $sample 2>"$path.stderr"
    set -e
    diff "$path.stderr" "$path.expected"
done

echo "Done.\n"
grep -h "covered" ./cov/source-*
