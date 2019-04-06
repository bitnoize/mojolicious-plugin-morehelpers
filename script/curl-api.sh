#!/bin/bash

#
# Helper functions for simple-way access REST API via curl
#

# Resource files can be found here
CURL_HOME=${CURL_HOME:-"/tmp/curl-api"}

# API location with default value
API_BASE=${API_BASE:-"http://localhost:8000"}

mkdir -p "$CURL_HOME"

function curl_options { CURL_OPTS=""; }

function _curl_prepare {
  CURL_SITE="${API_BASE}${1}"
  CURL_DATA="$2/$3.data"
  CURL_HEAD="$2/$3.head"
  CURL_BODY="$2/$3.body"
}

function _curl_dumper {
  local show_body=${1:-skip}
  local show_data=${2:-skip}

  echo "== Headers '$CURL_HEAD':"
  cat "$CURL_HOME/$CURL_HEAD"

  echo "== Response '$CURL_BODY':"
  case $show_body in
    skip) echo -e "There is no response data\n" ;;
    text) cat  "$CURL_HOME/$CURL_BODY"; echo ;;
    json) jq . "$CURL_HOME/$CURL_BODY"; echo ;;
    *) exit 255 ;;
  esac

  echo "== Request '$CURL_DATA':"
  case $show_data in
    skip) echo -e "There is no request data\n" ;;
    text) cat  "$CURL_HOME/$CURL_DATA"; echo ;;
    json) jq . "$CURL_HOME/$CURL_DATA"; echo ;;
    *) exit 255 ;;
  esac
}

function _curl_execute {
  curl_options

  curl -s "$CURL_SITE" \
    -D  "$CURL_HOME/$CURL_HEAD" \
    -o  "$CURL_HOME/$CURL_BODY" \
    -d "@$CURL_HOME/$CURL_DATA" \
    "${CURL_OPTS[@]}" "$@"
}

function _api_create {
  _curl_prepare $1 $2 ${3:-create}
  _curl_execute -X POST
  _curl_dumper ${4:-json} ${5:-json}
}

function _api_read {
  _curl_prepare $1 $2 ${3:-read}
  _curl_execute -X GET
  _curl_dumper ${4:-json} ${5:-skip}
}

function _api_update {
  _curl_prepare $1 $2 ${3:-update}
  _curl_execute -X PUT
  _curl_dumper ${4:-json} ${5:-json}
}

function _api_delete {
  _curl_prepare $1 $2 ${3:-delete}
  _curl_execute -X DELETE
  _curl_dumper ${4:-json} ${5:-skip}
}

function _api_list {
  _curl_prepare $1 $2 ${3:-list}
  _curl_execute -X GET
  _curl_dumper ${4:-json} ${5:-text}
}

function _parse_head_grep {
  grep -Fi $1 "$CURL_HOME/$CURL_HEAD" | sed -n -e "s/^$1: //p"
}

function _parse_body_json {
  jq -r ".$1" "$CURL_HOME/$CURL_BODY"
}

