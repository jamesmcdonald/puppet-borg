#!/bin/bash

export BORG_PASSPHRASE="$(</etc/borg/passphrase)"
BORG_REPO="borg:$(hostname -f)"

function usage() {
  echo "usage: $0 [-i] [-a archive] [path [path ...]]"
  echo "   or: $0 -l [archive [path [path ...]]]"
  echo "   or: $0 -h"
  echo
  echo "Restore files from Borg backup. The first form restores files, and the second"
  echo "allows you to list archives and files in the repository."
  echo
  echo "  -l            List available backups archives. You can pass the name of an"
  echo "                archive to list its contents and optionally provide specific"
  echo "                paths to list."
  echo "  -i            Restore files in-place. By default the full path will be"
  echo "                restored into the current directory. With this option files"
  echo "                are restored under / and will overwrite existing files."
  echo "  -a archive    Restore from a specific backup archive. By default the paths"
  echo "                to restore are searched for in each archive starting with the"
  echo "                most recent."
  echo "  -h            Display this help and exit."
  exit 0
}

function list() {
  archive=$1
  shift
  [ ! -z "$archive" ] && archive=::$archive
  borg list $BORG_REPO$archive "$@"
  return $?
}

inplace=0
listmode=0
archives=""

while getopts 'hlia:' opt
do
  case $opt in
    a)
      archives=$OPTARG
      ;;
    l)
      listmode=1
      ;;
    i)
      inplace=1
      echo "Restoring files in-place; existing files will be overwritten"
      ;;
    h|*)
      usage
      ;;
  esac
done
shift $((OPTIND - 1))

if [[ $listmode == 1 ]]; then
  list "$@"
  exit $?
fi

if [[ $# -eq 0 ]]; then
  echo "Nothing to do: \"$0 -h\" for usage information"
  exit 0
fi

if [[ -z "$archives" ]]; then
  echo "Finding backup archives..."
  archives="$(list | awk '{print $1}' | sort -r)"
  if [[ -z "$archives" ]]; then
    echo "No archives found, aborting"
    exit 1
  fi
  echo "Found archives:"
  echo $archives | sed -e 's/ /\n/g' | sed -e 's/^/ - /'
fi

for filepath in "$@"; do
  if echo $filepath | grep -q '^/'; then
    filepath="$(echo $filepath | sed -e 's/^.\(.*\)$/\1/')"
  else
    filepath="$(echo $(pwd)/$filepath | sed -e 's/^.\(.*\)$/\1/')"
  fi
  for archive in $archives; do
    echo "Checking in $archive..."
    if [ -z "$(borg list $BORG_REPO::$archive "$filepath")" ]; then
      echo " $filepath not found, moving on"
      continue
    fi
    echo " $filepath found, restoring..."
    [[ $inplace = "1" ]] && OLDPWD="$(pwd)" && cd /
    borg extract -vp $BORG_REPO::$archive "$filepath"
    [[ $inplace = "1" ]] && cd "$OLDPWD"
    break
  done
done
