var Twit = require('twit');
var fs = require('fs');
var intervalMilliseconds = process.env.TWEET_INTERVAL_MINUTES * 60 * 1000;

var T = new Twit({
    consumer_key: process.env.TWITTER_CONSUMER_KEY, 
    consumer_secret: process.env.TWITTER_CONSUMER_SECRET,
    access_token: process.env.TWITTER_ACCESS_TOKEN,
    access_token_secret: process.env.TWITTER_ACCESS_TOKEN_SECRET
});

var dataDir1 = process.env.DATA_DIR_1.replace(/([^\/])$/, '$1\/');
var dataDir2 = process.env.DATA_DIR_2.replace(/([^\/])$/, '$1\/');
var nextDataDir = dataDir1;
var nextQuoteIndex = {};
nextQuoteIndex[dataDir1] = 0;
nextQuoteIndex[dataDir2] = 0;

function tweetAQuote() {
    var files = fs.readdirSync(nextDataDir);
    var quoteJsonFile = nextDataDir + files[nextQuoteIndex[nextDataDir]];
    var moviequote = require(quoteJsonFile);
    console.log('About to tweet quote #' + nextQuoteIndex[nextDataDir] + ' from ' + nextDataDir + ' : ' + moviequote.phrase);
    T.post('statuses/update', {status: moviequote.phrase}, function (err, reply) {
        if (err) {
            console.error("error: " + err);
        }
    });
}

function incrementDataDir() {
    nextQuoteIndex[nextDataDir] = nextQuoteIndex[nextDataDir] + 1;
    if (fs.readdirSync(nextDataDir).length <= nextQuoteIndex[nextDataDir]) {
        console.log('REACHED THE END, STARTING OVER, IN ' + nextDataDir);
        nextQuoteIndex[nextDataDir]=0;
    }
    if (nextDataDir==dataDir1) {
        nextDataDir=dataDir2;
    } else {
        nextDataDir=dataDir1;
    }
}

setInterval(function () {
    // wrapped in a try/catch in case Twitter is unresponsive, don't care about error it just won't tweet.
    try {
        tweetAQuote();
        incrementDataDir();
    }
    catch (e) {
        console.log(e);
    }
}, intervalMilliseconds);

