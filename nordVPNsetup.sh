#!/bin/bash

#bind this command to a key:
#gnome-terminal -- /home/az/data/code/scripts/nordVPNsetup.sh
#(e.g.: xfce4-terminal -- ... etc.)
SCRIPTPATH="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

connect(){
    if nordvpn connect $COUNTRIE; then
        nordvpn set killswitch enable;
    fi
}

disconnect(){
    if nordvpn disconnect; then
        nordvpn set killswitch disable;
    fi
}

reconnect(){
    nordvpn disconnect;
    nordvpn connect;
}

selectCountrie(){
    nordvpn countries;
    echo
    read -e -p "Select Countrie: " COUNTRIE
    if nordvpn connect $COUNTRIE; then
        nordvpn set killswitch enable;
    fi
}

setCountrie(){
    nordvpn countries;
    echo
    read -e -p "Set Countrie: " COUNTRIE
    echo $COUNTRIE > $SCRIPTPATH/countrieSetting.txt
    echo "Countrie set to $COUNTRIE."
    COUNTRIESET=1
}

forceRestartNetwork(){
    if sudo service network-manager restart; then
        until wget -q --spider http://google.com; do
            sleep 0.5;
        done 
        sleep 1;
        echo "Network succesfully restarted!"
    else
        echo "Network restart aborted!"
    fi
}

restartNetwork(){
    if ! wget -q --spider http://google.com; then
        forceRestartNetwork
    else
        echo "Restart not necessary. Network already connected!"
    fi
}

getStatus(){
    CONNECTION=$(nordvpn status | grep Status:)  # get connection status.
    KILLSWITCH=$(nordvpn settings | grep Kill)  # get killswitch status.
}


DONE=0  # is set to 1 after first loop. Used to set default value for INPUT to 'q' for quit.
SKIPDONE=0  # is set to 1 to prevent DONE from being set to 1 when [a]uto command was chosen.
PREVIOUSIP=0  # IP before commands are run.
NEWIP=0  # IP after commands are run.
COUNTRIESET=0  # is set to 1 after a new countrie was set.
COUNTRIE=$(<$SCRIPTPATH/countrieSetting.txt)


#  ----- MAIN-function -----
echo -e "\nNORD VPN SETUP"
while true; do

    # get status
    getStatus

    # print status
    echo -e "\n--------------------"
    echo -e "$CONNECTION\n$KILLSWITCH"
    
    # get prevIP and print IP
    if [ "${KILLSWITCH:13:7}" = "enabled" ] && [ "${CONNECTION:14:9}" != "Connected" ] ; then  # if killswitch is enabeld but connection is not established.
        echo -e "\nkillswitch enabled but not connected!"
    else
        if IP=$(wget -O - -q https://checkip.amazonaws.com;); then
            if [ "$PREVIOUSIP" != "$NEWIP" ]; then
                echo -e "\nprevious IP: $PREVIOUSIP\nnew IP: $NEWIP"
            else
                echo -e "\nIP: $IP"
            fi
            PREVIOUSIP=$IP
        else
            echo -e "\n IP error."
            PREVIOUSIP="\n prevIP error."
        fi
    fi

    echo -e "--------------------\n"

    # print options
    echo -e "Options: [c]onnect | [d]isconnect | [r]econnect | [t]emporarily select Countrie | [s]et countrie | restart [n]etwork | [f]orce network restart"
    echo -e "         [k]illswitch on | killswitch [o]ff | [a]uto | [h]elp | [q]uit\n"

    # Input (determine default Input value)
    if [ "${KILLSWITCH:13:8}" = "disabled" ] && [ "${CONNECTION:14:9}" = "Connected" ] ; then  # 'kn' if killswitch is disabled but connection is established.
            read -e -p "Command: " -i "kn" INPUT
        
    elif [ "$COUNTRIESET" = "1" ]; then  # 'cn' if a new Countrie was set.
        read -e -p "Command: " -i "cn" INPUT
        COUNTRIESET=0

    elif [ "${KILLSWITCH:13:7}" = "enabled" ] && [ "${CONNECTION:14:9}" != "Connected" ] ; then  # 'cn' if killswitch is enabled but connection is not established.
        read -e -p "Command: " -i "cn" INPUT

    elif [ $DONE -eq 1 ]; then  # 'q' if already DONE with first loop.
        read -e -p "Command: " -i "q" INPUT

    elif [ "${CONNECTION:14:9}" = "Connected" ] ; then #  'dn' if already connected.
        read -e -p "Command: " -i "dn" INPUT

    else  # 'cn' if not connected yet.
        read -e -p "Command: " -i "cn" INPUT
    fi

    clear
    echo "INPUT: $INPUT"

    # reset
    DONE=0
    SKIPDONE=0

    for (( n=0; n<=${#INPUT}-1; n++ ));do  # for every character in Input

        case ${INPUT:$n:1} in  # select
            
            c)  # [c]onnect
                echo -e "\n--[c]onnect"
                connect
                ;;

            d)  # [d]isconnect
                echo -e "\n--[d]isconnect"
                disconnect
                ;;
            
            r)  # [r]econnect
                echo -e "\n--[r]econnect";
                reconnect
                ;;

            t)  # [t]emporarily select Countrie
                echo -e "\n--[t]emporarily select Countrie";
                selectCountrie
                ;;

            s)  # [s]et Countrie
                echo -e "\n--[s]etCountrie";
                setCountrie
                ;;

            n)  # restart [n]etwork
                echo -e "\n--restart [n]etwork";
                restartNetwork
                ;;

            f)  # [f]orce Network restart
                echo -e "\n--[f]orce Network restart";
                forceRestartNetwork
                ;;

            k)  # [k]illswitch on
                echo -e "\n--[k]illswitch on"
                nordvpn set killswitch enable;
                ;;

            o)  # killswitch [o]ff
                echo -e "\n--killswitch [o]ff"
                nordvpn set killswitch disable;
                sleep 1;
                ;;
            
            a)  # [a]uto: suggest next best command instead of [q]uit.
                echo -e "\n--[a]uto\nsuggesting a command.."
                SKIPDONE=1
                ;;

            h)  # [h]elp
                if [ "${#INPUT}" = "1" ]; then  # help is only given if the command was run on its own.
                    echo -e "\n--[h]elp\nThis program will always suggest a command.\nYou can still choose to enter another command.\nMultiple commands will be combined. They will be executed in order.\n\nExample:\n'drcs' will [d]isconnect then [r]estart Network, [c]onnect and show [s]tatus.\n\nYou can also use [a]uto to suggest a command."
                    SKIPDONE=1
                else
                    echo -e "\n--[h]elp\nRun this command ond its own to get an description of this program."
                fi
                ;;

            q)  # [q]uit
                echo -e "\n[q]uit"
                sleep 0.3;
                break 2
                ;;

            *)  # Unknown Input
                echo -e "\n--[${INPUT:$n:1}]: Unknown Input"
                continue
                ;;    
        esac
    done
    
    # set DONE to 1 after any loop
    if [ $SKIPDONE -eq 0 ]; then  # gets skipped if [a]uto was chosen or if [h]elp was run on its own.
        DONE=1
    fi

    # get status
    getStatus

    # get newIP
    if [ "${KILLSWITCH:13:7}" = "enabled" ] && [ "${CONNECTION:14:9}" != "Connected" ] ; then  # if killswitch is enabled but connection is not established.
        NEWIP="newIP error."
    else
        if IP=$(wget -O - -q https://checkip.amazonaws.com;); then
            NEWIP=$IP
        fi
    fi
done
