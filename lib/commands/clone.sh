#!/bin/bash

function clone {
	[[ ! $1 ]] && help_err clone
	local git_repo=$1
	is_github_shorthand "$git_repo"
	if is_github_shorthand "$git_repo"; then
		if [[ -e "$git_repo/.git" ]]; then
			local msg="$git_repo also exists as a filesystem path,"
			msg="${msg} use \`homeshick clone ./$git_repo' to circumvent the github shorthand"
			warn 'clone' "$msg"
		fi
		git_repo="https://github.com/$git_repo.git"
	fi
	local cloned_castle_name
	cloned_castle_name=$(repo_basename "$git_repo")
	local repo_path
	# repos is a global variable
	# shellcheck disable=SC2154
	repo_path=$repos"/"$cloned_castle_name
	pending 'clone' "$git_repo"
	test -e "$repo_path" && err "$EX_ERR" "$repo_path already exists"

	local git_out
	version_compare "$GIT_VERSION" 1.6.5
	if [[ $? != 2 ]]; then
		if [ -n "$HOMESHICK_CLONE_BRANCH" ];then
			git_out=$(git clone -b "$HOMESHICK_CLONE_BRANCH" --recursive "$git_repo" "$repo_path" 2>&1)
		else
			git_out=$(git clone --recursive "$git_repo" "$repo_path" 2>&1)
		fi;
		# shellcheck disable=SC2181
		[[ $? == 0 ]] || err "$EX_SOFTWARE" "Unable to clone $git_repo. Git says:" "$git_out"
		success
	else
		git_out=$(git clone "$git_repo" "$repo_path" 2>&1) || \
			err "$EX_SOFTWARE" "Unable to clone $git_repo. Git says:" "$git_out"
        if [ -n "$HOMESHICK_CLONE_BRANCH" ];then
            git_out=$(git branch "$HOMESHICK_CLONE_BRANCH" "origin/$HOMESHICK_CLONE_BRANCH" && git checkout "$HOMESHICK_CLONE_BRANCH") || \
				err "$EX_SOFTWARE" "Cannot checkout branch '$HOMESHICK_CLONE_BRANCH' for $git_repo. Git says:" "$git_out"
        fi;
		success

		pending 'submodules' "$git_repo"
		git_out=$(cd "$repo_path"; git submodule update --init 2>&1) || \
			err "$EX_SOFTWARE" "Unable to clone submodules for $git_repo. Git says:" "$git_out"
		success
	fi
        is_truthy "$HOMESHICK_USE_CASTLE_ROOT" && set_castle_root_mode "$cloned_castle_name"
        [ -n "$HOMESHICK_IGNORE" ] && echo "$HOMESHICK_IGNORE" | tr ',' '\n' >> "$repo_path/.git/info/exclude"
	return "$EX_SUCCESS"
}

function symlink_cloned_files {
	local cloned_castles=()
	while [[ $# -gt 0 ]]; do
		local git_repo=$1
		if is_github_shorthand "$git_repo"; then
			git_repo="https://github.com/$git_repo.git"
		fi
		local castle
		castle=$(repo_basename "$git_repo")
		shift
		local repo="$repos/$castle"
		if is_castle_root_mode_enabled "$castle"; then
			local search_dir="$repo";
		elif [ -d "$repo/home" ]; then
			local search_dir="$repo/home";
		else
			continue;
		fi
		local num_files
		num_files=$(find "$search_dir" -mindepth 1 -maxdepth 1 | wc -l | tr -dc "0123456789")
		if [[ $num_files -gt 0 ]]; then
			cloned_castles+=("$castle")
		fi
	done
	ask_symlink "${cloned_castles[@]}"
	return "$EX_SUCCESS"
}

# Convert username/repo into https://github.com/username/repo.git
function is_github_shorthand {
	if [[ ! $1 =~ \.git$ && $1 =~ ^([0-9A-Za-z-]+/[0-9A-Za-z_\.-]+)$ ]]; then
		return 0
	fi
	return 1
}

# Get the repo name from an URL
function repo_basename {
if [[ $1 =~ ^[^/:]+: ]]; then
	# For scp-style syntax like '[user@]host.xz:path/to/repo.git/',
	# remove the '[user@]host.xz:' part.
	basename "${1#*:}" .git
else
	basename "$1" .git
fi
}
