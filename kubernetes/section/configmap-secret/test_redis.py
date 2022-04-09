# test_redis.py
import redis

r = redis.Redis(host="192.168.49.2", # host is url that kubernetes control plane is running.
                port="30100",
                db=0)
r.rpush('foo', 'bar')
r.rpush('foo', 'bar2')