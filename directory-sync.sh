#!/bin/bash
#
# Sync files from a source directory to a destination directory when files in the source directory
# change.  We only support syncing a source directory and automatically add a trailing slash to the
# source diretory. Requires fswatch (brew install fswatch).

# rsync excludes file
EXCLUDES_FILE="/tmp/file-sync-excludes-$$.txt"
# Optional rsync log file
LOG_FILE=
# Source directory
SOURCE_DIR=
# Destination directory (local or remote)
DESTINATION=
# Perform an initial sync before watching for changes to the source directory?
INITIAL_SYNC=0
# Remote shell to use for rsync, useful for specifying an alternate ssh port.  Note: This variable
# must be quoted in the command for quotes to represented properly
REMOTE_SHELL='ssh -p 22'
# Clear this to stop removing remote files
DELETE_REMOTE="--delete"

# Exclude data that does not need to be on the webserver
EXCLUDES=(
    ".git"
    ".gitignore"
    ".gitmodules"
    ".gitlab-ci.yal"
    ".tags"
    "*.swp"
    ".DS_Store"
    "Icon\r"
    "private/cache"
    "private/logs"
)

function cleanup_on_exit {
    echo "$0 Cleaning up"
    if [[ -f $EXCLUDES_FILE ]]; then
        echo "Remove excludes file $EXCLUDES_FILE"
        rm $EXCLUDES_FILE
    fi
    exit 0
}

function show_help {
cat <<HELP
Usage $0 -s *source-dir* -d *destination** [-i] [-n] [-l *log-file*] [-e *excludes-file*] [-r *remote-shell*]
Where:
    -d The destination (local directory or remote location).
    -s The source directory. The contents of the directory will be synced, not the directory itself.
    -r Optional remote shell to use for rsync. Useful for specifying an alternate ssh port.
    -i Perform an initial sync before enabling the file watcher on the source directory.
    -n Do not delete remote files
    -l rsync log file

For example:

To sync only changes to the "source" directory to a remote host

file-sync.sh -i -s source/ -d remotehost.com:~/test

To perform an initial sync of the current directory and any subsequent changes to a remote server
using ssh on port 1027 with an inital rsync

file-sync.sh -s `pwd` -d remotehost.com:/var/www/html -r "ssh -p 1027" -i
HELP
}

# Cleanup after ourselves on exit

trap cleanup_on_exit SIGINT SIGTERM

while getopts "h?d:e:il:p:r:s:" opt; do
    case "$opt" in
        h|\?)
            show_help
            exit 0
            ;;
        d)  DESTINATION=$OPTARG
            ;;
        i)  INITIAL_SYNC=1
            ;;
        l)  LOG_FILE="--log-file=$OPTARG"
            ;;
        n)  DELETE_REMOTE=
            ;;
        r)  REMOTE_SHELL=$OPTARG
            ;;
        s)  SOURCE_DIR=$OPTARG
            ;;
    esac
done

if [[ -z $DESTINATION ]]; then
    echo "Must specify a destination"
    exit 1
fi

if [[ -z $SOURCE_DIR || ! -d $SOURCE_DIR ]]; then
    echo "Source directory '$SOURCE_DIR' is not a directory"
    exit 1
fi

printf -- '%s\n' "${EXCLUDES[@]}" > ${EXCLUDES_FILE}

# We are syncing the contents of the source directory so rsync needs it to have a training slash
last_char=${SOURCE_DIR:${#SOURCE_DIR}-1:1}
[[ $last_char != "/" ]] && SOURCE_DIR="${SOURCE_DIR}/"

# Note that REMOTE_SHELL is in quotes as this string will likely contain quotes.
if [ 1 -eq $INITIAL_SYNC ]; then
    rsync -auq --stats --copy-unsafe-links --exclude-from=${EXCLUDES_FILE} ${DELETE_REMOTE} -e "${REMOTE_SHELL}" ${LOG_FILE} ${SOURCE_DIR} ${DESTINATION}
fi

# Every time we notice a change in the watched directory, do an rsync to the destination. With -o we
# are printing the number of changes that ocurred and we can use this to run rsync once per batch
# rather than once per file.

# VSCode file edits stopped generating fswatch events. Sync every 10 seconds instead.
# fswatch -o -0 -e "*.swp" -e ".git*" "${SOURCE_DIR}" | while read -d "" num; do
#     # Note that REMOTE_SHELL is in quotes as this string will likely contain quotes.
#     rsync -auq --stats --copy-unsafe-links --exclude-from=${EXCLUDES_FILE} ${DELETE_REMOTE} -e "${REMOTE_SHELL}" ${LOG_FILE} ${SOURCE_DIR} ${DESTINATION}
# done

while [ 1 -eq 1 ]; do
    rsync -auq --stats --copy-unsafe-links --exclude-from=${EXCLUDES_FILE} ${DELETE_REMOTE} -e "${REMOTE_SHELL}" ${LOG_FILE} ${SOURCE_DIR} ${DESTINATION}
    sleep 10
done
