# Aliases plugin ported from OMZ.
#
# Source:
# https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/aliases
#
# shellcheck shell=bash
# shellcheck source=/dev/null
# shellcheck disable=SC2312

# Load after the system completions.
# BASH_IT_LOAD_PRIORITY: 375

cite about-plugin
about-plugin 'pretty-print aliases and search for them'

function als() {
	if _command_exists python3; then
		alias | python3 "${PWD}/aliases.plugin/cheatsheet.py" "$@"
	fi
}
