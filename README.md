Dumbest file server
===================

This is a file server with a HTTP interface.
It is currently implemented with Althttpd.

Requirements
------------

  - althttpd (vendored)
  - python3
  - bwrap

Starting the server
-------------------

Build althttpd with make then run:

    ./sodumb.sh [--port PORT] [--cert unsafe-builtin|CERT]

where CERT is the concatenation of a certificate and private key in PEM format.
You can place it in the `cert` directory.

Authentication
--------------

Althttpd supports HTTP Basic Authentication.
The password is set by editing `wwwroot/-auth`.

HTTP API
--------

  - Download file:

        GET /data/NAME

  - List files (names only, most recent first):

        GET /data.ls

  - Upload file:

        POST /data.put

    The request body must be multipart/form-data with a single "file" field,
    with a "filename" parameter.

File names are restricted to the ASCII printable characters except:

    SPACE
    /       (directory separator)
    \       (a common escape character, sometimes a directory separator)

A name may not begin with `.` or `-` because hidden files and files beginning
with `-` are special to althttpd. In particular, the `-auth` file must not be
clobbered.

`data` can be considered the bucket name, allowing the possibility of multiple
buckets (if required).

Althttpd imposes a limit of `MAX_CONTENT_LENGTH` on HTTP requests
(default: 250 million bytes).
