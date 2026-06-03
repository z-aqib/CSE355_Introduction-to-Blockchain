#!/bin/bash






#ask for number of validator nodes
#echo 'How many validator nodes do you need? '
#read N
N=5

#ask for number of accounts
#echo 'How many accounts in each non-validator node?'
#read accountsNum #should be 12
accountsNum=12;

ListOfNames="";

ListOfNames=$(sudo ls /home/osboxes/ITB/PA3/students)

NamesArray=($ListOfNames)

for username in "${NamesArray[@]}"
	do


		echo 'valid username: '$username ;
		#create the ubuntu accounts

		#sudo useradd $username -p $(openssl passwd -crypt $password) --create-home #create the accounts

		#sudo usermod -s /bin/bash $username

		#sudo chmod o-rwx /home/$username #make sure other people can't access their home

		echo "PATH=$"PATH":/usr/local/istanbul-tools/build/bin" | sudo tee -a /home/osboxes/ITB/PA3/students/$username/.bashrc  #&>/dev/null #add quorum, instanbul tools and node/npm to the path

		echo "PATH=$"PATH":/usr/local/quorum/build/bin" | sudo tee -a /home/osboxes/ITB/PA3/students/$username/.bashrc #&>/dev/null

		echo "PATH=$"PATH":/usr/local/node-v16.13.0-linux-x64/bin" | sudo tee -a /home/osboxes/ITB/PA3/students/$username/.bashrc #&>/dev/null

done






#make the validator nodes
mkdir blockChain
cd blockChain

istanbul setup --num $N --nodes --quorum --save --verbose  &>/dev/null

port=33000;
httpport=22000;

for  (( i=0; i<$N;i++))
do

	echo "creating validator Node$i";
	#make a folder with this node
	mkdir -p Node$i/data
	cp $i/nodekey Node$i/data/nodekey
	rm -r $i
	#make an account in data
	geth account new --password <(echo $i) --datadir Node$i/data/ &>/dev/null
	accountfile=$(ls Node$i/data/keystore/)
	accountAddress=$(jq '.address' Node$i/data/keystore/$accountfile)

	#now add this account to the genesis.json file
	contents="$(jq --arg accountAddress "$accountAddress" -c '.alloc+={'$accountAddress':{"balance":"0x446c3b15f9926687d2c40534fdb564000000000000"}}' genesis.json)"
	echo "${contents}" > genesis.json

	#now edit static-nodes.json to make sure the i'th entry has the right port
	enode=$(jq '.['$i']' static-nodes.json)
	mainString=${enode/0.0.0.0:30303/127.0.0.1:$port}
	port=$((port+1))

	contents="$(jq '.['$i'] ='$mainString static-nodes.json)"
	echo "${contents}" > static-nodes.json

done


#make the non-validator nodes

mkdir NVnodes

cp ../usernames.txt NVnodes/usernames.txt

cd NVnodes

for username in "${NamesArray[@]}"
	do

		echo "creating non-validator Node$username";
		#create non-validor node with the name being nodeUsername
		mkdir -p ../Node$username/data
		istanbul setup --nodes --num 1 --verbose --quorum --save &>/dev/null
		cp 0/nodekey ../Node$username/data/nodekey


		#edit static-nodes.json to have the correct ip and port
		enode=$(jq '.[0]' static-nodes.json)
		mainString=${enode/0.0.0.0:30303/127.0.0.1:$port}
		port=$((port+1))

		contents="$(jq '.[0] ='$mainString static-nodes.json)"
		echo "${contents}" > static-nodes.json

		#copy and append this static-nodes.json to the original static-nodes.json
		contents=$(jq  -s add  ../static-nodes.json static-nodes.json)
		echo "${contents}" > ../static-nodes.json

		#cp static-nodes.json ../Node$username/data/

		rm -r 0


		#make a new account and add that to genesis.json as well
		for ((i=0;i<$accountsNum;i++))
		do
			echo -en "\r account number:$((i+1))/$accountsNum"
			#I want a password that is different from the ubuntu password so I am currently keeping it as the first 6 characters of $password's md5hash (or sumthing..get it?)
			hash=$(echo -n "$password" | md5sum | awk '{print $1}')
			hash="${hash::6}"

			geth account new --password <(echo $hash) --datadir ../Node$username/data &>/dev/null
			#accountfile=$(ls ../Node$username/data/keystore)
			accountfileArray=($(ls ../Node$username/data/keystore))


			accountfile=${accountfileArray[$i]};

			accountAddress=$(jq '.address' ../Node$username/data/keystore/$accountfile);

			contents="$(jq --arg accountAddress "$accountAddress" -c '.alloc+={'$accountAddress':{"balance":"0x8AC7230489E80000"}}' ../genesis.json)"
		echo "${contents}" > ../genesis.json
		done
	echo -en "\n"

done



for username in "${NamesArray[@]}"
	do

	cp ../static-nodes.json ../Node$username/data/ #copy the static-nodes.json with the data of all nodes into each of the usernodes

done
cd ..
rm -r NVnodes

#do the same for all the validator nodes (copy static-nodes.json)

for  (( i=0; i<$N;i++))
do
	cp static-nodes.json Node$i/data/static-nodes.json
done

#now, as the genesis.json file and static-nodes.json files are all finalized, let's initialize the blockchain and also create start-up scripts for later


#to do
#initialize all the blockchain
#make a start-up script for each


port=33000
httpport=22000


echo 'initializing the nodes'

#initialize the validator nodes
for  (( i=0; i<$N;i++))
do

	#also copy the static-nodes file
	cp static-nodes.json Node$i/data/static-nodes.json

	#initialize the node
	echo "initializing Node$i"
	#cp ../startPy.py Node$i/startPy.py
	cp genesis.json Node$i/genesis.json
	cd Node$i
	geth --datadir data init ./genesis.json &>/dev/null

	#make the script

	echo "PRIVATE_CONFIG=ignore geth --datadir data --nodiscover --istanbul.blockperiod 5 --syncmode full --mine --miner.threads 1 --verbosity 5 --networkid 10 --http --http.addr 127.0.0.1 --http.port $httpport --http.api admin,eth,debug,miner,net,txpool,personal,web3,istanbul --emitcheckpoints --allow-insecure-unlock --port $port 2>> output.log" > startup.sh
	cd ..
	port=$((port+1))
	httpport=$((httpport+1))
done




#initialize the non-validator nodes


for username in "${NamesArray[@]}"
	do
	#initialize the node
	echo "initializing Node$username"

	#cp ../startPy.py Node$username/startPy.py
	cp genesis.json Node$username/genesis.json
	cd Node$username
	geth --datadir data init ./genesis.json &>/dev/null

	#make the script
	echo "PRIVATE_CONFIG=ignore geth --datadir data --nodiscover --istanbul.blockperiod 5 --syncmode full --mine --miner.threads 1 --verbosity 5 --networkid 10 --http --http.addr 127.0.0.1 --http.port $httpport --http.api admin,eth,debug,miner,net,txpool,personal,web3,istanbul --emitcheckpoints --allow-insecure-unlock --port $port" > startup.sh
	cd ..

	port=$((port+1))
	httpport=$((httpport+1))

	#copy the folder to the appropriate directory
	sudo cp -r Node$username /home/osboxes/ITB/PA3/students/$username/Node$username



	#copy the contracts folder
	sudo cp -r ../contracts /home/osboxes/ITB/PA3/students/$username/contracts/

	#create a web3.json file which has the current working directory of the users and a password

	hash=$(echo -n "$password" | md5sum | awk '{print $1}')
	hash="${hash::6}"

	pathToIPC=/home/osboxes/ITB/PA3/students/$username/Node$username/data/geth.ipc
	echo $(jq --null-input '{"location":"'$pathToIPC'" ,"password":"'$hash'"}') > web3data.json
	sudo cp web3data.json /home/osboxes/ITB/PA3/students/$username/contracts/web3data.json

	#give permission to that user to edit their own files
	sudo setfacl -m u:$username:rwx -R /home/osboxes/ITB/PA3/students/$username
	#and to us
	sudo setfacl -m u:$(whoami):rwx -R /home/osboxes/ITB/PA3/students/$username


done

#start the validator nodes
echo 'Starting the nodes'
for  (( i=0; i<$N;i++))
do
	echo "starting Node$i"
	cd Node$i
	bash startup.sh &
	cd ..
done


#to do
#put the location of each usernode into a json file called "location.json" and save it in the contracts directory for each person
#rewrite all the javascript files


