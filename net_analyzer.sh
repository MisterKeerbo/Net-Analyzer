RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m'

echo "Welcome to the network Analyzer!"

option=1
while [ $option != 4 ]
do
    echo "What would you like to do?"
    echo "1 - Analyze servers"
    echo "2 - Scan local network"
    echo "3 - Show logs"
    echo "4 - Exit"
    read option
    if [ $option = 1 ]
    then
        # ==================== Analyze Networks ====================
        echo "Enter servers file:"
        read FILE_NAME

        echo "Number of ping attempts:"
        read PING_ATTEMPTS

        DATE=$(date +%F)
        PORTS=(21 22 80 443 3306)
        ANALYZED_SERVERS=0
        AVAILABLE_SERVERS=0
        DOWN_SERVERS=0
        OPEN_PORTS=0
        FASTEST_SERVER=''
        MIN_LATENCY=10000
        SLOWEST_SERVER=''
        MAX_LATENCY=0

        touch serverResults.txt

        while read server
        do
            (( ANALYZED_SERVERS++ ))
            echo "------------------------"
            echo "------------------------" >> serverResults.txt
            echo "$server: "
            echo "$server: " >> serverResults.txt
            IFS=''
            pingmessage=$(ping $server -c $PING_ATTEMPTS 2> /dev/null)
            if [ $? != 0 ]
            then
                echo -e "${RED}Server is DOWN${NC}"
                echo -e "Server is DOWN" >> serverResults.txt
                (( DOWN_SERVERS++ ))
            else
                echo -e "${GREEN}Server is UP${NC}"
                echo -e "${GREEN}Server is UP${NC}" >> serverResults.txt
                (( AVAILABLE_SERVERS++ ))
                averageLatency=$(echo $pingmessage | grep 'rtt' | awk '{ print $4 }' | cut -d "/" -f 2)
                echo "Average latency: $averageLatency ms"
                echo "Average latency: $averageLatency ms" >> serverResults.txt
                
                latencyIsBigger=$(echo "$averageLatency > $MAX_LATENCY" | bc)
                latencyIsSmaller=$(echo "$averageLatency < $MIN_LATENCY" | bc)
                
                if [ "$latencyIsBigger" = "1" ]
                then
                    MAX_LATENCY=$averageLatency
                    SLOWEST_SERVER=$server
                fi
                if [ "$latencyIsSmaller" = "1" ]
                then
                    MIN_LATENCY=$averageLatency
                    FASTEST_SERVER=$server
                fi


                if [[ $server = *[a-zA-Z] ]]
                then
                    echo -n "IP: "
                    dig +short $server | head -n 1
                    dig +short $server | head -n 1 >> serverResults.txt
                fi

                echo -n "Number of hops: "
                echo -n "Number of hops: " >> serverResults.txt
                traceroute $server | tail -1 | awk '{ print $1 }'
                traceroute $server | tail -1 | awk '{ print $1 }' >> serverResults.txt

                for PORT in ${PORTS[@]}
                do
                    if ( nc -zvw 2 $server $PORT 2> /dev/null )
                    then
                        echo "Port $PORT: OPEN"
                        echo "Port $PORT: OPEN" >> serverResults.txt
                        (( OPEN_PORTS++ ))
                    else
                        echo "Port $PORT: CLOSED"
                        echo "Port $PORT: CLOSED" >> serverResults.txt
                    fi
                done

            fi

            echo
        done < $FILE_NAME

        echo "======= NETWORK REPORT ======="
        echo "Servers analyzed: $ANALYZED_SERVERS"
        echo "Servers UP:       $AVAILABLE_SERVERS"
        echo "Servers DOWN:     $DOWN_SERVERS"
        echo
        echo "Total open ports: $OPEN_PORTS"
        echo
        echo "Fastest server:   $FASTEST_SERVER"
        echo "Slowest server:   $SLOWEST_SERVER"
        echo "=============================="
        
        if [ -f "network-log-$DATE.txt" ]
        then
            fileIndex=1
            while [ -f "network-log-$DATE($fileIndex).txt" ]
            do
                (( fileIndex++ ))
            done
            touch "network-log-$DATE($fileIndex).txt"
            echo "$DATE" > "network-log-$DATE($fileIndex).txt"
            cat $FILE_NAME >> "network-log-$DATE($fileIndex).txt"
            cat serverResults.txt >> "network-log-$DATE($fileIndex).txt"
        else
            touch "network-log-$DATE.txt"
            echo "$DATE" > "network-log-$DATE.txt"
            cat $FILE_NAME >> "network-log-$DATE.txt"
            cat serverResults.txt >> "network-log-$DATE.txt"
        fi


        rm serverResults.txt



        echo "======= NETWORK REPORT =======" >> network-log-$DATE.txt
        echo "Servers analyzed: $ANALYZED_SERVERS" >> network-log-$DATE.txt
        echo "Servers UP:       $AVAILABLE_SERVERS" >> network-log-$DATE.txt
        echo "Servers DOWN:     $DOWN_SERVERS" >> network-log-$DATE.txt
        echo >> network-log-$DATE.txt
        echo "Total open ports: $OPEN_PORTS" >> network-log-$DATE.txt
        echo >> network-log-$DATE.txt
        echo "Fastest server:   $FASTEST_SERVER" >> network-log-$DATE.txt
        echo "Slowest server:   $SLOWEST_SERVER" >> network-log-$DATE.txt
        echo "==============================" >> network-log-$DATE.txt
    
    elif [ $option = 2 ]
    then
        # ==================== Scan local network ====================
        echo "Responding IPs:"
        for i in {1..254}
        do
            ping -c 1 -W 1 192.168.1.$i | grep "64 bytes" | awk '{print $4}' | tr -d ':' &
        done; wait
           


    elif [ $option = 3 ]
    then
        # ==================== Show logs ====================
        ls | grep "network-log"
        read -p "Choose a log date:(YYYY-MM-DD) " Date
        fileCount=$(ls | grep -c "network-log-$Date")
        if [ $fileCount -gt 1 ]
        then
            read -p "Which log? " logNumber
            if [ -f "network-log-$Date($logNumber).txt" ]
            then
                cat "network-log-$Date($logNumber).txt"
            elif [ $logNumber = "0" ]
            then
                if [ -f "network-log-$Date.txt" ]
                then
                    cat "network-log-$Date.txt"
                else
                    echo -e "${YELLOW}File doesn't exist: network-log-$Date.txt${NC}"
                fi
            else
                echo -e "${YELLOW}File doesn't exist: network-log-$Date($logNumber).txt${NC}"
            fi
        else
            if [ -f "network-log-$Date.txt" ]
            then
                cat "network-log-$Date.txt"
            else
                echo -e "${YELLOW}File doesn't exist: network-log-$Date.txt${NC}"
            fi
        fi

    elif [ $option = 4 ]
    then
        echo "Goodbye"
    else
        echo -e "${YELLOW}Please enter a valid number.${NC}"
    fi

done
