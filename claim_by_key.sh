#!/bin/bash

# bp account
BP=eosbeijingbp
# private key
PRIVATE_KEY=
# private key permission
PERMISSION=claimer

# env
NODEOS_BIN_DIR='/ebs/eos/build/programs'
WALLET_HOST='127.0.0.1:3000'
NODE_HOST='127.0.0.1:8880'
CLEOS="$NODEOS_BIN_DIR/cleos/cleos -u http://$NODE_HOST --wallet-url http://$WALLET_HOST"

# step 1: wait until 24 hours from last claim
last_claim_time=`$CLEOS get table eosio eosio producers -l 1000 | jq -r '.rows[] | select(.owner == "'$BP'") | .last_claim_time'`
now=`date +%s%N`
diff=`expr $last_claim_time / 1000000 + 24 \* 3600 - $now / 1000000000 + 1`
echo "wait for ${diff}s"
sleep $diff

# step 2: create new wallet and import key
mkdir -p ~/eosio-wallet
rm -rf ~/eosio-wallet/*
WALLET_RESULT=`$CLEOS wallet create -n claim`
$CLEOS wallet import -n claim --private-key $PRIVATE_KEY

# step 3: claim rewards
$CLEOS push action eosio claimrewards "{\"owner\":\"$BP\"}" -p $BP@$PERMISSION
if [ $? -eq 0 ]; then
    echo 'claimed at ' `date`
else
    echo 'failed to claim at ' `date`
fi

# step 5: clean
$CLEOS wallet stop
rm -rf ~/eosio-wallet/*
history -c
history -w