#!/bin/sh
printf '\033c\033]0;%s\a' Backrooms Unhinged
base_path="$(dirname "$(realpath "$0")")"
"$base_path/Backrooms Unhinged.x86_64" "$@"
