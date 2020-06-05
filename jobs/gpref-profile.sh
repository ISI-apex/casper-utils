#!/bin/bash

set -e

if [[ ! -e "${OVERLAY_PATH}" ]]
then
	echo "ERROR: OVERLAY_PATH var not pointing to ebuilds repo" 1>&2
	exit 1
fi
OVERLAY_PATH=$(realpath ${OVERLAY_PATH})

PPATH=$1
if [ -z "${PPATH}" ]
then
	echo "ERROR: prefix name not specified as argument" 1>&2
	exit 1
fi
PROFILE=${2:-casper-usc-hpcc-amd64}

ROOT=$(realpath ${PPATH})
REPO=casper

# profile that holds files that need to be copied to /etc
REPO_PATH=var/db/repos/${REPO}

# "Upstream" repo: https://github.com/acolinisi/casper-ebuilds
git clone "${OVERLAY_PATH}" "$ROOT"/${REPO_PATH}

mkdir -p "$ROOT"/etc/portage/repos.conf
cat <<EOF > "$ROOT"/etc/portage/repos.conf/casper.conf
[casper]
priority = 51
location = $ROOT/${REPO_PATH}
EOF

prun() {
	"$ROOT"/startprefix -c "$1"
}

# Remove python-2.7, gcc-9.2 and a few other unnecessary leftovers
prun "emerge --depclean"

prun "eselect profile set ${REPO}:${PROFILE}"

# Manual parts of selecting the profile:
#   Setup files that are not supported by profiles (but we do
#   store them in the profiles directory tree to keep stuff together)
cat "$ROOT"/${REPO_PATH}/profiles/casper/package.license.profile \
	>> "$ROOT"/etc/portage/package.license
cat "$ROOT"/${REPO_PATH}/profiles/usc-hpcc/package.provided.profile \
	>> "$ROOT"/etc/portage/package.provided
mkdir -p "$ROOT"/etc/portage/sets
(
	cd "$ROOT"/${REPO_PATH}/profiles/casper/sets
	for set in *
	do
		ln -sf ../../../${REPO_PATH}/profiles/casper/sets/$set \
 			"$ROOT"/etc/portage/sets/$set
	done
)

sets=()
if [[ -z "$BARE" ]]
then
	sets+=("@casper-libs")
fi

# Apply use flags, overrides from the newly added repo, install sets
prun "emerge -v --deep --complete-graph --update --newuse --newrepo @world ${sets[@]}"

prun "eselect python set python3.8"
