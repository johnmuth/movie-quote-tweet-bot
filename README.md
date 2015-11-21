# movie-quote-tweet-bot

Tweets lines from movies, one at a time, in order.

## Prerequisites

-  [Node.js](https://nodejs.org)
-  [jq](https://stedolan.github.io/jq/)

## Usage

1.  Download quotes for the movie you want your bot to tweet: `./crawler/crawl-movie-quotes.sh -t 'Animal Crackers'`
2.  Create a Twitter account for your bot.
3.  Create a Twitter "app" for your bot. Doing so gives you keys your bot will need, to use the Twitter API. [https://apps.twitter.com/app/new](https://apps.twitter.com/app/new)
4.  Set environment variables as illustrated in `setenvs.example.sh`
5.  Run it: `node movie-quote-tweet-bot.js`

## Example bots

- [@SingerTravis](https://twitter.com/SingerTravis) - *Annie Hall* and *Taxi Driver*, alternating
- [@rebelwithoutca1](https://twitter.com/rebelwithoutca1) - *Rebel Without a Cause*
- [@liquidskybot](https://twitter.com/liquidskybot) - *Liquid Sky*

## Credits

Thanks to http://www.quodb.com for providing an easy way to get movie quotes.
