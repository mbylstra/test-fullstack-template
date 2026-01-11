#!/bin/bash

# Wrapper script that delegates to the mobile-app customize-template script
exec "$(dirname "$0")/../mobile-app/scripts/customize-template.sh" "$@"
