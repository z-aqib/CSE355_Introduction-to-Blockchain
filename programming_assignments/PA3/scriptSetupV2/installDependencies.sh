#!/bin/bash

myDir=$(pwd)

#install git
echo 'installing git'
sudo apt-get install git 

#install golang
echo 'installing golang'
sudo apt-get install golang 

#install make
echo 'installing make'
sudo apt-get install make 

#install jq to edit json files in bash
echo 'installing jq'
sudo apt install jq 


#install geth
echo 'installing geth'
git clone https://github.com/ConsenSys/quorum.git
cd quorum &>/dev/null
make all
cd ..

sudo cp -r quorum /usr/local/quorum

cd /usr/local

echo "PATH=$"PATH:$(pwd)"/quorum/build/bin" | sudo tee -a ~/.bashrc

PATH=$PATH:/usr/local/quorum/build/bin

#install istanbul-tools
cd $myDir
git clone https://github.com/ConsenSys/istanbul-tools.git
cd istanbul-tools
make

cd ..

sudo cp -r istanbul-tools /usr/local/istanbul-tools


cd /usr/local


echo "PATH=$"PATH:$(pwd)"/istanbul-tools/build/bin" | sudo tee -a ~/.bashrc

PATH=$PATH:/usr/local/istanbul-tools/build/bin

#install nodejs and npm
cd $myDir
wget https://nodejs.org/dist/v16.13.0/node-v16.13.0-linux-x64.tar.xz
sudo tar -xf $myDir/node-v16.13.0-linux-x64.tar.xz
rm node-v16.13.0-linux-x64.tar.xz
sudo cp -r node-v16.13.0-linux-x64 /usr/local/node-v16.13.0-linux-x64
echo "PATH=$"PATH":/usr/local/node-v16.13.0-linux-x64/bin" | sudo tee -a ~/.bashrc
source ~/.bashrc

PATH=$PATH:/usr/local/node-v16.13.0-linux-x64/bin


#make a contracts folder that will have solc and web3 installed
mkdir contracts &>/dev/null
cd contracts



echo 'you should probably restart the terminal (or source ~/.bashrc )'
