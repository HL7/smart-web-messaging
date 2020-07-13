#!/bin/bash
#
# Generates an IG using sushi and the IG publisher tool.
# Usage: ./build.sh [sushi-output-dir]
#

set -e
set -u

SUSHI_OUT="${1:-build}"
SAMPLE_IG=https://raw.githubusercontent.com/FHIR/sample-ig/master


function refresh() {
  local script="$1"
  curl "$SAMPLE_IG/$script" > "$script" 2>/dev/null
}


# Sanity checks.
type jekyll sushi  # This command will fail if any are not installed.


# Temporarily cd into the dir where this script resides.
pushd . &>/dev/null
cd $( dirname "$0" )
TOP="${PWD}"

# Run sushi.
sushi fsh -o "${SUSHI_OUT}"
cp "${SUSHI_OUT}"/ig.ini .
mkdir -p input
cp "${SUSHI_OUT}"/input/ImplementationGuide*.json input

# Build the IG.
cd "${SUSHI_OUT}"

# Update the script that updates the publisher jar.
[[ -e _updatePublisher.sh ]] || refresh _updatePublisher.sh 

# Update the publisher jar, if missing.
[[ -d input-cache ]] && [[ -f input-cache/publisher.jar ]] \
  || bash _updatePublisher.sh -f

# Update the script that runs the publisher.
[[ -e _genonce.sh ]] || refresh _genonce.sh

# Build the IG.
bash _genonce.sh

# View the generated IG.
open output/qa.html
open output/index.html

# Return to the location before this script was invoked.
popd &>/dev/null
