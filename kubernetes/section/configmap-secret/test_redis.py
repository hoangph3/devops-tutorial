# test_redis.py
import redis

r = redis.Redis(host="192.168.49.2",
                port="30100",
                db=0)
r.rpush('foo', 'bar')
r.rpush('foo', 'bar2')
