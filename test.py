import testinfra

def test_redis_installed(host):
    assert host.package("redis-server").is_installed
