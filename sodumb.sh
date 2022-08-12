#!/bin/sh
#
# Start file server.
#
set -euf

DIR=$(dirname "$0")

PORT=12022
CERT=
SANDBOX_SHELL=0

while [ $# -gt 0 ] ; do
    case $1 in
        --port)
            PORT=$2
            shift 2
            ;;
        --cert)
            CERT=$2
            shift 2
            ;;
        --shell)
            SANDBOX_SHELL=1
            shift 1
            ;;
        --)
            shift 1
            break
            ;;
        -*)
            echo "unknown option: $1" >&2
            exit 1
            ;;
    esac
done

if [ $# -gt 0 ] ; then
    echo "too many arguments" >&2
    exit 1
fi

cd "$DIR"

# Just in case.
umask 022

# In case bwrap is not installed on the system.
PATH="$PATH:$HOME/bin"

if ! command -v bwrap >/dev/null ; then
    echo "missing bwrap" >&2
    exit 1
fi

exec_sandbox() {
    exec bwrap \
        --unshare-all \
        --share-net \
        --chdir / \
        --tmpfs / \
        --ro-bind /bin /bin \
        --ro-bind /lib /lib \
        --ro-bind-try /lib64 /lib64 \
        --ro-bind /usr /usr \
        --ro-bind ./althttpd /althttpd \
        --ro-bind ./wwwroot /wwwroot \
        --bind ./wwwroot/data /wwwroot/data \
        --ro-bind-try ./cert /cert \
        --dev /dev \
        --proc /proc \
        --dir /tmp \
        --die-with-parent \
        -- "$@"
}

if [ "$SANDBOX_SHELL" = 1 ] ; then
    exec_sandbox bash -i
    exit 1
fi

case $CERT in
    '')
        exec_sandbox /althttpd/althttpd -logfile /dev/stderr -root /wwwroot --port "$PORT"
        ;;
    *)
        exec_sandbox /althttpd/althttpsd -logfile /dev/stderr -root /wwwroot --port "$PORT" --cert "$CERT"
        ;;
esac
