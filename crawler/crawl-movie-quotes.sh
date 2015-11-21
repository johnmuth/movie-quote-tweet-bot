#!/bin/bash

set -e
set -u

usage() { echo "Usage: $0 -t <title> [ -q <quote id>]" 1>&2; exit 1; }

MOVIE_ID=''
MOVIE_TITLE=''
DATA_DIR=''
nextQuoteId=''

while getopts ":t:q:" o; do
    case "${o}" in
        t)
            MOVIE_TITLE=${OPTARG}
            TITLE_URL_ENCODED=`echo "$MOVIE_TITLE" | sed "s/ /%20/g" | sed "s/&/%26/g"`
            DATA_DIR=${TITLE_URL_ENCODED}
            if [ ! -d "$DATA_DIR" ]; then
                mkdir -p "$DATA_DIR"
            fi
            ;;
        q)
            nextQuoteId=${OPTARG}
            ;;
        *)
            usage
            ;;
    esac
done

if [ -z "$DATA_DIR" ] || [ -z "$MOVIE_TITLE" ]; then
    usage
fi

source ./quodb-functions.sh

if [ -z "$nextQuoteId" ]; then
  nextQuoteId=`getNewQuoteId`
fi

if [ -z "$MOVIE_ID" ]; then
  MOVIE_ID=`getMovieId`
  if [ -z "$MOVIE_ID" ]; then
    echo "Unable to find id for title '$MOVIE_TITLE' at quodb.com"
    exit 1
  fi
fi

crawlDirection='forward'
while [ "$crawlDirection" == 'forward' ] || [ "$crawlDirection" == 'backward' ] ;
do
  quotesJson=`getQuotesJson $MOVIE_ID $nextQuoteId`
  saveToFiles "$quotesJson"
  nextQuoteId=`getNextQuoteId "$quotesJson" "$crawlDirection"`
  if [ -z "$nextQuoteId" ] && [ "$crawlDirection" == 'forward' ]; then
    echo "Reached the end. Now crawling backward to ensure we have the beginning."
    crawlDirection='backward'
    nextQuoteId=$(( `getLowestSavedQuoteId` - 1 ))
  fi
  if [ -z "$nextQuoteId" ] && [ "$crawlDirection" == 'backward' ]; then
    crawlDirection='stop'
  fi
done

echo "Finished."
