#!/usr/bin/env bash

set -e

age_dir=.age
age_file=keys.txt
path_to_age=/tmp/${age_dir}
path_to_age_file=${path_to_age}/${age_file}

if [ -f "$path_to_age_file" ] && ( grep 'AGE-SECRET-KEY' ${path_to_age_file} 1>/dev/null 2>&1 ); then
  echo "Info: age key has already existed! Skip."
  exit
fi

echo "Pls enter username: "
read user
echo "Pls enter pw: "
read -s pw
echo "Pls enter host: "
read host

mkdir -p ${path_to_age}

retry=1
max_retry=10
while (( retry < max_retry )) && ( ! grep 'AGE-SECRET-KEY' ${path_to_age_file} 1>/dev/null 2>&1 ); do
  echo "[retry ${retry}] AGE-SECRET-KEY does not exist in ${path_to_age_file}, trying to access it..."
  curl -o ${path_to_age_file} -u "${user}:${pw}" https://${host}/dav/config/${age_dir}/${age_file}
  retry=$((retry + 1))
done

if [ $retry == $max_retry ]; then
  echo "Reach max retry: $retry."
  exit 1
else
  echo "Restore age keys successfully! The key is in ${path_to_age_file}."
fi
