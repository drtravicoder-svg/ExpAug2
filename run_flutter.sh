#!/bin/bash

# Add Flutter to PATH
export PATH="/home/runner/.flutter/bin:$PATH"

# Run Flutter web on port 5000
flutter run -d web-server --web-port 5000 --web-hostname 0.0.0.0
