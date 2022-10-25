#!/bin/bash

configtest=no
datafile=all
while getopts ":yf:" opt; do
        case $opt in
                y)
                        configtest=yes
                        ;;
                f)
                        datafile=$OPTARG
                        ;;
                \?)
                        echo "Error: invalid option"
                        exit;;
        esac
done

if [[ $configtest == "yes" ]]; then
        /opt/logstash/bin/logstash --config.test_and_exit -f /opt/logstash/rspec-tests/filters
fi

if [[ $datafile == "all" ]]; then
        DATA_TEST=/opt/logstash/rspec-tests/data/*.json /opt/logstash/bin/rspec -f p /opt/logstash/rspec-tests/rspec_script.rb
elif [[ -f $datafile ]]; then
        DATA_TEST=$datafile /opt/logstash/bin/rspec -f p /opt/logstash/rspec-tests/rspec_script.rb
else
        echo "ERROR : $datafile is not a valid file path"
fi