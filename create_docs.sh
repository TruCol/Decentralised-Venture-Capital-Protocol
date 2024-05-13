#!/bin/bash
rm -r doc_output
mkdir doc_output
forge doc --out doc_output
mkdir -p doc_output/manual
cp -r docs/manual/* doc_output/manual
cp -r SUMMARY.md doc_output/manual/SUMMARY.md

# Copy/overwrite the book
rm doc_output/book.toml
cp book.toml doc_output/book.toml

forge doc --out doc_output --build --serve --open
