#!/bin/bash
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
type jekyll sushi  # Will fail if any is not available.

# Temporarily cd into the dir where this script resides.
pushd . &>/dev/null
cd $( dirname "$0" )
TOP="${PWD}"

# Run sushi.
sushi fsh -o "${SUSHI_OUT}"

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

# Publish the generated IG HTML into the docs folder.
rsync -av --delete output/ "${TOP}"/../docs

# View the generated IG.
open output/index.html

# Return to the location before this script was invoked.
popd &>/dev/null
