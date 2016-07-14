#!/bin/bash

function homeshick_config_set {
	local castle="$1"
	local config_key="$2"
	local config_value="$3"
	git config -f "$repos/../${castle}.config" "homeshick.$config_key" "$config_value"
}

function homeshick_config_get {
    local castle="$1"
    local config_key="$2"
    git config -f "$repos/../${castle}.config" "homeshick.$config_key"
}

function set_castle_root_mode {
	local castle="$1"
	homeshick_config_set "$1" "use-castle-root" true
}

function is_castle_root_mode_enabled {
	config_value=$(homeshick_config_get "$1" "use-castle-root")
	if [ $? -eq 0 ] && [ "$config_value" = "true" ];then
		return 0
	else
		return 1
	fi
}

function castle_exists {
	local action=$1
	local castle=$2
	local repo="$repos/$castle"
	if [[ ! -d $repo ]]; then
		err $EX_ERR "Could not $action $castle, expected $repo to exist"
	fi
}

function home_exists {
	local action=$1
	local castle=$2
	local repo="$repos/$castle"
        if ! is_castle_root_mode_enabled "$castle" && [ ! -d "$repo/home" ]; then
                err $EX_ERR "Could not $action $castle, expected $repo to contain a home folder"
        fi
}

function list_castle_names {
	while IFS= read -d $'\0' -r repo ; do
		local reponame=$(basename "${repo%/.git}")
		printf "$reponame\n"
	done < <(find -L "$repos" -mindepth 2 -maxdepth 2 -name .git -type d -print0 | sort -z)
	return $EX_SUCCESS
}

function abs_path {
	local dir=$(dirname "$1")
	local base=$(basename "$1")
	(cd "$dir" &>/dev/null; printf "%s/%s" "$PWD" "$base")
}
