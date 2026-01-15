export ZSH="$HOME/.oh-my-zsh"
export BAT_THEME="Dracula"

eval "$(starship init zsh)"
ZSH_THEME=""

plugins=(
	git
	zsh-autosuggestions
)

source $ZSH/oh-my-zsh.sh

# Custom alias
alias debian=TERM='xterm-256color proot-distro login debian --user gouranga'
alias la='ls -A'
alias l='ls -CF'
alias ls='eza --color=always --long --git --no-filesize --icons=always --no-time --no-user --no-permissions'
alias code=code-oss
alias code-c='code --profile "C/C++ Dev"'
alias code-w='code --profile "Web Dev"'

# Overwrite mkdir
mkdir() {
	if [ $# -eq 0 ]; then
		command mkdir
		return
	fi

	command mkdir -p "$@" || return 1

	if [ $# -ne 1 ]; then
		return 0
	fi

	read "ans?Do you want to initialize a git repo in '$1'? (y/n): "
	if [[ "$ans" == "y" || "$ans" == "Y" ]]; then
		(
			cd "$1" || exit
			git init -q
			echo "# $1" >README.md
			git add .
			git commit -m "Initial commit" -q
			echo "✅ Initialized Git repo and created initial commit in $(pwd)/.git/"
		)
	else
		echo "📁 Created folder without git init."
	fi
}

# Overwrite rm -rf
rm() {
	if [ $# -eq 0 ]; then
		echo "Usage: rm <file or folder>"
		return 1
	fi

	local flags=()
	local targets=()

	for arg in "$@"; do
		if [[ "$arg" == -* ]]; then
			flags+=("$arg")
		else
			targets+=("$arg")
		fi
	done

	if [ ${#targets[@]} -eq 0 ]; then
		command rm "${flags[@]}"
		return
	fi

	echo "⚠️  You are about to delete the following items:"
	for item in "${targets[@]}"; do
		if [ -d "$item" ]; then
			echo "📁 Folder: $item"
		elif [ -f "$item" ]; then
			echo "📄 File:   $item"
		else
			echo "❓ Unknown: $item"
		fi
	done

	read "ans?Are you sure you want to delete these? (y/n): "
	if [[ "$ans" == "y" || "$ans" == "Y" ]]; then
		command rm "${flags[@]}" "${targets[@]}"
		echo "🗑️  Deleted successfully."
	else
		echo "❎  Cancelled."
	fi
}

# Universal extractor
extract() {
	if [ -f "$1" ]; then
		case "$1" in
		*.tar.bz2) tar xjf "$1" ;;
		*.tar.gz) tar xzf "$1" ;;
		*.bz2) bunzip2 "$1" ;;
		*.rar) unrar x "$1" ;;
		*.gz) gunzip "$1" ;;
		*.tar) tar xf "$1" ;;
		*.zip) unzip "$1" ;;
		*.7z) 7z x "$1" ;;
		*) echo "❌ '$1' cannot be extracted via extract()" ;;
		esac
	else
		echo "❌ '$1' is not a valid file!"
	fi
}

# Universal compressor
compress() {
	if [ -z "$1" ]; then
		echo "📦 Usage: compress <file_or_dir>"
		return 1
	fi

	local input=$1
	if [ ! -e "$input" ]; then
		echo "❌ '$input' does not exist!"
		return 1
	fi

	local -a options=(
		"tar.gz   → Good balance, common"
		"tar.bz2  → Better compression, slower"
		"tar.xz   → Best compression, slowest"
		"zip      → Cross-platform"
		"7z       → High compression"
		"gz       → Single file only"
		"bz2      → Single file only"
	)

	local selected=1
	local key key2 key3 i

	local COLOR_BG_SELECTED=$'\033[48;5;58m'
	local COLOR_FG_SELECTED=$'\033[38;5;255m'
	local COLOR_RESET=$'\033[0m'
	local COLOR_HEADER=$'\033[38;5;80m'
	local COLOR_NORMAL=$'\033[38;5;249m'

	tput civis
	trap 'tput cnorm' EXIT

	while true; do
		printf "\033[2J\033[H"
		echo -e "${COLOR_HEADER}🎯 Select compression format for '$input'${COLOR_RESET}"
		echo -e "${COLOR_HEADER}────────────────────────────────────────────${COLOR_RESET}"
		for ((i = 1; i <= ${#options[@]}; i++)); do
			if ((i == selected)); then
				echo -e "${COLOR_BG_SELECTED}${COLOR_FG_SELECTED}👉 ${options[i - 1]}${COLOR_RESET}"
			else
				echo -e "${COLOR_NORMAL}   ${options[i - 1]}${COLOR_RESET}"
			fi
		done

		read -k1 key
		if [[ $key == $'\x1b' ]]; then
			read -k1 key2
			read -k1 key3
			key="$key$key2$key3"
		fi

		case "$key" in
		$'\x1b[A')
			((selected--))
			((selected < 1)) && selected=${#options[@]}
			;;
		$'\x1b[B')
			((selected++))
			((selected > ${#options[@]})) && selected=1
			;;
		$'\n' | $'\r') break ;;
		'') break ;;
		esac
	done

	tput cnorm
	trap - EXIT

	local format="${options[selected - 1]%% *}"
	local output="${input%/}.${format}"

	echo
	echo "📦 Compressing '$input' → '$output' ..."

	case "$format" in
	tar.gz) tar czf "$output" "$input" ;;
	tar.bz2) tar cjf "$output" "$input" ;;
	tar.xz) tar cJf "$output" "$input" ;;
	zip) zip -r "$output" "$input" ;;
	7z) 7z a "$output" "$input" ;;
	gz)
		if [ -f "$input" ]; then
			gzip -c "$input" >"$output"
		else
			echo "❌ .gz only supports single files!"
			return 1
		fi
		;;
	bz2)
		if [ -f "$input" ]; then
			bzip2 -c "$input" >"$output"
		else
			echo "❌ .bz2 only supports single files!"
			return 1
		fi
		;;
	esac

	echo "✅ Done! Created: $output"
}

# Start python server
serve() {
	port=${1:-8000}
	python3 -m http.server "$port"
}

