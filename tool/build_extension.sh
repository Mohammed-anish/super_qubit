#!/bin/bash

# Navigate to the extension project
cd tool/super_qubit_devtools_extension

# Get dependencies
flutter pub get

# Build using the official command
# This builds the extension and copies it to the correct location in the parent package
dart run devtools_extensions build_and_copy --source=. --dest=../../extension/devtools

echo "DevTools extension built and copied via official command."
