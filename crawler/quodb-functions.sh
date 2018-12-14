#!/bin/bash

function getQuotesJson() {
  set +u
  local quoteId=$1
  if [ -z "$quoteId" ]; then
    quoteId=`getNewQuoteId`
  fi
  curl -s http://api.quodb.com/quotes/"$MOVIE_ID"/"$quoteId"
  set -u
}

function getTitleId() {
    local jsonString=$1
    echo "$jsonString" | jq 'if has("docs") then .docs[0].title_id else empty end' | cut -f2 -d'"'
}

function saveToFiles() {
    local jsonString=$1
    for quoteId in `echo "$jsonString"|jq -r ".docs[]|.phrase_id"`
    do
        outputFile="$DATA_DIR/quote.$MOVIE_ID.$quoteId.json"
        echo "$outputFile"
        if [ ! -f "$outputFile" ]; then
            echo "$jsonString" | jq ".docs[]| select(.phrase_id==$quoteId)" > "$outputFile"
        fi
    done
}

function getSearchResultsJson() {
    local term=$1
    curl -s "http://api.quodb.com/search/$term?title=$TITLE_URL_ENCODED&phrases_per_title=10&titles_per_page=100"
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
  searchResultIds=`curl -s "http://api.quodb.com/search/t*?title=$TITLE_URL_ENCODED&phrases_per_title=10&titles_per_page=100" |  jq -r ".docs[]|select(.title_id==\"$MOVIE_ID\")|.phrase_id"`
  getFirstUnsavedId "$searchResultIds"
}

function getMoviesWithTitle() {
  curl -s "http://api.quodb.com/search/t*?title=$TITLE_URL_ENCODED&phrases_per_title=1" | jq '.docs[]|select(.serie==null)|{title_id,year}'
}

function getLowestSavedQuoteId() {
  getSavedIds | sort | head -1
}

function getHighestSavedQuoteId() {
  getSavedIds | sort | tail -1
}

function getNextQuoteId() {
  local crawlDirection=$1
  if [ "$crawlDirection" == 'forward' ]; then
    highestQuoteId=`getHighestSavedQuoteId`
    if [ ! -z "$highestQuoteId" ]; then
      echo $(( $highestQuoteId + 3 ))
    fi
  fi
  if [ "$crawlDirection" == 'backward' ]; then
    lowestQuoteId=`getLowestSavedQuoteId`
    if [ ! -z "$lowestQuoteId" ]; then
      echo $(( $lowestQuoteId - 3 ))
    fi
  fi
}