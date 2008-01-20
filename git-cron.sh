#!/bin/sh -e


BASE="$(cd $(dirname $0); pwd)"
export BASE

# lockfile
lockfile-create "$BASE"/git.lock
lockfile-touch "$BASE"/git.lock &
TOUCHER="$!"

trap 'kill $TOUCHER' EXIT 
trap "lockfile-remove $BASE/git.lock" EXIT 


# args
VERBOSE="$1"
verbosep(){
	if [ "$VERBOSE" = "-v" ] || [ "$VERBOSE" = "--verbose" ] ; then
		return 0
	fi
	return 1
}

verbosep && shift

# run the converters

if [ "$#" = 0 ] ; then
	SCRIPTS="$BASE/converters-enabled/"*
else
	SCRIPTS="$@"
fi

for converter in $SCRIPTS ; do 
	converter_name="$(basename $converter)"
	if ! [ -f $converter ] && [ -f converters-available/$converter ] ; then
		converter=converters-available/$converter
	fi
	if ! [ -x $converter ] ; then 
		echo "git-cron: skipping non-executable $converter_name"
		continue 
	fi

	verbosep && echo "git-cron: running $converter_name"
	if $converter ; then
		verbosep && echo "git-cron: $converter_name succeeded."
	else
		echo "git-cron: $converter_name failed with exit status $?."
	fi
done

# clean up after git-cvsimport
rm -f /tmp/git*.cvsps 2>/dev/null
