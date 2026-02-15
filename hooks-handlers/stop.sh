#!/usr/bin/env bash

# Stop hook intentionally no-op.
# Badge rendering is handled directly by assistant text output
# (glyph tags + code spans), not via hook-side terminal ANSI output.

echo '{"continue":true}'
