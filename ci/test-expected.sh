#!/bin/sh

set -xe

for sample in samples/*.expected
do
    gcc -S -x c -std=c99 $sample
done
