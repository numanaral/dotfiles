# Powerlevel10k basic configuration.
# Run 'p10k configure' for full interactive setup.
'builtin' 'local' '-a' 'p10k_config_opts'
[[ ! -o 'aliases' ]] || p10k_config_opts+=('aliases')
'builtin' 'setopt' 'no_aliases'
[[ ! -o 'sh_glob' ]] || p10k_config_opts+=('sh_glob')
'builtin' 'setopt' 'no_sh_glob'
[[ ! -o 'no_brace_expand' ]] || p10k_config_opts+=('no_brace_expand')
'builtin' 'setopt' 'brace_expand'

() {
  emulate -L zsh
  setopt local_options
  unsetopt case_glob
  typeset -g POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(context dir vcs)
  typeset -g POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=(status command_execution_time background_jobs time)
  typeset -g POWERLEVEL9K_PROMPT_ADD_NEWLINE=true
}

(( ${#p10k_config_opts} )) && setopt ${p10k_config_opts[@]}
'builtin' 'unset' 'p10k_config_opts'
