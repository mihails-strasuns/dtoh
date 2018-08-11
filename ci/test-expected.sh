#!/bin/sh

set -x

for sample in samples/*.expected
do
    gcc -S -x c -std=c99 $sample
done
