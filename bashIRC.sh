#!/bin/bash
#Simple IRC-bot that serves as an example how bash
#can be used in network programming. However this
#should only been seen as an experiment as more
#robust functionality can be achived using e.g.
#Python or Java instead.
#For detailed descriptions about the protocol used, 
#see https://tools.ietf.org/html/rfc1459

FD="3"
USERNAME="botname"
HOSTNAME="bothostname"
REALNAME="botrealname"
SERVERNAME="subdomain.example.com"
PORT=6667
CHANNEL="#mychannel"

exec 3<>/dev/tcp/${SERVERNAME}/${PORT}

# Send text on the opened socket
send()
{
    messageToSend=$1
    echo "$messageToSend" >&${FD}
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

            if [[ "${botCommand[1]}" == "convert" ]]; then
                send "PRIVMSG ${privMSGClient[2]} :Validating convert syntax ..."

                if [[ "${botCommand[2]}" =~ ^0x[[:xdigit:]]+$ ]]; then
                    
                    if [[ ${#botCommand[2]} -gt 17 ]]; then
                        send "PRIVMSG ${privMSGClient[2]} :I do not allow buffer overflows :P"
                    else
                        send "PRIVMSG ${privMSGClient[2]} :Correct convert syntax"
                        send "PRIVMSG ${privMSGClient[2]} :${botCommand[2]} in decimal is $((${botCommand[2]}))"
                    fi

                else
                    send "PRIVMSG ${privMSGClient[2]} :Invalid convert syntax"
                fi

            else
                send "PRIVMSG ${privMSGClient[2]} :Invalid command: ${textMessage[2]}"
                send "PRIVMSG ${privMSGClient[2]} :Supported functions so far:"
                send "PRIVMSG ${privMSGClient[2]} :convert [hex], e.g. !bashbot convert 0xFF"
            fi
        fi
    fi
done
