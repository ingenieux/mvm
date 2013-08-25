#!/bin/bash

function fatalExit (){
    echo "$@" && exit 1;
}

if [ "$MVM_SOURCE" == "" ]; then
    MVM_SOURCE="https://raw.github.com/ingenieux/mvm/master/mvm.sh"
fi

if [ "$MVM_DIR" == "" ]; then
    MVM_DIR="$HOME/.mvm"
fi

# Downloading to $MVM_DIR
mkdir -p "$MVM_DIR"
pushd "$MVM_DIR" > /dev/null
echo -ne "=> Downloading... "
curl --silent "$MVM_SOURCE" -o mvm.sh || fatalExit "Failed";
echo "Downloaded"
popd > /dev/null

# Detect profile file, .bash_profile has precedence over .profile
if [ ! -z "$1" ]; then
  PROFILE="$1"
else
  if [ -f "$HOME/.bash_profile" ]; then
	PROFILE="$HOME/.bash_profile"
  elif [ -f "$HOME/.profile" ]; then
	PROFILE="$HOME/.profile"
  fi
fi

SOURCE_STR="[[ -s "$MVM_DIR/mvm.sh" ]] && . "$MVM_DIR/mvm.sh"  # This loads MVM"

if [ -z "$PROFILE" ] || [ ! -f "$PROFILE" ] ; then
  if [ -z $PROFILE ]; then
	echo "=> Profile not found"
  else
	echo "=> Profile $PROFILE not found"
  fi
  echo "=> Append the following line to the correct file yourself"
  echo
  echo "\t$SOURCE_STR"
  echo
  echo "=> Close and reopen your terminal to start using MVM"
  exit
fi

if ! grep -qc 'mvm.sh' $PROFILE; then
  echo "=> Appending source string to $PROFILE"
  echo "" >> "$PROFILE"
  echo $SOURCE_STR >> "$PROFILE"
else
  echo "=> Source string already in $PROFILE"
fi

echo "=> Close and reopen your terminal to start using MVM"
