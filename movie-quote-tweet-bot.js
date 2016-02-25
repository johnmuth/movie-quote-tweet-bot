var Twit = require('twit');
var fs = require('fs');
var intervalMilliseconds = 0;
if (process.env.TWEET_INTERVAL_MINUTES) {
    intervalMilliseconds = process.env.TWEET_INTERVAL_MINUTES * 60 * 1000;
} else if (process.env.TWEET_INTERVAL_SECONDS) {
    intervalMilliseconds = process.env.TWEET_INTERVAL_SECONDS * 1000;
}

var T = new Twit({
    consumer_key: process.env.TWITTER_CONSUMER_KEY, 
    consumer_secret: process.env.TWITTER_CONSUMER_SECRET,
    access_token: process.env.TWITTER_ACCESS_TOKEN,
    access_token_secret: process.env.TWITTER_ACCESS_TOKEN_SECRET
});
var dataDirs = JSON.parse(process.env.DATA_DIRS);
var nextDataDirIndex = 0;
var nextQuoteIndex = {};
var quoteFiles = {};
for (var i = 0; i < dataDirs.length; i++) {
    nextQuoteIndex[i]=0;
    quoteFiles[i] = fs.readdirSync(dataDirs[i]);
}
var nextQuoteFile = dataDirs[0] + '/' + quoteFiles[0][0];

function tweetAQuote() {
    var moviequote = require(nextQuoteFile);
    console.log("About to tweet: ", moviequote.phrase);
    if (process.env.DRY_RUN != 'true') {
        T.post('statuses/update', {status: moviequote.phrase}, function (err, reply) {
            if (err) {
                console.error("error: ", err);
            }
        });
    }
}

function incrementQuoteData() {
    if (nextQuoteIndex[nextDataDirIndex] == quoteFiles[nextDataDirIndex].length - 1) {
        nextQuoteIndex[nextDataDirIndex] = 0;
    } else {
        nextQuoteIndex[nextDataDirIndex] = nextQuoteIndex[nextDataDirIndex] + 1;
    }
    if (nextDataDirIndex==dataDirs.length - 1) {
        nextDataDirIndex = 0;
    } else {
        nextDataDirIndex++;
    }
    nextQuoteFile = dataDirs[nextDataDirIndex] + '/' + quoteFiles[nextDataDirIndex][nextQuoteIndex[nextDataDirIndex]];
}

setInterval(function () {
    // wrapped in a try/catch in case Twitter is unresponsive, don't care about error it just won't tweet.
    try {
        tweetAQuote();
        incrementQuoteData();
    }
    catch (e) {
        console.log(e);
    }
}, intervalMilliseconds);
