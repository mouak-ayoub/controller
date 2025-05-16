#!/bin/bash

pip install "apache-airflow[celery]==2.10.5" --constraint "https://raw.githubusercontent.com/apache/airflow/constraints-2.10.5/constraints-3.8.txt"
airflow db init
airflow users create \
--username admin \
--firstname ayoub \
--lastname mk \
--role Admin \
--email anything@mail.com \
--password passwd
tmux new-session -d -s airflow-webserver 'airflow webserver --port 8080'
tmux new-session -d -s airflow-scheduler 'airflow scheduler'

