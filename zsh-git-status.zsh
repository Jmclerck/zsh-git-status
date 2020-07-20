function git_status_callback() {
  NEXT_GIT_STATUS=$3

  zle reset-prompt 
}

function git_status_main() {
  local icons=()
  local git=$(git -C $1 rev-parse --is-inside-work-tree 2> /dev/null)

  if [[ $git == true ]]; then
    local branch=$(git -C $1 rev-parse --abbrev-ref HEAD)

    local stashes=$(git -C $1 stash list | rg -o '@' |  tr -d ' ' | tr -d '\n')
    local numberOfStashes=${#stashes}
    if [[ $numberOfStashes -gt 0 ]]; then
        icons+=("%{$fg[magenta]%} $numberOfStashes")
    fi

    local untracked=$(git -C $1 status --porcelain | rg -o '^\?\?\s' |  tr -d ' ' | tr -d '\n')
    local numberOfUntracked=${#untracked}
    if [[ $numberOfUntracked -gt 0 ]]; then
        icons+=("%{$fg[yellow]%} $(($numberOfUntracked / 2))")
    fi

    local added=$(git -C $1 status --porcelain | rg -o '^\sA\s|^A\s{2}' |  tr -d ' ' | tr -d '\n')
    local numberOfAdded=${#added}
    if [[ $numberOfAdded -gt 0 ]]; then
        icons+=("%{$fg[green]%} $numberOfAdded")
    fi

    local deleted=$(git -C $1 status --porcelain | rg -o '^\sD\s|^D\s{2}' |  tr -d ' ' | tr -d '\n')
    local numberOfDeleted=${#deleted}
    if [[ $numberOfDeleted -gt 0 ]]; then
        icons+=("%{$fg[red]%} $numberOfDeleted")
    fi

    local modified=$(git -C $1 status --porcelain | rg -o '^\sM\s|^M\s{2}' |  tr -d ' ' | tr -d '\n')
    local numberOfModified=${#modified}
    if [[ $numberOfModified -gt 0 ]]; then
        icons+=("%{$fg[yellow]%} $numberOfModified")
    fi

    local renamed=$(git -C $1 status --porcelain | rg -o '^\sR\s|^R\s{2}' |  tr -d ' ' | tr -d '\n')
    local numberOfRenamed=${#renamed}
    if [[ $numberOfRenamed -gt 0 ]]; then
        icons+=("%{$fg[green]%} $numberOfRenamed")
    fi

    local conflicts=$(git -C $1 status --porcelain | rg -o '^UU\s' |  tr -d ' ' | tr -d '\n')
    local numberOfConflicts=${#conflicts}
    if [[ $numberOfConflicts -gt 0 ]]; then
        icons+=("%{$fg[red]%} $(($numberOfConflicts / 2))")
    fi

    local staged=$(git -C $1 status --porcelain |  rg -o '^A\s{2}|^D\s{2}|^M\s{2}|^R\s{2}' | tr -d ' ' | tr -d '\n')
    local numberOfStaged=${#staged}
    if [[ $numberOfStaged -gt 0 ]]; then
        icons+=("%{$fg[green]%} $(($numberOfStaged))")
    fi

    local remote=$(git -C $1 show-ref origin/$branch 2> /dev/null)
    if [[ -z $remote ]]; then
        icons+=("%{$fg[white]%}")
    else
        local ahead=$(git -C $1 rev-list origin/$branch..HEAD 2>/dev/null | wc -l | tr -d ' ')
        if [[ $ahead -gt 0 ]]; then
            icons+=("%{$fg[yellow]%} $ahead")
        fi

        local behind=$(git -C $1 rev-list HEAD..origin/$branch 2>/dev/null | wc -l | tr -d ' ')
        
        if [[ $behind -gt 0 ]]; then	
            icons+=("%{$fg[green]%} $behind")
        fi
    fi

    print "%{$fg[blue]%}%{$fg[magenta]%}$icons $branch~@%{$reset_color%}"
  else
    print "%{$fg[magenta]%} %{$reset_color%}"
  fi
}

function git_status() {
  async_init
  async_start_worker git_status_worker -n
  async_register_callback git_status_worker git_status_callback
  async_job git_status_worker git_status_main $1
}
