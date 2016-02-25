#!/bin/bash

set -e
set -u

usage() { echo "Usage: $0 -t <title>" 1>&2; exit 1; }

MOVIE_ID=''
MOVIE_TITLE=''
DATA_DIR=''
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
nextQuoteId=''

while getopts ":t:" o; do
    case "${o}" in
        t)
            MOVIE_TITLE=${OPTARG}
            TITLE_URL_ENCODED=`python -c "import sys, urllib as ul; \
                print ul.quote_plus(\"$MOVIE_TITLE\")"`
            DATA_DIR='movie-quotes'/${TITLE_URL_ENCODED}
            if [ ! -d "$DATA_DIR" ]; then
                mkdir -p "$DATA_DIR"
            fi
            ;;
        *)
            usage
            ;;
    esac
done

if [ -z "$DATA_DIR" ] || [ -z "$MOVIE_TITLE" ]; then
    usage
fi

source "$SCRIPT_DIR"/quodb-functions.sh

MOVIE_ID=`getMovieId`
if [ -z "$MOVIE_ID" ]; then
  echo "Unable to find id for title '$MOVIE_TITLE' at quodb.com"
  exit 1
fi

crawlDirection='backward'
while [ "$crawlDirection" != 'stop' ];
do
  quotesJson=`getQuotesJson $nextQuoteId`
  saveToFiles "$quotesJson"
  nextQuoteId=`getNextQuoteId "$quotesJson" "$crawlDirection"`
  if [ -z "$nextQuoteId" ] && [ "$crawlDirection" == 'backward' ]; then
    echo "Reached the beginning. Now crawling forward to the end."
    crawlDirection='forward'
    nextQuoteId=$(( `getHighestSavedQuoteId` + 3 ))
  elif [ -z "$nextQuoteId" ]; then
    crawlDirection='stop'
  fi
done

echo "Finished."
