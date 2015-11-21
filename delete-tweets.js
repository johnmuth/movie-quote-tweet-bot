var Twit = require('twit');

var T = new Twit({
    consumer_key: process.env.TWITTER_CONSUMER_KEY,
    consumer_secret: process.env.TWITTER_CONSUMER_SECRET,
    access_token: process.env.TWITTER_ACCESS_TOKEN,
    access_token_secret: process.env.TWITTER_ACCESS_TOKEN_SECRET
});

T.get('statuses/user_timeline', function (err, statuses) {
    if (err) {
        console.error("error getting tweets: ", err);
    }
    for (var i=0; i<statuses.length; i++) {
        var path = 'statuses/destroy/' + statuses[i].id;
        console.log("About to delete: " + path);
        T.post(path, function (err, response) {
            if (err) {
                console.error("error deleting tweet: ", err);
            } else {
                console.log("response: ", response);
            }
        });
    }
});
