ListOfNames=$(sudo ls /home/students/cs3812f25/)

NamesArray=($ListOfNames)

for username in "${NamesArray[@]}"
	do
	

		echo 'valid username: '$username ;
		create the ubuntu accounts

		#sudo useradd $username -p $(openssl passwd -crypt $password) --create-home #create the accounts
		
		#sudo usermod -s /bin/bash $username
		
		#sudo chmod o-rwx /home/$username #make sure other people can't access their home
		
		echo "PATH=$"PATH":/usr/local/istanbul-tools/build/bin" | sudo tee -a /home/students/cs3812f25/$username/.bashrc  #&>/dev/null #add quorum, instanbul tools and node/npm to the path

		echo "PATH=$"PATH":/usr/local/quorum/build/bin" | sudo tee -a /home/students/cs3812f25/$username/.bashrc #&>/dev/null

		echo "PATH=$"PATH":/usr/local/node-v16.13.0-linux-x64/bin" | sudo tee -a /home/students/cs3812f25/$username/.bashrc #&>/dev/null

done