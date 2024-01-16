# Based on OMZ helper library clipboard integration.
#
# Source:
# https://github.com/ohmyzsh/ohmyzsh/blob/master/lib/clipboard.zsh
#
# System clipboard integration
#
# This file has support for doing system clipboard copy and paste operations
# from the command line in a generic cross-platform fashion.
#
# This is uses essentially the same heuristic as neovim, with the additional
# special support for Cygwin.
# See: https://github.com/neovim/neovim/blob/e682d799fa3cf2e80a02d00c6ea874599d58f0e7/runtime/autoload/provider/clipboard.vim#L55-L121
#
# - wl-copy, wl-paste (if $WAYLAND_DISPLAY is set)
# - xsel (if $DISPLAY is set)
# - xclip (if $DISPLAY is set)
# - lemonade (for SSH) https://github.com/pocke/lemonade
# - doitclient (for SSH) http://www.chiark.greenend.org.uk/~sgtatham/doit/
# - tmux (if $TMUX is set)
#
# Defines two functions, clipcopy and clippaste, based on the detected platform.
##
#
# clipcopy - Copy data to clipboard
#
# Usage:
#
#  <command> | clipcopy    - copies stdin to clipboard
#
#  clipcopy <file>         - copies a file's contents to clipboard
#
##
#
# clippaste - "Paste" data from clipboard to stdout
#
# Usage:
#
#   clippaste   - writes clipboard's contents to stdout
#
#   clippaste | <command>    - pastes contents and pipes it to another process
#
#   clippaste > <file>      - paste contents to a file
#
# Examples:
#
#   # Pipe to another process
#   clippaste | grep foo
#
#   # Paste to a file
#   clippaste > file.txt
#

# shellcheck shell=bash
# shellcheck source=/dev/null
# shellcheck disable=SC2312,SC2317,SC2002

function detect-clipboard() {

	if [[ -n ${WAYLAND_DISPLAY-} ]] && _command_exists wl-copy && _command_exists wl-paste; then
		function clipcopy() { cat "${1:-/dev/stdin}" | wl-copy &> /dev/null; }
		function clippaste() { wl-paste; }
	elif [[ -n ${DISPLAY-} ]] && _command_exists xsel; then
		function clipcopy() { cat "${1:-/dev/stdin}" | xsel --clipboard --input; }
		function clippaste() { xsel --clipboard --output; }
	elif [[ -n ${DISPLAY-} ]] && _command_exists xclip; then
		function clipcopy() { cat "${1:-/dev/stdin}" | xclip -selection clipboard -in &> /dev/null; }
		function clippaste() { xclip -out -selection clipboard; }
	elif _command_exists lemonade; then
		function clipcopy() { cat "${1:-/dev/stdin}" | lemonade copy; }
		function clippaste() { lemonade paste; }
	elif _command_exists doitclient; then
		function clipcopy() { cat "${1:-/dev/stdin}" | doitclient wclip; }
		function clippaste() { doitclient wclip -r; }
	elif [[ -n ${TMUX-} ]] && _command_exists tmux; then
		function clipcopy() { tmux load-buffer "${1:--}"; }
		function clippaste() { tmux save-buffer -; }
	else
		function _retry_clipboard_detection_or_fail() {
			local clipcmd="${1}"
			shift
			if detect-clipboard; then
				"${clipcmd}" "$@"
			else
				printf "%s: Could not detect clipboard support!" "${clipcmd}" >&2
				return 1
			fi
		}
		function clipcopy() { _retry_clipboard_detection_or_fail clipcopy "$@"; }
		function clippaste() { _retry_clipboard_detection_or_fail clippaste "$@"; }
		return 1
	fi
}

function clipcopy {
	unset -f clipcopy
	detect-clipboard || true # let one retry
	"$0" "$@"
}

function clippaste {
	unset -f clippaste
	detect-clipboard || true # let one retry
	"$0" "$@"
}
