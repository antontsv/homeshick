#!/bin/bash

function pull {
	[[ ! $1 ]] && help_err pull
	local castle=$1
	# repos is a global variable
	# shellcheck disable=SC2154
	local repo="$repos/$castle"
	pending 'pull' "$castle"
	castle_exists 'pull' "$castle"
	if ! repo_has_upstream "$repo"; then
		ignore 'no upstream' "Could not pull $castle, it has no upstream"
		return "$EX_SUCCESS"
	fi

	local git_out

	# just fetch first - no merging yet
	if ! git_out=$(cd "$repo" && git fetch 2>&1);then
         err "$EX_SOFTWARE" "Unable to fetch as a part of git pull on $repo. Git says:" "$git_out"
    fi;

	# verify signature
	local vout
	# shellcheck disable=SC2154
	if [ -r "$trusted_keys_file" ];then
		if ! vout=$($verify_tool sigcheck -k "$trusted_keys_file" -p "$repo" -r FETCH_HEAD 2>&1);then
			err "$EX_SOFTWARE" "Verify signature on fetched data, stopping pull for $repo. Signature check says:" "$vout"
		fi;
	fi;

	if ! git_out=$(cd "$repo" && git merge FETCH_HEAD 2>&1);then
         # try to reset bad merge, to get to a clean state:
         cd "$repo" && git reset --merge 1>/dev/null 2>&1
         # abort any rebase if pull has been overriden to do a rebase:
         cd "$repo" && git rebase --abort 1>/dev/null 2>&1
         err "$EX_SOFTWARE" "Unable to pull $repo. Git says:" "$git_out"
    fi;

    version_compare "$GIT_VERSION" 1.7.10
    if [[ $? == 2 ]];then
        submodule_fix_out=$(cd "$repo" && submodule_force_relative_path "$repo" 2>&1) ||\
			err "$EX_SOFTWARE" "Unable force relative path for submodules in $repo. Output says:" "$submodule_fix_out"
    fi;

	version_compare "$GIT_VERSION" 1.6.5
	if [[ $? != 2 ]]; then
		git_out=$(cd "$repo" && git submodule update --recursive --init 2>&1) || \
			err "$EX_SOFTWARE" "Unable update submodules for $repo. Git says:" "$git_out"
	else
		git_out=$(cd "$repo" && git submodule update --init 2>&1) || \
			err "$EX_SOFTWARE" "Unable update submodules for $repo. Git says:" "$git_out"
	fi
	success
	return "$EX_SUCCESS"
}

function symlink_new_files {
	local updated_castles=()
	while [[ $# -gt 0 ]]; do
		local castle=$1
		shift
		local repo="$repos/$castle"
		if ! is_castle_root_mode_enabled "$castle" && [[ ! -d $repo/home ]]; then
			continue;
		fi
		local git_out
		local now
		now=$(date +%s)
		if ! git_out=$(cd "$repo" && git diff --name-only --diff-filter=A "HEAD@{(($now-$T_START+1)).seconds.ago}" HEAD -- home 2>/dev/null | wc -l 2>&1); then
			continue  # Ignore errors, this operation is not mission critical
		fi
		if [[ $git_out -gt 0 ]]; then
			updated_castles+=("$castle")
		fi
	done
	ask_symlink "${updated_castles[@]}"
	return "$EX_SUCCESS"
}

function submodule_force_relative_path {
    if [ -f .gitmodules ];then
        local modules=()
		while IFS='' read -r line; do modules+=("$line"); done < <(grep 'path = ' .gitmodules | awk '{print $3}')
        local parent_separator=";"
        for module in "${modules[@]}"; do
            local module_full_path="${2//$parent_separator//}$module"
            local only_slashes="${module_full_path//[^\/]}"
            local module_path_level_count=$((${#only_slashes} + 1))
			local prefix
            prefix=$(printf "%0.s../" $(seq 1 $module_path_level_count))
            echo "gitdir: ${prefix}.git/modules/${2//$parent_separator//modules/}$module" > "${1}/$module_full_path/.git"
            local parents="${2//[^$parent_separator]}"
            # .git/module counts as 2 levels, plus one level for each nested parent
			local prefix2
            prefix2=$(printf "%0.s../" $(seq 1 $((module_path_level_count + 2 + ${#parents}))))
            git config -f "${1}/.git/modules/${2//$parent_separator//modules/}$module/config" core.worktree "${prefix2}$module_full_path"
            submodule_fix_out=$(cd "${1}/$module_full_path" && submodule_force_relative_path "$1" "${2:-}$module$parent_separator" 2>&1) || \
				err "$EX_SOFTWARE" "Unable force relative path for submodules in $repo. Output says:" "$submodule_fix_out"
        done
    fi;
}
