source http.bash

@test "http-get-query-param" {
    declare query="?hello=bye&banana=fruit&heey=\\hallo%20bye%20beep???$" output=''
    
    output="$(http-get-query-param "$query" 'banana')"
    
    echo "Output : $output"
    [[ "fruit" == "$output" ]]

    output="$(http-get-query-param "$query" 'hello')"
    
    echo "Output : $output"
    [[ "bye" == "$output" ]]

    output="$(http-get-query-param "$query" 'heey')"

    echo "Output: $output"
    [[ '\hallo bye beep???$' == "$output" ]]
}
