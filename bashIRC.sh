#!/bin/bash
# Simple IRC-bot that serves as an example how bash
# can be used in network programming. However this
# is only an experiment and more robust functionality
# can be achived using e.g. Python or Java instead.
# For detailed descriptions about the protocol used, 
# see https://tools.ietf.org/html/rfc1459

FD="3"
USERNAME="botname"
HOSTNAME="bothostname"
REALNAME="botrealname"
SERVERNAME="subdomain.example.com"
PORT=6667
CHANNEL="#mychannel"

exec 3<>/dev/tcp/${SERVERNAME}/${PORT}

# Send text on the opened socket
# First argument: the text to send
send()
{
    messageToSend=$1
    echo "$messageToSend" >&${FD}
}

# Send a PRIVMSG
# First argument: the channel to send to
# Second argument: the message to send
sendPRIVMSG()
{
    local channel=$1
    local message=$2

    send "PRIVMSG $channel :$message"
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
    local channel=$1
    local hexToConvert=$2

    sendPRIVMSG "$channel" "Validating convert syntax ..."

    if [[ "$hexToConvert" =~ ^0x[[:xdigit:]]+$ ]]; then
        
        if [[ ${#hexToConvert} -gt 17 ]]; then
            sendPRIVMSG "$channel" ":I do not allow buffer overflows :P"
        else
            sendPRIVMSG "$channel" ":Correct convert syntax"
            sendPRIVMSG "$channel" ":$hexToConvert in decimal is $(($hexToConvert))"
        fi

    else
        sendPRIVMSG "$channel" ":Invalid convert syntax"
    fi
}

# Flatter Rolle
# First argument: the channel in which Rolle should be flattered
flatterRolle()
{
    local channel=$1

    local compliment=(
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

    local numberOfCompliments=${#compliment[*]}
    local randomIndex=$((RANDOM % $numberOfCompliments))

    sendPRIVMSG "$channel" "R0113: ${compliment[$randomIndex]}"
}

# Show all supported functions
# First argument: the channel to respond to
supportedFunctions()
{
    local channel=$1

    sendPRIVMSG "$channel" "Supported functions so far:"
    sendPRIVMSG "$channel" "convert [hex], e.g. !bashbot convert 0xFF"
    sendPRIVMSG "$channel" "flatter"
    sendPRIVMSG "$channel" "help"
}

# Connect to the IRC-server with the information
# specified in the configuration above.
send "NICK ${USERNAME}"
send "USER ${USERNAME} ${HOSTNAME} ${SERVERNAME} :${REALNAME}"
send "JOIN ${CHANNEL}"

while true; do
    message=$(receive)
    echo "'$message'" | cat -A

    # =~ Is a new feature that enables one to use
    # extended POSIX-regex in bash directly.
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

            elif [[ "${botCommand[1]}" == "flatter" && ${#botCommand[*]} -eq 2 ]]; then
                flatterRolle "${privMSGClient[2]}"

            elif [[ "${botCommand[1]}" == "help" && ${#botCommand[*]} -eq 2 ]]; then
                supportedFunctions "${privMSGClient[2]}"

            else
                sendPRIVMSG "${privMSGClient[2]}" "Invalid command: ${textMessage[2]}"
                supportedFunctions "${privMSGClient[2]}"
            fi
        fi
    fi
done
