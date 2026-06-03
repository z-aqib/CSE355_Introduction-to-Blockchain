#!/bin/bash

ListOfNames=$(sudo ls  /home/osboxes/ITB/PA3/students)

NamesArray=($ListOfNames)


for username in "${NamesArray[@]}"
do
	echo 'deleting: '$username

	sudo rm -r  /home/sysadmin/ITB/PA3/students/$username/contracts
	sudo rm -r  /home/sysadmin/ITB/PA3/students/$username/Node$username
done


echo 'killing geth'
pkill -f geth

#delete the blockchain
echo 'deleting the blockchain nodes'
sudo rm -r blockChain
