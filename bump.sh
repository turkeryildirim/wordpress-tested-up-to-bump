#!/bin/bash

# turn some bugs into errors
set -o errexit -o noclobber -o nounset -o pipefail

# main setup
CURRENTDIR=`pwd`
PLUGINSLUG="" # plugin nice name
READMEFILE="" # name of your readme file in the wordpress plugin
GITPATH="" # local base of git repository
SVNPATH="" # path to a temp SVN repo
SVNURL="" # remote SVN repo on wordpress.org
SVNUSER="" # your svn username

# parse arguments
while [ "$#" -gt 0 ]; do
  case "$1" in
    -h) 
        echo "Sample usage:"
        echo "--slug=my-slug --readme=readme.txt --gitpath=/home/local/my-plugin --svnpath=my-slug --svnuser=username"
        exit 1;;
    --slug=*) PLUGINSLUG="${1#*=}"; shift 1;;
    --readme=*) READMEFILE="${1#*=}"; shift 1;;
    --gitpath=*) GITPATH="${1#*=}"; shift 1;;
    --svnpath=*) SVNPATH="${1#*=}"; shift 1;;
    --svnurl=*) SVNURL="${1#*=}"; shift 1;;
    --svnuser=*) SVNUSER="${1#*=}"; shift 1;;
    --slug|--readme|--gitpath|--svnpath|--svnurl|--svnuser) echo "$1 requires an argument" >&2; exit 1;;

    -*) echo "Unknown option: $1" >&2; exit 1;;
    *) echo "Unrecognized argument: $1" >&2; exit 1;;
  esac
done

# check required arguments
if [ -z "$PLUGINSLUG" ]; then
    echo "Plugin slug required. Aborting."
    exit;
fi
if [ -z "$SVNUSER" ]; then
    echo "Plugin slug required. Aborting."
    exit;
fi

# verify  arguments
if [ -z "$READMEFILE" ]; then
    READMEFILE="$CURRENTDIR/readme.txt";
fi
if [ -z "$GITPATH" ]; then
    GITPATH="$CURRENTDIR/";
fi
if [ -z "$SVNPATH" ]; then
    SVNPATH="/tmp/$PLUGINSLUG";
fi
if [ -z "$SVNURL" ]; then
    SVNURL="http://plugins.svn.wordpress.org/$PLUGINSLUG/";
fi


# Show time...
echo "... Preparing to bump wordpress plugin tested version ..."

# Check local git directory
if [ ! -d "$GITPATH" ]; then
  echo "Directory $GITPATH not found. Aborting."
  exit 1;
fi

# get "stable tag"
STABLETAG=`grep "^Stable tag:" $GITPATH/readme.txt | awk -F' ' '{print $NF}'`
if [ -z "$STABLETAG" ]; then
    echo "Could not read stable tag in readme.txt";
fi
echo "readme.txt stable tag: $STABLETAG"

# get "tested up to" version from readme file
TESTEDVERSION=`grep "^Tested up to:" $GITPATH/readme.txt | awk -F' ' '{print $NF}'`
if [ -z "$TESTEDVERSION" ]; then
    echo "Could not read tested up to tag in readme.txt";
fi;
echo "readme.txt tested up to tag: $TESTEDVERSION"

echo "Creating local copy of SVN repo ..."
# Remove svn directory if exists
if [ -d "$SVNPATH" ]; then
    rm -rf "$SVNPATH/";
fi

# crete local svn directory
svn co $SVNURL $SVNPATH

# add git files and this file to ignore list
svn propset svn:ignore "deploy.sh
README.md
Thumbs.db
.github/*
.git
.gitattributes
.gitignore" "$SVNPATH/trunk/"

echo "Updating version ..."
cp -rf $GITPATH/readme.txt $SVNPATH/trunk/readme.txt
cp -rf $GITPATH/readme.txt $SVNPATH/tags/$STABLETAG/readme.txt
cd "$SVNPATH/"
svn ci -m "Tested up to bumped to $TESTEDVERSION in tagged release $STABLETAG"

echo "Removing temporary directory: $SVNPATH"
rm -rf "$SVNPATH/"

echo "All done"
