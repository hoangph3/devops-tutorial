from flask import Flask
import redis
import os


app = Flask(__name__)
REDIS_URL = os.environ["REDIS_URL"]
redis = redis.Redis.from_url(REDIS_URL)


@app.route('/')
def hello():
    redis.incr('hits')
    return 'Hello World! I have been seen %s times.' % redis.get('hits')


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8000, debug=True)
