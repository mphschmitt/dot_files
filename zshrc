# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:/usr/local/bin:$PATH

# Path to your oh-my-zsh installation.
# export ZSH="/home/ancap/.oh-my-zsh"
export ZSH="$HOME/.oh-my-zsh"

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time oh-my-zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/robbyrussell/oh-my-zsh/wiki/Themes
ZSH_THEME="robbyrussell"

# Set list of themes to pick from when loading at random
# Setting this variable when ZSH_THEME=random will cause zsh to load
# a theme from this variable instead of looking in ~/.oh-my-zsh/themes/
# If set to an empty array, this variable will have no effect.
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment the following line to disable bi-weekly auto-update checks.
# DISABLE_AUTO_UPDATE="true"

# Uncomment the following line to change how often to auto-update (in days).
# export UPDATE_ZSH_DAYS=13

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load?
# Standard plugins can be found in ~/.oh-my-zsh/plugins/*
# Custom plugins may be added to ~/.oh-my-zsh/custom/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(git)

source $ZSH/oh-my-zsh.sh

# User configuration

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='mvim'
# fi

# Compilation flags
# export ARCHFLAGS="-arch x86_64"

# ssh
# export SSH_KEY_PATH="~/.ssh/rsa_id"

# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes. Aliases can be placed here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"
#
#
if [ "$TMUX" = "" ]; then tmux; fi

alias vim="gvim -v"
alias clean_recent="echo \"\" > ~/.local/share/recently-used.xbel"
alias py="/usr/bin/python3"

export LANG=en

PATH="$HOME/.local/bin:$HOME/bin:$PATH"

# ======= ClamAV: invite hebdomadaire au démarrage d'un terminal =======
# Ne rien faire pour les shells non interactifs
[[ $- != *i* ]] && return

# Paramètres (modifiables)
: "${CLAM_PROMPT_PERIOD_DAYS:=7}"                              # Fréquence d'invite en jours
: "${CLAM_SCAN_TARGETS:=$HOME}"                                 # Cibles de scan (séparées par des espaces)
: "${XDG_STATE_HOME:=$HOME/.local/state}"
: "${XDG_DATA_HOME:=$HOME/.local/share}"

# Dossiers applicatifs
_CLAM_STATE_DIR="$XDG_STATE_HOME/clamav-weekly"
_CLAM_DATA_DIR="$XDG_DATA_HOME/clamav"
_CLAM_LOG_DIR="$_CLAM_DATA_DIR/logs"
_CLAM_QUAR_DIR="$_CLAM_DATA_DIR/quarantine"
_CLAM_STAMP_FILE="$_CLAM_STATE_DIR/last_prompt"

# Création des dossiers si besoin
mkdir -p "$_CLAM_STATE_DIR" "$_CLAM_LOG_DIR" "$_CLAM_QUAR_DIR"

# Commande de scan (clamscan par défaut; utilisez clamdscan si le démon est actif)
function _clam_scan_cmd()
{
	if command -v clamdscan >/dev/null 2>&1 && systemctl is-active --quiet clamav-daemon 2>/dev/null; then
		echo "clamdscan"
		else
		echo "clamscan"
	fi
}

# Fonction d’invite hebdomadaire
function _clam_weekly_prompt ()
{
	# Respect d’un opt-out explicite
	[[ -n "$CLAM_DISABLE_WEEKLY_PROMPT" ]] && return

	local now last=0 period_secs log_file scan_cmd
	now=$(date +%s)
	[[ -f "$_CLAM_STAMP_FILE" ]] && read -r last <"$_CLAM_STAMP_FILE" || true
	period_secs=$(( CLAM_PROMPT_PERIOD_DAYS * 24 * 3600 ))

	# Si la dernière invite est récente, quitter
	(( now - last < period_secs )) && return

	# Demande à l'utilisateur
	printf "[ClamAV] Lancer un scan de %s ? [O/n] " "$CLAM_SCAN_TARGETS"
	read -r ans
	case "${(L)ans}" in n|no|non)  printf "%s" "$now" > "$_CLAM_STAMP_FILE"; return ;;
	esac

	scan_cmd=$(_clam_scan_cmd)
	log_file="$_CLAM_LOG_DIR/scan-$(date +%Y%m%d-%H%M%S).log"

	echo "[ClamAV] Début du scan avec $scan_cmd… Journal: $log_file"
	# Options raisonnables par défaut :
	# -r            : récursif
	# --move        : met en quarantaine les fichiers infectés
	# --log         : journal complet
	# --cross-fs=no : évite de traverser les montages (utile si $HOME contient des montages)
	# --infected    : affiche en sortie console uniquement les fichiers infectés
	if [ "$scan_cmd" = "clamscan" ]; then
		clamscan -r --cross-fs=no --infected --move="$_CLAM_QUAR_DIR" --log="$log_file" $CLAM_SCAN_TARGETS
	else
		clamdscan --multiscan --fdpass --move="$_CLAM_QUAR_DIR" --log="$log_file" $CLAM_SCAN_TARGETS
	fi

	# Marquer la date d’invite, succès ou non du scan
	printf "%s" "$now" > "$_CLAM_STAMP_FILE"

	# Récapitulatif minimal (extrait de fin de journal)
	echo "[ClamAV] Récapitulatif :"
	grep -E "Infected files:|Known viruses:|Scanned files:" "$log_file" || tail -n 20 "$log_file" || true
}

# Raccourci manuel pour lancer un scan à la demande : `clam-weekly-scan`
function clam-weekly-scan ()
{
	# Réinitialise la date de dernière invite pour forcer la question et exécuter le scan
	rm -f "$_CLAM_STAMP_FILE"
	_clam_weekly_prompt
}

# Lancer l’invite à l’ouverture d’un terminal
_clam_weekly_prompt
# ======= Fin ClamAV hebdomadaire =======
