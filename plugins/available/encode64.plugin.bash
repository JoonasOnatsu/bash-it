# Encode64 plugin ported from OMZ.
#
# Source:
# https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/encode64
#
# shellcheck shell=bash
# shellcheck source=/dev/null
# shellcheck disable=SC2312

cite about-plugin
about-plugin 'Base64 encoding/decoding'

function encode64() {
	if [[ $# -eq 0 ]]; then
		cat | base64
	else
		printf '%s' "$1" | base64
	fi
}

function encodefile64() {
	if [[ $# -eq 0 ]]; then
		printf 'You must provide a filename!\n' >&2
	else
		base64 -i "$1" -o "$1.txt"
		printf "%s\'s content encoded in base64 and saved as \"%s.txt\"\n" "${1}" "${1}" >&1
	fi
}

function decode64() {
	if [[ $# -eq 0 ]]; then
		cat | base64 --decode
	else
		printf '%s' "$1" | base64 --decode
	fi
}
alias e64=encode64
alias ef64=encodefile64
alias d64=decode64
