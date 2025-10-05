#!/bin/bash

# Add Flutter to PATH
export PATH="/home/runner/.flutter/bin:$PATH"

# Build web app for release
flutter build web --release

# Serve the built app
cd build/web && python3 -m http.server 5000 --bind 0.0.0.0
