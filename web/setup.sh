#!/usr/bin/env bash
# Test harness setup: fedep installs the npm-published frontend deps, and the three blocks
# involved (richtext itself, plus the @makeform/common -> @makeform/base chain it extends)
# are symlinked from their sibling checkouts so editing + rebuilding them shows up directly.
# @grantdash/composer is the host lib @makeform/base depends on; it lives outside this repo.
set -e
cd "$(dirname "$0")/.."

COMPOSER=${COMPOSER_DIST:-$HOME/workspace/grantdash/projects/composer/dist}

npx fedep

LIB=web/static/assets/lib
mkdir -p $LIB/@makeform $LIB/@grantdash
mkdir -p $LIB/@makeform/richtext $LIB/@makeform/common $LIB/@makeform/base $LIB/@grantdash/composer
ln -sfn ../../../../../../dist            $LIB/@makeform/richtext/main
ln -sfn ../../../../../../../common/dist  $LIB/@makeform/common/main
ln -sfn ../../../../../../../base/dist    $LIB/@makeform/base/main
ln -sfn "$COMPOSER"                       $LIB/@grantdash/composer/main

for p in richtext common base; do
  [ -f "$LIB/@makeform/$p/main/index.html" ] || echo "warning: @makeform/$p not built (run ./build there)"
done
[ -f "$LIB/@grantdash/composer/main/index.min.js" ] || echo "warning: @grantdash/composer not found at $COMPOSER"
echo "harness ready — npm start"
