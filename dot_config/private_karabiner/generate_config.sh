#!/bin/bash

function generate() {
    jsonnet -o $1.json $1.jsonnet
}

if [ -d private_assets ]; then
    cd private_assets/private_complex_modifications
else
    cd assets/complex_modifications
fi

for f in *.jsonnet; do
    generate ${f%.*}
done
