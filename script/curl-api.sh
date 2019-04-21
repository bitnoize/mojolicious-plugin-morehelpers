#!/bin/bash

#
# Helper functions for simple-way access to REST API via curl
#

export CURL_HOME=${CURL_HOME:-"/tmp/curl-api"}
export CURL_EDITOR=${CURL_EDITOR:-"yes"}
export CURL_ACCEPT=${CURL_ACCEPT:-"application/json"}

# API location with default value
API_BASE=${API_BASE:-"http://localhost:8000"}

mkdir -p "$CURL_HOME"

# Redefine this function in your script to add custom curl options
function _curl_options { CURL_OPTS=""; }

function _curl_prepare {
  CURL_SITE="${API_BASE}${1}"
  CURL_HEAD="$2/$3.head"
  CURL_BODY="$2/$3.body"
  CURL_DATA="$2/$3.data"

  CURL_DATA_USE=${4:-skip}
  CURL_BODY_USE=${5:-skip}

  [ -t 0 -a -t 1 ] || CURL_EDITOR=""
  [ -n "$CURL_EDITOR" -a "$CURL_DATA_USE" != "skip" ] && \
    "${EDITOR:-vim}" "$CURL_HOME/$CURL_DATA"
}

function _curl_dumper {
  echo "++ CURL_HOME: '$CURL_HOME'"
  echo "++ CURL_SITE: '$CURL_SITE'"
  echo

  echo ">> Request '$CURL_DATA'"
  case $CURL_DATA_USE in
    skip) echo -e "There is no request data\n" ;;
    text) cat  "$CURL_HOME/$CURL_DATA"; echo ;;
    json) jq . "$CURL_HOME/$CURL_DATA"; echo ;;
    *) exit 255 ;;
  esac

  echo "<< Headers '$CURL_HEAD'"
  cat "$CURL_HOME/$CURL_HEAD"

  echo "<< Response '$CURL_BODY'"
  case $CURL_BODY_USE in
    skip) echo -e "There is no response data\n" ;;
    text) cat  "$CURL_HOME/$CURL_BODY"; echo ;;
    json) jq . "$CURL_HOME/$CURL_BODY"; echo ;;
    *) exit 255 ;;
  esac
}

function _curl_execute {
  _curl_options

  "${CURL:-curl}" -s "$CURL_SITE" \
    -D  "$CURL_HOME/$CURL_HEAD" \
    -o  "$CURL_HOME/$CURL_BODY" \
    -d "@$CURL_HOME/$CURL_DATA" \
    -H "Accept: $CURL_ACCEPT" \
    "${CURL_OPTS[@]}" "$@"

  # Fix line-breaks
  sed -i "s/\r//g" "$CURL_HOME/$CURL_HEAD"
}

function _api_create {
  _curl_prepare $1 $2 ${3:-create} ${4:-json} ${5:-json}
  _curl_execute -X POST
  _curl_dumper
}

function _api_read {
  _curl_prepare $1 $2 ${3:-read} ${4:-skip} ${5:-json}
  _curl_execute -X GET
  _curl_dumper
}

function _api_update {
  _curl_prepare $1 $2 ${3:-update} ${4:-json} ${5:-json}
  _curl_execute -X PUT
  _curl_dumper
}

function _api_delete {
  _curl_prepare $1 $2 ${3:-delete} ${4:-skip} ${5:-json}
  _curl_execute -X DELETE
  _curl_dumper
}

function _api_list {
  _curl_prepare $1 $2 ${3:-list} ${4:-text} ${5:-json}
  _curl_execute -X GET
  _curl_dumper
}

function _parse_head_grep {
  grep -Fi $1 "$CURL_HOME/$CURL_HEAD" | sed -n -e "s/^$1: //p"
}

function _parse_body_json {
  jq -r ".$1" "$CURL_HOME/$CURL_BODY"
}

