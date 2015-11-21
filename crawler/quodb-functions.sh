#!/bin/bash

function getQuotesJson() {
  set +u
  if [ -z "$1" ] || [ -z "$2" ]; then
    echo "{}"
  else
    curl -s http://api.quodb.com/quotes/$1/$2
  fi
  set -u
}

function getQuoteIds() {
    local jsonString=$1
    echo "$jsonString" | jq 'if has("docs") then .docs[].phrase_id else empty end' | grep -E '^[0-9]+$'
}

function getTitleId() {
    local jsonString=$1
    echo "$jsonString" | jq 'if has("docs") then .docs[0].title_id else empty end' | cut -f2 -d'"'
}

function saveToFiles() {
    local jsonString=$1
    for quoteId in `getQuoteIds "$jsonString"`
    do
        outputFile="$DATA_DIR/quote.$MOVIE_ID.$quoteId.json"
        echo "$outputFile"
        if [ ! -f "$outputFile" ]; then
            echo "$jsonString" | jq ".docs[]| select(.phrase_id==$quoteId)" > "$outputFile"
        fi
    done
    echo ""
}

function getSearchResultsJson() {
    local term=$1
    curl -s "http://api.quodb.com/search/$term?title=$TITLE_URL_ENCODED&phrases_per_title=100"
}

function getSavedIds() {
  for f in $DATA_DIR/quote.$MOVIE_ID.*.json; do
      [ -e "$f" ] && echo "$f" | cut -f3 -d'.'
  done
}

function getFirstUnsavedId() {
    local searchResultIds=$1
    for searchResultId in `echo "$searchResultIds"`;
    do
        searchResultIdIsSaved='false'
        for savedId in `getSavedIds`; 
        do
            if [ "$savedId" == "$searchResultId" ]; then
                searchResultIdIsSaved='true'
                continue
            fi
        done
        if [ "$searchResultIdIsSaved" == "false" ]; then
            echo "$searchResultId"
            break
        fi
    done
}

function getNewQuoteId() {
  resultsJson=`getSearchResultsJson 't*'`
  if [ -z "$MOVIE_ID" ]; then
    MOVIE_ID=`getTitleId "$resultsJson"`
  fi
  searchResultIds=`getQuoteIds "$resultsJson"`
  getFirstUnsavedId "$searchResultIds"
}

function getMovieId() {
  resultsJson=`getSearchResultsJson 't*'`
  getTitleId "$resultsJson"
}

function getLowestSavedQuoteId() {
  getSavedIds | sort | head -1
}

function getNextQuoteId() {
  local quotesJson=$1
  local crawlDirection=$2
  if [ "$crawlDirection" == 'forward' ]; then
    lastQuoteId=`getQuoteIds "$quotesJson" | tail -1`
    if [ ! -z "$lastQuoteId" ]; then
      echo $(( $lastQuoteId + 3 ))
    fi
  fi
  if [ "$crawlDirection" == 'backward' ]; then
    firstQuoteId=`getQuoteIds "$quotesJson" | head -1`
    if [ ! -z "$firstQuoteId" ]; then
      echo $(( $firstQuoteId - 3 ))
    fi
  fi
}