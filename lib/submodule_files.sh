#!/usr/bin/env bash
# This script is meant to be used in conjunction with
# `git submodule foreach'.
# It runs outputs all files tracked by a submodule.
# The paths are outputted relative to $root
root="$1"
toplevel="$2"
path="$3"
root_mode="${4:-0}"
# toplevel/path relative to root
repo=${toplevel/#$root/}/$path
# If we are at root, remove the slash in front
repo=${repo/#\//}
# We are only interested in submodules under home/
if [ "$root_mode" -eq 1 ] || [[ $repo =~ ^home ]]; then
	cd "$toplevel/$path"
	# List the files and prefix every line
	# with the relative repo path
	git ls-files | sed "s#^#${repo//#/\\#}/#"
fi
