#!/bin/bash
# --- 1. BOOTSTRAP VALIDATORS IN BACKGROUND ---
for i in {0..4}
do
    if ! pgrep -f "geth.*2200$i" > /dev/null; then
        echo "Starting consensus infrastructure (Validator Node$i)..."

        cd /home/osboxes/ITB/PA3/scriptSetupV2/blockChain/Node$i

        nohup bash startup.sh >> output.log 2>&1 &
        disown $!
    else
        echo "Consensus infrastructure (Validator Node$i) is already active."
    fi
done

sleep 2

# --- 2. START STUDENT NODE IN FOREGROUND ---
echo "Starting Student Node..."
cd /home/osboxes/ITB/PA3/students/pa3_std/Nodepa3_std
PRIVATE_CONFIG=ignore geth --datadir data --nodiscover \
    --istanbul.blockperiod 5 --syncmode full --mine --miner.threads 1 \
    --verbosity 5 --networkid 10 --http --http.addr 127.0.0.1 \
    --http.port 22005 --http.api admin,eth,debug,miner,net,txpool,personal,web3,istanbul \
    --emitcheckpoints --allow-insecure-unlock --port 33005
