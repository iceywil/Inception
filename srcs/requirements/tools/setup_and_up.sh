#!/usr/bin/env bash
set -euo pipefail
sb() { echo "[setup_and_up] $*"; }

# Single-run script to: prepare project dirs, download/register box, run vagrant up
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BOXURL="https://vagrantcloud.com/debian/boxes/bookworm64/versions/12.20250126.1/providers/virtualbox/amd64/vagrant.box"
BOXFILE="$SCRIPT_DIR/debian_bookworm64_virtualbox_12.20250126.1.box"
VAGRANT_HOME="$SCRIPT_DIR/.vagrant.d"
TMPDIR="$SCRIPT_DIR/vagrant_tmp"

sb "Using project root: $SCRIPT_DIR"
sb "VAGRANT_HOME is now $VAGRANT_HOME"

mkdir -p "$VAGRANT_HOME" "$TMPDIR"
chown "$(id -u):$(id -g)" "$VAGRANT_HOME" "$TMPDIR" 2>/dev/null || true

# If box already registered in the VAGRANT_HOME, skip add
box_registered=false
if VAGRANT_HOME="$VAGRANT_HOME" vagrant box list 2>/dev/null | grep -q '^debian/bookworm64'; then
  box_registered=true
  sb "Box 'debian/bookworm64' already registered in VAGRANT_HOME=$VAGRANT_HOME"
fi

if [ "$box_registered" = false ]; then
  if [ -f "$BOXFILE" ]; then
    sb "Box file already exists at $BOXFILE — will attempt to add it to Vagrant"
  else
    sb "Downloading box to: $BOXFILE"
    curl -L --fail --continue-at - -o "$BOXFILE" "$BOXURL"
  fi

  sb "Adding box using VAGRANT_HOME=$VAGRANT_HOME and TMPDIR=$TMPDIR"
  VAGRANT_HOME="$VAGRANT_HOME" TMPDIR="$TMPDIR" \
    vagrant box add --name debian/bookworm64 --provider virtualbox "$BOXFILE"
fi

sb "Starting VM with VAGRANT_HOME=$VAGRANT_HOME and TMPDIR=$TMPDIR"
export VAGRANT_HOME TMPDIR
cd "$SCRIPT_DIR"
vagrant up --provider=virtualbox

sb "Done"
