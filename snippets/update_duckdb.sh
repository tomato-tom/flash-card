#!/bin/bash

build_dir="$HOME/git/"
bin_dir="$HOME/.local/bin"

if [ ! "$build_dir/duckdb" ]; then
    sudo apt-get update
    sudo apt-get install -y git g++ cmake ninja-build libssl-dev libcurl4-openssl-dev
    cd "$build_dir"
    git clone https://github.com/duckdb/duckdb
    cd duckdb
else
    cd "$build_dir/duckdb"
    make clean
fi

BUILD_EXTENSIONS='json' make -j$(nproc)

if ! command -v duckdb >/dev/null 2>&1; then
    ln -s "$build_dir/duckdb/build/release/duckdb" "$bin_dir/duckdb"
fi

beep -r 3
