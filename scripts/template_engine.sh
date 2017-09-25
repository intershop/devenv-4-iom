#!/bin/bash

usage() {
    ME=$(basename $0)
    cat <<EOF
$ME
    redeploys OMS artifacts

SYNOPSIS
    $(basename $0) <template-file> [ <config-file> ]" [-h]

DESCRIPTION
    This is a very simple templating system to render environment varibales
    or variables of a given <config-file> in a given <template-file> by using
    the given pre-defined template-variables file.

    Other options:

    -h
      Display this help and exit.

EXAMPLES

    VAR1=Something VAR2=1.2.3 ${ME} ../templates/index.template
    ${ME} ../templates/index.template variables.sample
    VAR1=Something VAR2=1.2.3 ${ME} ../templates/index.template variables.sample > index.html
    ${ME} ../templates/index.template variables.sample > index.html"

EOF
}

# render the template and replace the variables
render(){
	FILE="$1"
  # read the lines of the template
	while read -r LINE ; do
    # find the variables by regex
	   while [[ "$LINE" =~ (\$\{[a-zA-Z_][a-zA-Z_0-9]*\}) ]] ; do
        MATCH=${BASH_REMATCH[1]}
    		REPLACED_MATCH="$(eval echo "\"$MATCH\"")"
        # replace all
    		LINE=${LINE//$MATCH/$REPLACED_MATCH}
	    done
      # output
	    echo "$LINE"
	done < $FILE
}

# name of template-variables file
TEMPLATE_VAR_FILE=template-variables

# $1 is name of the template-file
TEMPLATE_FILE=$1
# $2 is name of the config-file
CONFIG_FILE=$2
shift
shift

for OPT in "$@"; do
    case $OPT in
        -h)
            usage
            exit
            ;;
        *)  echo "invalid option $OPT" 1>&2
            echo 1>&2
            usage 1>&2
            exit 1
            ;;
    esac
done

# check template-file
if [ -z "$TEMPLATE_FILE" -o ! -f "$TEMPLATE_FILE" ]; then
    echo "template-file missing!" 1>&2
    echo 1>&2
    usage 1>&2
    exit 1
fi

# config-file given and exists
if [ ! -z "$CONFIG_FILE" -a -f "$CONFIG_FILE" ]; then

  # check syntax of $CONFIG_FILE
  if ! ( set -e; . $CONFIG_FILE ); then
      echo "error reading '$CONFIG_FILE'" 1>&2
      exit 1
  fi

  # read $CONFIG_FILE
  . $CONFIG_FILE

fi

# check template-variables file
if [ -z "$TEMPLATE_VAR_FILE" -o ! -f "$TEMPLATE_VAR_FILE" ]; then
    echo "template-variables file missing!" 1>&2
    echo 1>&2
    usage 1>&2
    exit 1
fi

# check syntax of $TEMPLATE_VAR_FILE
if ! ( set -e; . $TEMPLATE_VAR_FILE ); then
    echo "error reading '$TEMPLATE_VAR_FILE'" 1>&2
    exit 1
fi

# read $TEMPLATE_VAR_FILE
. $TEMPLATE_VAR_FILE

render "$TEMPLATE_FILE"
