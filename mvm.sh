#!/bin/sh +x

# Maven Version Manager
# Implemented as a bash function
# To use source this file from your bash profile
#
# Implemented by Tim Caswell <tim@creationix.com>
# with much bash help from Matthew Ranney

# Auto detect the MVM_DIR
if [ ! -d "$MVM_DIR" ]; then
    export MVM_DIR=$(cd $(dirname ${BASH_SOURCE[0]:-$0}) > /dev/null && pwd)
fi

# Make zsh glob matching behave same as bash
# This fixes the "zsh: no matches found" errors
if [ ! -z "$(which unsetopt 2>/dev/null)" ]; then
    unsetopt nomatch 2>/dev/null
fi

mvm_set_nullglob() {
  if type setopt > /dev/null 2>&1; then
      # Zsh
      setopt NULL_GLOB
  else
      # Bash
      shopt -s nullglob
  fi
}

# Obtain mvm version from rc file
rc_mvm_version() {
  if [ -e .mvmrc ]; then
        RC_VERSION=`cat .mvmrc | head -n 1`
    echo "Found .mvmrc files with version <$RC_VERSION>"
  fi
}

# Expand a version using the version cache
mvm_version() {
    local PATTERN=$1
    # The default version is the current one
    if [ ! "$PATTERN" ]; then
        PATTERN='current'
    fi

    VERSION=`mvm_ls $PATTERN | tail -n1`
    echo "$VERSION"

    if [ "$VERSION" = 'N/A' ]; then
        return
    fi
}

mvm_remote_version() {
    local PATTERN=$1
    VERSION=`mvm_ls_remote $PATTERN | tail -n1`
    echo "$VERSION"

    if [ "$VERSION" = 'N/A' ]; then
        return
    fi
}

mvm_ls() {
    local PATTERN=$1
    local VERSIONS=''
    if [ "$PATTERN" = 'current' ]; then
        echo `node -v 2>/dev/null`
        return
    fi

    if [ -f "$MVM_DIR/alias/$PATTERN" ]; then
        mvm_version `cat $MVM_DIR/alias/$PATTERN`
        return
    fi
    # If it looks like an explicit version, don't do anything funny
    if [[ "$PATTERN" == 3.?* ]]; then
        VERSIONS="$PATTERN"
    else
        VERSIONS=`find "$MVM_DIR/" -maxdepth 1 -type d -name "$PATTERN*" -exec basename '{}' ';' \
                    | sort -t. -u -k 1.2,1n -k 2,2n -k 3,3n`
    fi
    if [ ! "$VERSIONS" ]; then
        echo "N/A"
        return
    fi
    echo "$VERSIONS"
    return
}

mvm_ls_remote() {
    local PATTERN=$1
    local VERSIONS
    if [ "$PATTERN" ]; then
        if echo "${PATTERN}" | \grep -v '^v' ; then
            PATTERN=v$PATTERN
        fi
    else
        PATTERN=".*"
    fi
    VERSIONS=`curl -s https://dist.apache.org/repos/dist/release/maven/maven-3/ \
                  | \egrep -o '3.[0-9]+\.[0-9]+' \
                  | \grep -w "${PATTERN}" \
                  | sort -t. -u -k 1.2,1n -k 2,2n -k 3,3n`
    if [ ! "$VERSIONS" ]; then
        echo "N/A"
        return
    fi
    echo "$VERSIONS"
    return
}

mvm_checksum() {
    if [ "$1" = "$2" ]; then
        return
    elif [ -z $2 ]; then
        echo 'Checksums empty' #missing in raspberry pi binary
        return
    else
        echo 'Checksums do not match.'
        return 1
    fi
}


print_versions() {
    local OUTPUT=''
    local PADDED_VERSION=''
    for VERSION in $1; do
        PADDED_VERSION=`printf '%10s' $VERSION`
        if [[ -d "$MVM_DIR/$VERSION" ]]; then
             PADDED_VERSION="\033[0;34m$PADDED_VERSION\033[0m"
        fi
        OUTPUT="$OUTPUT\n$PADDED_VERSION"
    done
    echo -e "$OUTPUT"
}

mvm() {
  if [ $# -lt 1 ]; then
    mvm help
    return
  fi

  # Try to figure out the os and arch for binary fetching
  local uname="$(uname -a)"
  local os=
  local arch="$(uname -m)"
  case "$uname" in
    Linux\ *) os=linux ;;
    Darwin\ *) os=darwin ;;
    SunOS\ *) os=sunos ;;
    FreeBSD\ *) os=freebsd ;;
  esac
  case "$uname" in
    *x86_64*) arch=x64 ;;
    *i*86*) arch=x86 ;;
    *armv6l*) arch=arm-pi ;;
  esac

  # initialize local variables
  local VERSION
  local ADDITIONAL_PARAMETERS

  case $1 in
    "help" )
      echo
      echo "Node Version Manager"
      echo
      echo "Usage:"
      echo "    mvm help                    Show this message"
      echo "    mvm install [-s] <version>  Download and install a <version>"
      echo "    mvm uninstall <version>     Uninstall a version"
      echo "    mvm use <version>           Modify PATH to use <version>"
      echo "    mvm run <version> [<args>]  Run <version> with <args> as arguments"
      echo "    mvm ls                      List installed versions"
      echo "    mvm ls <version>            List versions matching a given description"
      echo "    mvm ls-remote               List remote versions available for install"
      echo "    mvm deactivate              Undo effects of MVM on current shell"
      echo "    mvm alias [<pattern>]       Show all aliases beginning with <pattern>"
      echo "    mvm alias <name> <version>  Set an alias named <name> pointing to <version>"
      echo "    mvm unalias <name>          Deletes the alias named <name>"
      echo "    mvm copy-packages <version> Install global NPM packages contained in <version> to current version"
      echo
      echo "Example:"
      echo "    mvm install v0.4.12         Install a specific version number"
      echo "    mvm use 0.2                 Use the latest available 0.2.x release"
      echo "    mvm run 0.4.12 myApp.js     Run myApp.js using node v0.4.12"
      echo "    mvm alias default 0.4       Auto use the latest installed v0.4.x version"
      echo
    ;;

    "install" )
      # initialize local variables
      local binavail
      local t
      local url
      local sum
      local tarball
      local shasum='shasum'
      local nobinary

      if [ ! `\which curl` ]; then
        echo 'MVM Needs curl to proceed.' >&2;
      fi

      if [ -z "`which shasum`" ]; then
        shasum='sha1sum'
      fi

      if [ $# -lt 2 ]; then
        mvm help
        return
      fi

      shift

      nobinary=0
      if [ "$1" = "-s" ]; then
        nobinary=1
        shift
      fi

      if [ "$os" = "freebsd" ]; then
	nobinary=1
      fi

      VERSION=$1
      ADDITIONAL_PARAMETERS=''

      shift

      while [ $# -ne 0 ]
      do
        ADDITIONAL_PARAMETERS="$ADDITIONAL_PARAMETERS $1"
        shift
      done

      [ -d "$MVM_DIR/$VERSION" ] && echo "$VERSION is already installed." && return

      url="https://dist.apache.org/repos/dist/release/maven/maven-3/$VERSION/binaries/apache-maven-$VERSION-bin.tar.gz"
      sum=`curl -s $url.sha1`
      echo "url: $url sum: $sum"
      local tmpdir="$MVM_DIR/bin/maven-$VERSION"
      local tmptarball="$tmpdir/apache-maven-$VERSION.tar.gz"
      if (mkdir -p "$tmpdir" && \
          curl -L -C - --progress-bar $url -o "$tmptarball" && \
          mvm_checksum `${shasum} "$tmptarball" | awk '{print $1}'` $sum && \
          tar -xzf "$tmptarball" -C "$tmpdir" --strip-components 1 && \
          mv "$tmpdir" "$MVM_DIR/$VERSION" && \
          rm -f "$tmptarball"
          ) then
         mvm use $VERSION
         return;
      else
         echo "Binary download failed, trying source." >&2
         rm -rf "$tmptarball" "$tmpdir"
      fi

    ;;
    "uninstall" )
      [ $# -ne 2 ] && mvm help && return
      if [[ $2 == `mvm_version` ]]; then
        echo "mvm: Cannot uninstall currently-active node version, $2."
        return 1
      fi
      VERSION=`mvm_version $2`
      if [ ! -d $MVM_DIR/$VERSION ]; then
        echo "$VERSION version is not installed yet... installing"
        mvm install $VERSION
        return;
      fi

      t="$VERSION-$os-$arch"

      # Delete all files related to target version.
      rm -rf "$MVM_DIR/src/node-$VERSION" \
             "$MVM_DIR/src/node-$VERSION.tar.gz" \
             "$MVM_DIR/bin/node-${t}" \
             "$MVM_DIR/bin/node-${t}.tar.gz" \
             "$MVM_DIR/$VERSION" 2>/dev/null
      echo "Uninstalled node $VERSION"

      # Rm any aliases that point to uninstalled version.
      for A in `\grep -l $VERSION $MVM_DIR/alias/* 2>/dev/null`
      do
        mvm unalias `basename $A`
      done

    ;;
    "deactivate" )
      if [[ $PATH == *$MVM_DIR/*/bin* ]]; then
        export PATH=${PATH%$MVM_DIR/*/bin*}${PATH#*$MVM_DIR/*/bin:}
        hash -r
        echo "$MVM_DIR/*/bin removed from \$PATH"
      else
        echo "Could not find $MVM_DIR/*/bin in \$PATH"
      fi
      if [[ $MANPATH == *$MVM_DIR/*/share/man* ]]; then
        export MANPATH=${MANPATH%$MVM_DIR/*/share/man*}${MANPATH#*$MVM_DIR/*/share/man:}
        echo "$MVM_DIR/*/share/man removed from \$MANPATH"
      else
        echo "Could not find $MVM_DIR/*/share/man in \$MANPATH"
      fi
    ;;
    "use" )
      if [ $# -eq 0 ]; then
        mvm help
        return
      fi
      if [ $# -eq 1 ]; then
        rc_mvm_version
        if [ ! -z $RC_VERSION ]; then
            VERSION=`mvm_version $RC_VERSION`
        fi
      else
        VERSION=`mvm_version $2`
      fi
      if [ -z $VERSION ]; then
        mvm help
        return
      fi
      if [ -z $VERSION ]; then
        VERSION=`mvm_version $2`
      fi
      if [ ! -d $MVM_DIR/$VERSION ]; then
        echo "$VERSION version is not installed yet"
        return 1
      fi
      if [[ $PATH == *$MVM_DIR/*/bin* ]]; then
        PATH=${PATH%$MVM_DIR/*/bin*}$MVM_DIR/$VERSION/bin${PATH#*$MVM_DIR/*/bin}
      else
        PATH="$MVM_DIR/$VERSION/bin:$PATH"
      fi
      export PATH
      hash -r
      export M2_HOME="$MVM_DIR/$VERSION"
      export MVM_PATH="$MVM_DIR/$VERSION/bin/mvn"
      export MVM_BIN="$MVM_DIR/$VERSION/bin"
      echo "Now using maven $VERSION"
    ;;
    "run" )
      # run given version of maven
      if [ $# -lt 2 ]; then
        mvm help
        return
      fi
      VERSION=`mvm_version $2`
      if [ ! -d $MVM_DIR/$VERSION ]; then
        echo "$VERSION version is not installed yet"
        return;
      fi
      echo "Running node $VERSION"
      $MVM_DIR/$VERSION/bin/maven "${@:3}"
    ;;
    "ls" | "list" )
      print_versions "`mvm_ls $2`"
      if [ $# -eq 1 ]; then
        echo -ne "current: \t"; mvm_version current
        mvm alias
      fi
      return
    ;;
    "ls-remote" | "list-remote" )
        print_versions "`mvm_ls_remote $2`"
        return
    ;;
    "alias" )
      mkdir -p $MVM_DIR/alias
      if [ $# -le 2 ]; then
        for ALIAS in $(mvm_set_nullglob; echo $MVM_DIR/alias/$2* ); do
            DEST=`cat $ALIAS`
            VERSION=`mvm_version $DEST`
            if [ "$DEST" = "$VERSION" ]; then
                echo "$(basename $ALIAS) -> $DEST"
            else
                echo "$(basename $ALIAS) -> $DEST (-> $VERSION)"
            fi
        done
        return
      fi
      if [ ! "$3" ]; then
          rm -f $MVM_DIR/alias/$2
          echo "$2 -> *poof*"
          return
      fi
      mkdir -p $MVM_DIR/alias
      VERSION=`mvm_version $3`
      if [ $? -ne 0 ]; then
        echo "! WARNING: Version '$3' does not exist." >&2
      fi
      echo $3 > "$MVM_DIR/alias/$2"
      if [ ! "$3" = "$VERSION" ]; then
          echo "$2 -> $3 (-> $VERSION)"
      else
        echo "$2 -> $3"
      fi
    ;;
    "unalias" )
      mkdir -p $MVM_DIR/alias
      [ $# -ne 2 ] && mvm help && return
      [ ! -f $MVM_DIR/alias/$2 ] && echo "Alias $2 doesn't exist!" && return
      rm -f $MVM_DIR/alias/$2
      echo "Deleted alias $2"
    ;;
    "copy-packages" )
        if [ $# -ne 2 ]; then
          mvm help
          return
        fi
        VERSION=`mvm_version $2`
        ROOT=`mvm use $VERSION && npm -g root`
        INSTALLS=`mvm use $VERSION > /dev/null && npm -g -p ll | \grep "$ROOT\/[^/]\+$" | cut -d '/' -f 8 | cut -d ":" -f 2 | \grep -v npm | tr "\n" " "`
        npm install -g $INSTALLS
    ;;
    "clear-cache" )
        rm -f $MVM_DIR/v* 2>/dev/null
        echo "Cache cleared."
    ;;
    "version" )
        print_versions "`mvm_version $2`"
    ;;
    * )
      mvm help
    ;;
  esac
}

mvm ls default &>/dev/null && mvm use default >/dev/null || true
