#!/usr/bin/env bash

[[ $- = *i* ]] && echo "Don't source this script!" && return 10

install_caddy()
{
	echo "⚠️ This installer only supports v1, which is obsoleted now that Caddy 2 is released. This script may change or go away soon. Please upgrade: https://caddyserver.com/docs/v2-upgrade"

	trap 'echo -e "Aborted, error $? in command: $BASH_COMMAND"; trap ERR; exit 1' ERR
	caddy_license="$1"
	caddy_plugins="$2"
	caddy_access_codes="$3"
	install_path="/usr/local/bin"
	caddy_os="unsupported"
	caddy_arch="unknown"
	caddy_arm=""

	# Valid license declaration is required
	if [[ "$caddy_license" != "personal" && "$caddy_license" != "commercial" ]]; then
		echo "You must specify a personal or commercial use; see getcaddy.com for instructions."
		return 9
	fi

	# Termux on Android has $PREFIX set which already ends with /usr
	if [[ -n "$ANDROID_ROOT" && -n "$PREFIX" ]]; then
		install_path="$PREFIX/bin"
	fi

	# Fall back to /usr/bin if necessary
	if [[ ! -d $install_path ]]; then
		install_path="/usr/bin"
	fi

	# Not every platform has or needs sudo (https://termux.com/linux.html)
	((EUID)) && [[ -z "$ANDROID_ROOT" ]] && sudo_cmd="sudo"

	#########################
	# Which OS and version? #
	#########################

	caddy_bin="caddy"
	caddy_dl_ext=".tar.gz"

	# NOTE: `uname -m` is more accurate and universal than `arch`
	# See https://en.wikipedia.org/wiki/Uname
	unamem="$(uname -m)"
	if [[ $unamem == *aarch64* ]]; then
		caddy_arch="arm64"
	elif [[ $unamem == *64* ]]; then
		caddy_arch="amd64"
	elif [[ $unamem == *86* ]]; then
		caddy_arch="386"
	elif [[ $unamem == *armv5* ]]; then
		caddy_arch="arm"
		caddy_arm="5"
	elif [[ $unamem == *armv6l* ]]; then
		caddy_arch="arm"
		caddy_arm="6"
	elif [[ $unamem == *armv7l* ]]; then
		caddy_arch="arm"
		caddy_arm="7"
	else
		echo "Aborted, unsupported or unknown architecture: $unamem"
		return 2
	fi

	unameu="$(tr '[:lower:]' '[:upper:]' <<<$(uname))"
	if [[ $unameu == *DARWIN* ]]; then
		caddy_os="darwin"
		caddy_dl_ext=".zip"
		vers=$(sw_vers)
		version=${vers##*ProductVersion:}
		IFS='.' read OSX_MAJOR OSX_MINOR _ <<<"$version"

		# Major
		if ((OSX_MAJOR < 10)); then
			echo "Aborted, unsupported OS X version (9-)"
			return 3
		fi
		if ((OSX_MAJOR > 10)); then
			echo "Aborted, unsupported OS X version (11+)"
			return 4
		fi

		# Minor
		if ((OSX_MINOR < 5)); then
			echo "Aborted, unsupported OS X version (10.5-)"
			return 5
		fi
	elif [[ $unameu == *LINUX* ]]; then
		caddy_os="linux"
	elif [[ $unameu == *FREEBSD* ]]; then
		caddy_os="freebsd"
	elif [[ $unameu == *OPENBSD* ]]; then
		caddy_os="openbsd"
	elif [[ $unameu == *WIN* || $unameu == MSYS* ]]; then
		# Should catch cygwin
		sudo_cmd=""
		caddy_os="windows"
		caddy_dl_ext=".zip"
		caddy_bin=$caddy_bin.exe
	else
		echo "Aborted, unsupported or unknown os: $uname"
		return 6
	fi

	########################
	# Download and extract #
	########################

	echo "Downloading Caddy for ${caddy_os}/${caddy_arch}${caddy_arm} (${caddy_license} license)..."
	caddy_file="caddy_${caddy_os}_${caddy_arch}${caddy_arm}_custom${caddy_dl_ext}"
	qs="license=${caddy_license}&plugins=${caddy_plugins}&access_codes=${caddy_access_codes}&telemetry=${CADDY_TELEMETRY}"
	# caddy_url="https://caddyserver.com/download/${caddy_os}/${caddy_arch}${caddy_arm}?${qs}"
	caddy_url="https://caddyserver.com/download?os=${caddy_os}&arch=${caddy_arch}${caddy_arm}?${qs}"
	caddy_asc="https://caddyserver.com/download/${caddy_os}/${caddy_arch}${caddy_arm}/signature?${qs}"

	type -p gpg >/dev/null 2>&1 && gpg=1 || gpg=0

	# Use $PREFIX for compatibility with Termux on Android
	dl="$PREFIX/tmp/$caddy_file"
	rm -rf -- "$dl"
  echo "candy url is: ${caddy_url}"

	if type -p curl >/dev/null 2>&1; then
		curl -fsSL "$caddy_url" -u "$CADDY_ACCOUNT_ID:$CADDY_API_KEY" -o "$dl"
		((gpg)) && curl -fsSL "$caddy_asc" -u "$CADDY_ACCOUNT_ID:$CADDY_API_KEY" -o "$dl.asc"
	elif type -p wget >/dev/null 2>&1; then
		wget --quiet --header "Authorization: Basic $(echo -ne "$CADDY_ACCOUNT_ID:$CADDY_API_KEY" | base64)" "$caddy_url" -O "$dl"
		((gpg)) && wget --quiet --header "Authorization: Basic $(echo -ne "$CADDY_ACCOUNT_ID:$CADDY_API_KEY" | base64)" "$caddy_asc" -O "$dl.asc"
	else
		echo "Aborted, could not find curl or wget"
		return 7
	fi

	# Verify download
	if ((gpg)); then
		keyservers=(
			ha.pool.sks-keyservers.net
			hkps.pool.sks-keyservers.net
			pool.sks-keyservers.net
			keyserver.ubuntu.com)
		keyserver_ok=0 n_keyserver=${#keyservers[@]}
		caddy_pgp="65760C51EDEA2017CEA2CA15155B6D79CA56EA34"
		while ((!keyserver_ok && n_keyserver))
		do
			((n_keyserver--))
			gpg --keyserver ${keyservers[$n_keyserver]} --recv-keys $caddy_pgp >/dev/null 2>&1 &&
				keyserver_ok=1
		done
		if ((!keyserver_ok))
		then
			echo "No valid response from keyservers"
		elif gpg -q --batch --verify "$dl.asc" "$dl" >/dev/null 2>&1; then
			rm -- "$dl.asc"
			echo "Download verification OK"
		else
			rm -- "$dl.asc"
			echo "Aborted, download verification failed"
			return 8
		fi
	else
		echo "Notice: download verification not possible because gpg is not installed"
	fi

	echo "Extracting..."
	case "$caddy_file" in
		*.zip)    unzip -o "$dl" "$caddy_bin" -d "$PREFIX/tmp/" ;;
		*.tar.gz) tar -xzf "$dl" -C "$PREFIX/tmp/" "$caddy_bin" ;;
	esac
	chmod +x "$PREFIX/tmp/$caddy_bin"

	# Back up existing caddy, if any found in path
	if caddy_path="$(type -p "$caddy_bin")"; then
		caddy_backup="${caddy_path}_old"
		echo "Backing up $caddy_path to $caddy_backup"
		echo "(Password may be required.)"
		$sudo_cmd mv "$caddy_path" "$caddy_backup"
	fi

	echo "Putting caddy in $install_path (may require password)"
	$sudo_cmd mv "$PREFIX/tmp/$caddy_bin" "$install_path/$caddy_bin"
	if setcap_cmd=$(PATH+=$PATH:/sbin type -p setcap); then
		$sudo_cmd $setcap_cmd cap_net_bind_service=+ep "$install_path/$caddy_bin"
	fi
	$sudo_cmd rm -- "$dl"

	# check installation
	$caddy_bin -version

	echo "Successfully installed"
	trap ERR
	return 0
}

install_caddy "$@"