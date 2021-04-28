alias gs='git status'
alias gd='git diff'
alias gds='git diff --staged'

alias gm='git submodule'
alias gmf='git submodule foreach'
alias gms='git submodule summary'
alias gmu='git submodule update'

# For each submodule print current local branch
gmb() {
       local gbc="git rev-parse --abbrev-ref HEAD"
       git submodule foreach \
		"if [ \$($gbc) != HEAD ]; \
                then echo \$($gbc); \
                else echo WARN: not on any branch; fi ||:"
}

# For each sobmodule, list new commits on current branch not pushed to remote
gmn() {
	local remote=$1; remote=${remote:=origin}
	local gbc="git rev-parse --abbrev-ref HEAD"
	git submodule foreach \
		"if [ \$($gbc) != HEAD ]; \
		 then if git rev-parse $remote/\$($gbc) 2>/dev/null 1>&2; \
			 then git log --oneline $remote/\$($gbc)..\$($gbc); \
			 else echo WARN: no branch \$($gbc) in remote $remote; fi \
		 else echo WARN: not on any branch; fi ||:"
}

# For each sobmodule, push the given branch if it exists
gmp() {
	local remote=$1; remote=${remote:=origin}
	local br="$2"
	git submodule foreach \
		"if git rev-parse $br 2>/dev/null 1>&2; \
		then echo git push $remote $br:$br && git push $remote $br:$br; \
		else echo WARN: no branch $br; fi ||:"
}

# For each submdule, checkout the given branch if current hash matches; useful
# for re-attaching child repos to a branch after 'git sumodule update'.
gmk() {
	local replace=0
	local OPTIND opt
	while getopts "r?" opt; do
	    case "${opt}" in
		r) replace=1 ;;
		*)
		    echo "ERROR: invalid argument: ${opt}" 1>&2
		    return 1
		    ;;
	    esac
	done
	shift $((OPTIND-1))
	local branch=$1; branch=${branch:=master}
	local locbranch=$(basename $branch)
	local remote=$(dirname $branch)
	local _RED='\033[0;31m'
	local _NOCOLOR='\033[0m'
	ERROR="${_RED}FAILED${_NOCOLOR}" git submodule foreach \
		"run() { echo \"\$@\"; \"\$@\"; }; \
		if [ \"\$(git rev-parse HEAD)\" = \"\$(git rev-parse $branch 2>/dev/null)\" ]; \
		then if git rev-parse $locbranch 2>/dev/null 1>&2; \
		     then run git checkout $locbranch; \
		     else if [ -n "$remote" ]; \
			  then run git checkout -b $locbranch $branch; \
			  else echo -e \"\$WARN: no branch $locbranch and no remote specified\" 1>&2; \
			  fi; \
		     fi; \
		else if [ "$replace" -eq 1 ]; \
		     then if git rev-parse $branch 2>/dev/null 1>&2; \
			  then run git branch -D $branch; \
			       run git checkout -b $branch HEAD; \
			  else echo -e \"\$ERROR: no branch $branch\" 1>&2; \
			  fi; \
		     else echo -e \"\$ERROR: not on branch $branch\" 1>&2; \
		     fi; \
		fi ||:"
}

function version_gt() {
    test "$(printf '%s\n' "$@" | sort -V | head -n 1)" != "$1";
}
git_remote_url() {
    if version_gt $(git --version | cut -d' ' -f3) 2.23
    then
        git remote get-url $1
    else
        git remote -v | grep ^$1 | head -1 | xargs echo | cut -d' ' -f2
    fi
}
