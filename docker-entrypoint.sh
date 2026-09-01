#!/bin/sh
set -e

if [ -f Gemfile ] && ! bundle check >/dev/null 2>&1; then
  bundle install
fi

exec "$@"
