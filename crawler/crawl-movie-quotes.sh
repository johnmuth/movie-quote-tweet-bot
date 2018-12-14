#!/bin/bash

set -e
set -u

usage() { echo "Usage: $0 -t <title> [-y <year>]" 1>&2; exit 1; }

MOVIE_ID=''
MOVIE_TITLE=''
DATA_DIR=''
MOVIE_YEAR=''
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
nextQuoteId=''

while getopts ":t:y:" o; do
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
        y)
            MOVIE_YEAR=${OPTARG}
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

moviesWithTitle=`getMoviesWithTitle "$TITLE_URL_ENCODED"`
moviesWithTitleCount=`echo "$moviesWithTitle" | jq -s length`

if [ "$moviesWithTitleCount" -gt "1" ]; then
    if [ -z "$MOVIE_YEAR" ]; then
        echo "Found multiple movies with title '$MOVIE_TITLE'"
        echo "Add -y <year> to distinguish."
        echo "$moviesWithTitle"
        usage
    fi
    MOVIE_ID=`echo "$moviesWithTitle" | jq -r "select(.year==$MOVIE_YEAR)|.title_id"`
fi
if [ "$moviesWithTitleCount" -eq "1" ]; then
    MOVIE_ID=`echo "$moviesWithTitle" | jq -r ".[0]|.title_id"`
fi

if [ -z "$MOVIE_ID" ]; then
  echo "Unable to find id for title '$MOVIE_TITLE' at quodb.com"
  exit 1
fi

crawlDirection='backward'
while [ "$crawlDirection" != 'stop' ];
do
  quotesJson=`getQuotesJson $nextQuoteId`
  error=`echo "$quotesJson" | jq '.error'`
  if [ ! -z "$error" ] && [ "$error" != "null" ]; then
    if [ "$crawlDirection" == 'backward' ]; then
        echo "Reached the beginning. Now crawling forward to the end."
        crawlDirection='forward'
        nextQuoteId=`getNextQuoteId "$crawlDirection"`
    else
        echo "Reached the end."
        crawlDirection='stop'
    fi
  else
      saveToFiles "$quotesJson"
      nextQuoteId=`getNextQuoteId "$crawlDirection"`
  fi
done

echo "Finished."
