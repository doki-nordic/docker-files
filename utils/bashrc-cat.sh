
_prompr_get_message () {
	_path=. && [ -f $_path/zephyr/zephyr-env.sh ] || \
	_path=.. && [ -f $_path/zephyr/zephyr-env.sh ] || \
	_path=../.. && [ -f $_path/zephyr/zephyr-env.sh ] || \
	_path=../../.. && [ -f $_path/zephyr/zephyr-env.sh ] || \
	_path=../../../.. && [ -f $_path/zephyr/zephyr-env.sh ] || \
	_path=../../../../.. && [ -f $_path/zephyr/zephyr-env.sh ] || \
	_path=../../../../../.. && [ -f $_path/zephyr/zephyr-env.sh ] || \
	_path=../../../../../../.. && [ -f $_path/zephyr/zephyr-env.sh ] || \
	_path=../../../../../../../.. && [ -f $_path/zephyr/zephyr-env.sh ] || \
	_path=../../../../../../../../.. && [ -f $_path/zephyr/zephyr-env.sh ] || \
	_path=../../../../../../../../../.. && [ -f $_path/zephyr/zephyr-env.sh ] || \
	_path=../../../../../../../../../../.. && [ -f $_path/zephyr/zephyr-env.sh ] || \
	_path=
	if [[ "$1" != "0" ]]; then
		echo -e "\e[1;41m\e[1;33m[$1]\e[0m"
	fi
	echo -ne "\e[38;5;243mDocker: "
	if [[ "$_path" != "" ]]; then
		#echo $(basename $(realpath "$_path")) - $(basename $PWD)
		echo -ne "\033]0;$(basename $(realpath "$_path")) - $(basename "$PWD")\007"
		echo -e "$(realpath "$_path/..")/\e[1;32m$(basename $(realpath "$_path"))\e[1;34m/$(realpath -s --relative-to="$_path" "$PWD")\e[0m"
	else
		echo -ne "\033]0;$(basename $PWD)\007"
		echo -e "\e[0m$PWD"
	fi
}

PROMPT_COMMAND='_prompr_get_message $?'
PS1='$ '
