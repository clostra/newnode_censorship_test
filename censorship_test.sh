#!/bin/bash
#
# Given a file from https://github.com/citizenlab/test-lists test whether NewNode can reach the URLs in it
# Assumes that a NewNode client is running at 127.0.0.1:8006 or at the host:port given on the command line

shopt -s extglob

# default NewNode proxy location
proxy_host="127.0.0.1"
proxy_port="8006"

show_help() {
    echo "$0 [-h] [-p host:port] urls"
    echo "-h    show this help"
    echo "-p    specify an alternate NewNode proxy (default 127.0.0.1:8006)"
    echo "urls  CSV file from Citizen Lab containing URLs to test"
    exit 0
}

# response counters
failures=0
successes=0
redirects=0
client_errors=0
server_errors=0

track_response_stats() {
    case "$1" in
        000 ) 
            ((++failures))
            ;;
        2?? )
            ((++successes))
            ;;
        3?? )
            ((++redirects))
            ;;
        4?? )
            ((++client_errors))
            ;;
        5?? )
            ((++server_errors))
            ;;
    esac
}

print_report() {
    echo "==============================="
    echo "Unreachable sites: $failures"
    echo "Successes (2xx): $successes"
    echo "Redirects (3xx): $redirects"
    echo "Client Errors (4xx): $client_errors"
    echo "Server errors (5xx): $server_errors"
}

while getopts "hp:" opt; do
    case "$opt" in
    h|\?)
        show_help
        ;;
    p)  proxy=$OPTARG
        proxy_host=${OPTARG%%:*}
        proxy_port=${OPTARG##*:}
        # TODO validate host IP and port formats
        ;;
    esac
done

shift $((OPTIND-1))

[ $# = 1 ] || show_help

# TODO validate that a NewNode proxy is running at host:port

line=0
while IFS=, read -r url category_code category_description date_added src notes
do
    [ $((++line)) -eq 1 ] && continue
    response="$(curl --output /dev/null --proxy $proxy_host:$proxy_port --location --silent --fail -r 0-0 -w "%{http_code}" $url)"
    echo "$url $response"
    track_response_stats "$response"
done < $@
print_report
