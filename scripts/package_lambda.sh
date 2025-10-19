#!/usr/bin/env bash
set -euo pipefail
rm -rf build
mkdir -p build
ZIP=build/etl_lambda.zip

# Copy python code
cd src
zip -r "../${ZIP}" handlers etl -x "*/__pycache__/*"
cd ..

echo "Lambda packaged to ${ZIP}"