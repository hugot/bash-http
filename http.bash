#!/bin/bash
##
#  HTTP module for bash CGI scripts

##
# Keep code predictable by making all CGI environment variables
# readonly
http-freeze-variables() {
    declare -gr \
	    HTTP_HOST="$HTTP_HOST" \
	    HTTP_USER_AGENT="$HTTP_USER_AGENT" \
	    CGI_PATTERN="$CGI_PATTERN" \
	    SERVER_PORT="$SERVER_PORT" \
	    SERVER_NAME="$SERVER_NAME" \
	    HTTP_ACCEPT="$HTTP_ACCEPT" \
	    REQUEST_METHOD="$REQUEST_METHOD" \
	    SCRIPT_NAME="$SCRIPT_NAME" \
	    SERVER_PROTOCOL="$SERVER_PROTOCOL" \
	    GATEWAY_INTERFACE="$GATEWAY_INTERFACE" \
	    REMOTE_ADDR="$REMOTE_ADDR" \
	    SERVER_SOFTWARE="$SERVER_SOFTWARE"

    if [[ -n ${PATH_INFO+x} ]]; then
	declare -gr PATH_INFO="$PATH_INFO"
    fi
}

##
# Send a basic http response. This function might not always be the
# most performant option, but it does provide a clean API and automatically
# adds a content-length header.
http-respond() {
    declare arg="$1" content='' status=''
    declare -A headers=()
    while shift; do
        case "$arg" in
            -S | --status)
                status="$1"
                shift
                ;;
            -H | --header)
                headers[$1]="$2"
                shift 2
                ;;
            -C | --content)
                content="$1"
                shift
                ;;
            *)
                printf 'Unknown option: "%s"\n' "${arg}" >&2
                return 1
        esac
        arg="$1"
    done

    declare content_length="$(echo "$content" | wc -c)"

    headers['Content-Length']="$content_length"

    if [[ -z ${headers['Content-Type']} ]]; then
        headers['Content-Type']='text/plain'
    fi

    if [[ -z $status ]]; then
        status=200
    fi

    printf 'HTTP/1.1 %d\n' "$status"
    for header in "${!headers[@]}"; do
        http-header "$header" "${headers[$header]}"
    done
    http-headers-end

    echo "$content"
}

http-header() {
    declare name="$1" value="$2"
    printf '%s: %s\r\n' "$name" "$value"
}

http-headers-end() {
    printf '\r\n'
}

http-init() {
    if [[ -z "$1" ]]; then
	declare -i status=200
    else
	declare -i status="$1"
    fi
    
    printf 'HTTP/1.1 %d\r\n' "$status"
}

##
# Get a GET param from a query string
http-get-query-param() {
    declare query_string="$1" parameter="$2"

    if [[ "$query" =~ (&|^\?)"$parameter"=([^&]+) ]]; then
	declare value="${BASH_REMATCH[2]}"
	value="${value//\\/\\\\}"
	value="${value//%/\\\x}"
	value="${value//+/ }"

	echo -e "${value}"
	return 0
    fi

    return 1
}
