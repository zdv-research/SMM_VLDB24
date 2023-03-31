#!/bin/bash

app_name="sleep"
source run_env.sh


run_core () {
    sleep 5
}

run_name="5s"
set_output_file
run