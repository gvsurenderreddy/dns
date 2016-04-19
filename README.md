#### What's this?

It's a skeleton DNS service, providing http api for A record registration and upstream DNS lookup.

#### Performance

Are you kidding me? It's ruby...

#### Reliable?

Better forget about it.

#### Then what is it used for?

It's used for aws: cn-north-1 region. As a temporary replacement of route53. (The region is fucked up. And you probably know why.)

#### How to use it?

install & start

```
git clone git@github.com:vivowares/dns.git
cd dns
god -c dns.god -D > god.log 2>&1 &
```

put it in crontab (assume you installed it in user `dns` home dir)

```
* * * * * cd /home/dns/dns god -c dns.god  -D >god.log 2>&1
```

basic workflow

```
god stop dns_service
god start dns_service
```

update the A record

```
curl 'localhost:5301/?hostname=test.your.vpc&ip=10.0.1.2'
```

lookup

```
dig @localhost -p 5300 test.your.vpc
```

**To use it in you vpc, you need to point your machines' /etc/resolver to this dns service.**


**Nice thing about this is, it tries it's best effort to save the A records in a file, assuming the registration is not very frequent. The `god` process take cares to keep the process alive. And the cron job runs every minute to make sure god process is also alive.**
