#!/bin/bash

: > result

failed=0
total=0
for i in {1..20} ; do
  a=$(awk -v RS= "{ if (NR == $i) { print } }" answer.sql | sed "s/--.*//g")
  if [ -z "$a" ]; then
    break
  fi
  echo "case $i"
  let "total++"
  echo

  s=$(awk -v RS= "{ if (NR == $i) { print } }" sql.sql | sed "s/--.*//g")

  ar=$(sqlite3 ../imdb-cmudb2019.db "$a")
  sr=$(sqlite3 ../imdb-cmudb2019.db "$s")
  d=`diff -EZbBs <(echo "$ar" ) <(echo "$sr")`
  dr=$?
  echo return: "$dr"
  if [ "$dr" -eq 0 ]; then
    echo case $i pass!
  else
    echo case $i failed. check file \"result\" to see diff.
  fi

  if [ "$dr" -ne 0 ]; then
    let "failed++"
    echo "case $i" >> result
    echo ------------------------------ >> result
    echo answer >> result
    echo -e "$ar" | head -30 >> result
    echo >> result

    echo sql >> result
    echo -e "$sr" | head -30 >> result
    echo >> result

    echo diff >> result
    echo -e "$d" >> result
    echo ------------------------------- >> result
  fi

  echo "-------------------------------"
done

echo "-------------------------------" >> result
echo total: $total
echo passed: $[$total - $failed]
echo failed: $failed

echo "-------------------------------" >> result
echo total: $total >> result
echo passed: $[$total - $failed] >> result
echo failed: $failed >> result

vim result
