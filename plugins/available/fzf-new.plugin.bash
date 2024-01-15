# Based on OMZ FZF plugin, ported partially to Bash.
#
# Source:
# https://github.com/ohmyzsh/ohmyzsh/blob/master/plugins/fzf/fzf.plugin.zsh
#
# WIP: this is work in progress, just the basic stuff is ported.
#
# shellcheck shell=bash
# shellcheck source=/dev/null
# shellcheck disable=SC2207,SC2128

# Load after the system completion to make sure that the fzf completions are working
# BASH_IT_LOAD_PRIORITY: 375

cite about-plugin
about-plugin 'load fzf, if you are using it'

function fzf_setup_using_base_dir() {
	local _fzf_basedir _fzf_shelldir _fzfdirs _dir

	test -d "${FZF_BASE}" && _fzf_basedir="${FZF_BASE}"

	if [[ -z ${_fzf_basedir} ]]; then
		_fzfdirs=(
			"${HOME}/.fzf"
			"${HOME}/.nix-profile/share/fzf"
			"${XDG_DATA_HOME:-${HOME}/.local/share}/fzf"
			"/usr/local/opt/fzf"
			"/opt/homebrew/opt/fzf"
			"/usr/share/fzf"
			"/usr/local/share/examples/fzf"
		)
		for _dir in "${_fzfdirs[@]}"; do
			if [[ -d ${_dir} ]]; then
				_fzf_basedir="${_dir}"
				break
			fi
		done

		if [[ -z ${_fzf_basedir} ]]; then
			if _command_exists fzf-share && _dir="$(command fzf-share 2> /dev/null)" && [[ -d ${_dir} ]]; then
				_fzf_basedir="${_dir}"
			elif _command_exists brew && _dir="$(command brew --prefix fzf 2> /dev/null)" && [[ -d ${_dir} ]]; then
				_fzf_basedir="${_dir}"
			fi
		fi
	fi

	if [[ ! -d ${_fzf_basedir} ]]; then
		return 1
	fi

	# Fix fzf shell directory for Arch Linux, NixOS or Void Linux packages
	if [[ ! -d "${_fzf_basedir}/shell" ]]; then
		_fzf_shelldir="${_fzf_basedir}"
	else
		_fzf_shelldir="${_fzf_basedir}/shell"
	fi

	# Setup fzf binary path
	if ! _command_exists fzf && [[ ${PATH} != *${_fzf_basedir}/bin* ]]; then
		export PATH="${PATH}:${_fzf_basedir}/bin"
	fi

	# Auto-completion
	if [[ -o interactive && ${DISABLE_FZF_AUTO_COMPLETION} != "true" ]]; then
		source "${_fzf_shelldir}/completion.bash" 2> /dev/null
	fi

	# Key bindings
	if [[ ${DISABLE_FZF_KEY_BINDINGS} != "true" ]]; then
		source "${_fzf_shelldir}/key-bindings.bash"
	fi
}

function fzf_setup_using_debian() {
	if ! _command_exists apt && ! _command_exists apt-get; then
		# Not a debian based distro
		return 1
	fi

	# NOTE: There is no need to configure PATH for debian package, all binaries
	# are installed to /usr/bin by default

	local _completions _key_bindings

	case ${PREFIX} in
		*com.termux*)
			if [[ ! -f "${PREFIX}/bin/fzf" ]]; then
				# fzf not installed
				return 1
			fi
			# Support Termux package
			_completions="${PREFIX}/share/fzf/completion.bash"
			_key_bindings="${PREFIX}/share/fzf/key-bindings.bash"
			;;
		*)
			if [[ ! -d /usr/share/doc/fzf/examples ]]; then
				# fzf not installed
				return 1
			fi
			# Determine completion file path: first bullseye/sid, then buster/stretch
			_completions="/usr/share/doc/fzf/examples/completion.bash"
			[[ -f ${_completions} ]] || _completions="/usr/share/bash-completion/completions/bash"
			_key_bindings="/usr/share/doc/fzf/examples/key-bindings.bash"
			;;
	esac

	# Auto-completion
	if [[ -o interactive && ${DISABLE_FZF_AUTO_COMPLETION} != "true" ]]; then
		source "${_completions}" 2> /dev/null
	fi

	# Key bindings
	if [[ ${DISABLE_FZF_KEY_BINDINGS} != "true" ]]; then
		source "${_key_bindings}" 2> /dev/null
	fi

	return 0
}

# Indicate to user that fzf installation not found if nothing worked
function fzf_setup_error() {
	cat >&2 << 'EOF'
[bash-it] fzf plugin: Cannot find fzf installation directory.
Please add `export FZF_BASE=/path/to/fzf/install/dir` to your .bashrc
EOF
}

fzf_setup_using_debian \
	|| fzf_setup_using_base_dir \
	|| fzf_setup_error

unset -f 'fzf_setup_*'

# No need to continue if the command is not present
_command_exists fzf || return

if [[ -z ${FZF_DEFAULT_COMMAND} ]]; then
	if _command_exists fd; then
		export FZF_DEFAULT_COMMAND='fd --type f --hidden --exclude .git'
	elif _command_exists rg; then
		export FZF_DEFAULT_COMMAND='rg --files --hidden --glob "!.git/*"'
	elif _command_exists ag; then
		export FZF_DEFAULT_COMMAND='ag -l --hidden -g "" --ignore .git'
	fi
fi

fe() {
	about "Open the selected file in the default editor"
	group "fzf"
	param "1: Search term"
	example "fe foo"

	local IFS=$'\n'
	local files
	files=($(fzf-tmux --query="$1" --multi --select-1 --exit-0))
	[[ -n ${files} ]] && ${EDITOR:-vim} "${files[@]}"
}

fcd() {
	about "cd to the selected directory"
	group "fzf"
	param "1: Directory to browse, or . if omitted"
	example "fcd aliases"

	local dir
	# trunk-ignore(shellcheck/SC2312)
	dir=$(find "${1:-.}" -path '*/\.*' -prune \
		-o -type d -print 2> /dev/null | fzf +m) \
		&& cd "${dir}" || exit
}
