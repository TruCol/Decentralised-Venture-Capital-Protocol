#!/usr/bin/env bash

# Solhint's repo doesn't support pre-commit out-of-the-box, so this script is the workaround.

VERSION="4.5.4"

if ! which solhint 1>/dev/null || [[ $(solhint --version) != "$VERSION" ]]; then
  echo "Installing solhint@$VERSION"
  npm install -g solhint@$VERSION
fi

TMPFILE=$(mktemp)
solhint $@
echo "$(solhint $@)" > "$TMPFILE"
rm "$TMPFILE"