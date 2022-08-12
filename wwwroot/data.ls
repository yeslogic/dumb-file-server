#!/bin/sh
set -euf

handle_GET() {
    printf "Content-Type: text/plain\n\n"
    # Sort by most recent.
    # shellcheck disable=SC2010
    ls -1 -t data | grep -ve '^-'
}

error_status() {
    printf "Status: %s\n" "$1"
}

case ${REQUEST_METHOD:-} in
    GET)
        handle_GET
        ;;
    *)
        error_status "405 Method Not Allowed"
        ;;
esac
