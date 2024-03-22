# usages

- [quick start](https://pm2.keymetrics.io/docs/usage/quick-start/)
- [Configuration File](https://pm2.keymetrics.io/docs/usage/application-declaration/)


```sh
# run a script every minute
pm2 start ./script.sh --name ${service_name} --cron="*/1 * * * *" --no-autorestart

pm2 delete ${service_name_or_index}

pm2 logs
pm2 logs ${service_name}

pm2 monit

pm2 save
```
