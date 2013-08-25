# Maven Version Manager

this is a hack on the brilliant [nvm](https://github.com/creationix/nvm/) to work with [Maven](http://maven.apache.org/) instead.

## Installation

First you'll need to make sure your system has a c++ compiler.  For OSX, XCode will work, for Ubuntu, the build-essential and libssl-dev packages work.

### Install script

To install you could use the [install script](https://github.com/ingenieux/mvm/blob/master/install.sh) (requires Git) using cURL:

    curl https://raw.github.com/ingenieux/mvm/master/install.sh | sh

or Wget:

    wget -qO- https://raw.github.com/ingenieux/mvm/master/install.sh | sh

<sub>The script clones the mvm repository to `~/.mvm` and adds the source line to your profile (`~/.bash_profile` or `~/.profile`).</sub>


### Manual install

For manual install create a folder somewhere in your filesystem with the `mvm.sh` file inside it.  I put mine in a folder called `mvm`.

Or if you have `git` installed, then just clone it:

    git clone https://github.com/ingenieux/mvm.git ~/.mvm

To activate mvm, you need to source it from your bash shell

    source ~/.mvm/mvm.sh

I always add this line to my `~/.bashrc` or `~/.profile` file to have it automatically sourced upon login.
Often I also put in a line to use a specific version of node.

## Usage

To download, compile, and install the version 3.1.0, do this:

    mvm install 3.1.0

And then in any new shell just use the installed version:

    mvm use 0.10

You can create an `.mmvrc` file containing version number in the project root folder; run the following command to switch versions:

    mvm use

Or you can just run it:

    mvm run 3.1.0

If you want to see what versions are installed:

    mvm ls

If you want to see what versions are available to install:

    mvm ls-remote

To restore your PATH, you can deactivate it.

    mvm deactivate

To set a default Node version to be used in any new shell, use the alias 'default':

    mvm alias default 3.1.0

## License

mvm is released under the MIT license.


Copyright (C) 2010-2013 Tim Caswell

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

## Running tests
Tests are written in [Urchin](http://www.urchin.sh). Install Urchin like so.

    wget -O /usr/local/bin https://raw.github.com/scraperwiki/urchin/0c6837cfbdd0963903bf0463b05160c2aecc22ef/urchin
    chmod +x /usr/local/bin/urchin

(Or put it some other place in your PATH.)

There are slow tests and fast tests. The slow tests do things like install node
and check that the right versions are used. The fast tests fake this to test
things like aliases and uninstalling. From the root of the mvm git repository,
run the fast tests like this.

    urchin test/fast

Run the slow tests like this.

    urchin test/slow

Run all of the tests like this

    urchin test

Nota bene: Avoid running mvm while the tests are running.

## Bash completion

To activate, you need to source `bash_completion`:

  	[[ -r $MVM_DIR/bash_completion ]] && . $MVM_DIR/bash_completion

Put the above sourcing line just below the sourcing line for NVM in your profile (`.bashrc`, `.bash_profile`).

### Usage

mvm

	$ mvm [tab][tab]
	alias          copy-packages  help           list           run            uninstall      version
	clear-cache    deactivate     install        ls             unalias        use

mvm alias

	$ mvm alias [tab][tab]
	default

	$ mvm alias my_alias [tab][tab]
	v0.4.11        v0.4.12       v0.6.14

mvm use

	$ mvm use [tab][tab]
	my_alias        default        v0.4.11        v0.4.12       v0.6.14

mvm uninstall

	$ mvm uninstall [tab][tab]
	my_alias        default        v0.4.11        v0.4.12       v0.6.14

## Problems

If you try to install a node version and the installation fails, be sure to delete the node downloads from src (~/.mvm/src/) or you might get an error when trying to reinstall them again or you might get an error like the following:

    curl: (33) HTTP server doesn't seem to support byte ranges. Cannot resume.


