#!/bin/bash

# Check if agrument "truthy" like integer 1, or string true
function is_truthy {
	if [ -n "$1" ] && ([ "$1" = "true" ] || [ "$1" = "1" ]);then
		return 0
	else
		return 1
	fi;
}
