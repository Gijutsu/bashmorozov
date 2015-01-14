#!/bin/bash
# Simple IRC-bot that serves as an example how bash
# can be used in network programming. However this
# is only an experiment and more robust functionality
# can be achived using e.g. Python or Java instead.
# For detailed descriptions about the protocol used, 
# see https://tools.ietf.org/html/rfc1459

USERNAME="botname"
HOSTNAME="bothostname"
REALNAME="botrealname"
SERVERNAME="subdomain.example.com"
PORT=6667
CHANNEL="#mychannel"

# Bash 4.1-alpha and later supports automatic
# file descriptor allocation
exec {FD}<>/dev/tcp/${SERVERNAME}/${PORT}

# Send text on the opened socket
# First argument: the text to send
send()
{
    local __messageToSend=$1
    echo "$__messageToSend" >&${FD}
}

# Send a PRIVMSG
# First argument: the channel to send to
# Second argument: the message to send
sendPRIVMSG()
{
    local __channel=$1
    local __message=$2

    send "PRIVMSG $__channel :$__message"
}

# Receive one line of text from the opened socket
# First argument: variable in which to return the text  
receive()
{
    local __message=""

    IFS='\n' read -ru ${FD} '__message'

    # Remove carriage return from the value to return so
    # that bash will not give us any problem when 
    # matching against the message.
    echo -n "$__message" | tr -d '\r'
}

# Convert from hex to decimal
# First argument: the channel to respond to
# Second argument: the hex to convert
convertHexToDec()
{
    local __channel=$1
    local __hexToConvert=$2

    sendPRIVMSG "$__channel" "Validating convert syntax ..."

    if [[ "$__hexToConvert" =~ ^0x[[:xdigit:]]+$ ]]; then
        
        if [[ ${#__hexToConvert} -gt 17 ]]; then
            sendPRIVMSG "$__channel" "I do not allow buffer overflows :P"
        else
            sendPRIVMSG "$__channel" "Correct convert syntax"
            sendPRIVMSG "$__channel" "$__hexToConvert in decimal is $(($__hexToConvert))"
        fi

    else
        sendPRIVMSG "$__channel" ":Invalid convert syntax"
    fi
}

# Test if a site is blocked in China
# First argument: the channel to respond to
# Second argument: the site to test
blockedInChina()
{
    local __channel=$1
    local __URLToTest=$2
    local __baseURL="http://www.blockedinchina.net/?siteurl="
    local __result=""

    local __regexOKBeijing='.*<td class="serverlocation">Beijing</td><td class="ok">OK</td>'
    local __regexBLOCKBeijing='.*<td class="serverlocation">Beijing</td><td class="fail">BLOCKED</td>'
    local __regexOKShenzhen='.*<td class="serverlocation">Shenzhen</td><td class="ok">OK</td>'
    local __regexBLOCKEDShenzhen='.*<td class="serverlocation">Shenzhen</td><td class="fail">BLOCKED</td>'
    local __regexOKInnerMongolia='.*<td class="serverlocation">Inner Mongolia</td><td class="ok">OK</td>'
    local __regexBLOCKEDInnerMongolia='.*<td class="serverlocation">Inner Mongolia</td><td class="fail">BLOCKED</td>'
    local __regexOKHeilongjiangProvince='.*<td class="serverlocation">Heilongjiang Province</td><td class="ok">OK</td>'
    local __regexBLOCKEDHeilongjiangProvince='.*<td class="serverlocation">Heilongjiang Province</td><td class="fail">BLOCKED</td>'
    local __regexOKYunnanProvince='.*<td class="serverlocation">Yunnan Province</td><td class="ok">OK</td>'
    local __regexBLOCKEDYunnanProvince='.*<td class="serverlocation">Yunnan Province</td><td class="fail">BLOCKED</td>'
    local __regexError='.*An error occured'

    __result=$(curl -qf -m 6 "$__baseURL$__URLToTest")

    if [[ $? -eq 0 ]]; then
        
        if [[ ! $__result =~ $__regexError ]]; then
        
            if [[ $__result =~ $__regexOKBeijing ]]; then
                sendPRIVMSG "$__channel" "$__URLToTest is reachable from Beijing"
            elif [[ $__result =~ $__regexBLOCKBeijing ]]; then
                sendPRIVMSG "$__channel" "$__URLToTest is BLOCKED from Beijing"
            fi
            
            if [[ $__result =~ $__regexOKShenzhen ]]; then
                 sendPRIVMSG "$__channel" "$__URLToTest is reachable from Shenzhen"
            elif [[ $__result =~ $__regexBLOCKEDShenzhen ]]; then
                sendPRIVMSG "$__channel" "$__URLToTest is BLOCKED from Shenzhen"
            fi

            if [[ $__result =~ $__regexOKInnerMongolia ]]; then
                sendPRIVMSG "$__channel" "$__URLToTest is reachable from Inner Mongolia"
            elif [[ $__result =~ $__regexBLOCKEDInnerMongolia ]]; then
                sendPRIVMSG "$__channel" "$__URLToTest is BLOCKED from Inner Mongolia"
            fi

            if [[ $__result =~ $__regexOKHeilongjiangProvince ]]; then
                sendPRIVMSG "$__channel" "$__URLToTest is reachable from Heilongjiang Province"
            elif [[ $__result =~ $__regexBLOCKEDHeilongjiangProvince ]]; then
                sendPRIVMSG "$__channel" "$__URLToTest is BLOCKED from Heilongjiang Province"
            fi

            if [[ $__result =~ $__regexOKYunnanProvince ]]; then
                sendPRIVMSG "$__channel" "$__URLToTest is reachable from Yunnan Province"
            elif [[ $__result =~ $__regexBLOCKEDYunnanProvince ]]; then
                sendPRIVMSG "$__channel" "$__URLToTest is BLOCKED from Yunnan Province"
            fi

        else
            sendPRIVMSG "$__channel" "Error: the requested URL contains one or more errors, \
                                    please verify that it is a valid URL."
        fi

    elif [[ $? -eq 3 ]]; then
        sendPRIVMSG "$__channel" "Error: malformed URL"

    else
        sendPRIVMSG "$__channel" "Error: could not get any info from China"
    fi
}

# Flatter somebody
# First argument: the channel in which someone should be flattered
# Second argument: the Nick to flatter
flatter()
{
    local __channel=$1
    local __nick=$2

    local __compliment=(
        "You look pretty when you smile"
        "I love your personality"
        "You look lovely tonight"
        "Nice make up"
        "You did a good job!"
        "I really love your car!"
        "You deserve a promotion"
        "I appreciate all of your opinions"
        "I love what you've done with the place"
        "You are like a spring flower; beautiful and vivacious"
        "I find you to be a fountain of inspiration"
        "You have perfect bone structure"
        "I disagree with anyone who disagrees with you"
        "I would love to visit you, but I live on the Internet"
        "I love the way you click"
        "If I freeze, it's not a computer virus. I was just stunned by your beauty"
        "You make my data circuits skip a beat"
        "You could survive a zombie apocalypse"
    )

    local __numberOfCompliments=${#__compliment[*]}
    local __randomIndex=$((RANDOM % $__numberOfCompliments))

    sendPRIVMSG "$__channel" "${__nick}: ${__compliment[$__randomIndex]}"
}

# Show all supported functions
# First argument: the channel to respond to
supportedFunctions()
{
    local __channel=$1

    sendPRIVMSG "$__channel" "Supported functions so far:"
    sendPRIVMSG "$__channel" "convert [hex], e.g. !bashbot convert 0xFF"
    sendPRIVMSG "$__channel" "blocked-in-china URL, e.g. !bashbot blocked-in-china gmail.com"
    sendPRIVMSG "$__channel" "flatter nick"
    sendPRIVMSG "$__channel" "help"
}

# Connect to the IRC-server with the information
# specified in the configuration above.
send "NICK ${USERNAME}"
send "USER ${USERNAME} ${HOSTNAME} ${SERVERNAME} :${REALNAME}"
send "JOIN ${CHANNEL}"

while true; do
    message=$(receive)
    echo "'$message'" | cat -A

    if [[ "$message" =~ ^PING ]]; then
        IFS=' ' pingMessage=($message)
        echo "send PONG ${pingMessage[1]}"
        send "PONG ${pingMessage[1]}"

    elif [[ "$message" =~ ^: ]]; then
        IFS=':' textMessage=($message)

        if [[ "${textMessage[2]}" =~ ^\!bashbot ]]; then
            IFS=' ' privMSGClient=(${textMessage[1]})
            IFS=' ' botCommand=(${textMessage[2]})

            if [[ "${botCommand[1]}" == "convert" && ${#botCommand[*]} -eq 3 ]]; then
                convertHexToDec "${privMSGClient[2]}" "${botCommand[2]}"

            elif [[ "${botCommand[1]}" == "flatter" && ${#botCommand[*]} -eq 3 ]]; then
                flatter "${privMSGClient[2]}" "${botCommand[2]}"

            elif [[ "${botCommand[1]}" == "blocked-in-china" && ${#botCommand[*]} -eq 3 ]]; then
                # Simple URL regex to test against
                URLRegex='^[a-zA-Z0-9.-]{2,256}$'

                if [[ "${botCommand[2]}" =~ $URLRegex ]]; then
                    blockedInChina "${privMSGClient[2]}" "${botCommand[2]}" 
                else
                    sendPRIVMSG "${privMSGClient[2]}" "That URL is too suspicious to test :P"
                fi

            elif [[ "${botCommand[1]}" == "help" && ${#botCommand[*]} -eq 2 ]]; then
                supportedFunctions "${privMSGClient[2]}"

            else
                sendPRIVMSG "${privMSGClient[2]}" "Invalid command: ${textMessage[2]}"
                supportedFunctions "${privMSGClient[2]}"
            fi
        fi
    fi
done
