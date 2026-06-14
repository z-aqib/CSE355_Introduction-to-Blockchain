import re
from logging.config import valid_ident
import time
import pickle
from Block import Block
import os
from hashing import *
import datetime
import json
from util import *
from network import Node
import sys
import copy
import shutil

"""
Establishing connection with backend
"""


class FullNode:
    def __init__(self, id):
        """
		DO NOT EDIT
		"""
        self.DIFFICULTY = 4  # Difficulty setting
        self.STUDENT_ID = id  # Do not edit, this is your student ID

        self.unconfirmed_transactions = []  # Raw 5 TXNs that you will get from the mempool
        self.all_unconfirmed_transactions = []  # all Raw unconfirmed txns from mempool
        self.valid_but_unconfirmed_transactions = {}
        self.valid_chain, self.confirmed_transactions = load_valid_chain()  # Your valid chain, all the TXNs in that valid chain
        self.corrupt_transactions = {}  # Initialize known invalid TXNs. To be appended to (by you, later). These are transactions whose signatures don't match or their output > input
        self.UTXO_Database_Pending = {}  # This is a temporary UTXO database you may use.
        self.UTXO_Database = {}

    def last_block(self):
        """
		DO NOT EDIT
		returns last block of the valid chain loaded in memory
		"""
        self.valid_chain.sort(key=self.sortHelper)
        return self.valid_chain[-1]

    ## PART ONE ##

    def verifyTransaction(self, Tx):

        UTXO_Database_temp = copy.deepcopy(self.UTXO_Database_Pending)

        # first confirm whether the current Tx's hash matches that which is in Tx.id
        if not Tx['id'] == calculateHash(stringifyTransaction(Tx)):
            return False

        totalValue = 0  # crypto received

        if Tx['COINBASE']:
            if not Tx['id'] in UTXO_Database_temp.keys():
                totalValue += 5e9
                UTXO_Database_temp[Tx[
                    'id']] = True  # Just to ensure that a coinbase transaction is not added to the UTXO database every time
            else:
                return False

        # initially, verify ALL the signatures in this transaction assuming the public key is relevant
        for inp in Tx['inputs']:
            parentTxHash = inp[0]
            thisTxHash = calculateHash(stringifyTransactionExcludeSig(Tx))
            StringToMatch = str(parentTxHash) + ":" + str(thisTxHash)

            if not VerifySignature(StringToMatch, inp[2], inp[3]):
                return False

            # Now, find the parent UTXO and verify whether one with hash(inp[3]) exists. If so, fetch it
            if not hashPubKey(inp[3]) in UTXO_Database_temp.keys():
                return False

            found = False

            for (tx_hash, output_no, val) in UTXO_Database_temp[hashPubKey(inp[3])]:
                if tx_hash == parentTxHash and inp[1] == output_no:
                    totalValue += val
                    UTXO_Database_temp[hashPubKey(inp[3])].remove((tx_hash, output_no, val))
                    found = True
                    break

            if not found:
                return False

        totalSent = 0

        outp_number = 0
        for outp in Tx['outputs']:
            totalSent += outp[0]

            if not outp[1] in UTXO_Database_temp.keys():
                UTXO_Database_temp[outp[1]] = []

            UTXO_Database_temp[outp[1]].append((Tx['id'], outp_number, outp[0]))
            outp_number += 1

        if totalSent > totalValue:
            self.corrupt_transactions[Tx['id']] = True
            return False

        # If this transaction is valid, update the PENDING utxo database
        self.UTXO_Database_Pending = copy.deepcopy(UTXO_Database_temp)
        return True

    def findValidButUnconfirmedTransactions(self):
        # find 5 valid transactions that are NOT in a block yet

        # initialize as empty
        self.valid_but_unconfirmed_transactions = {}  # These transactions will go into a block to be mined

        found = 0
        lookFor = 5
        for k in range(0, len(self.unconfirmed_transactions)):
            Tx = self.unconfirmed_transactions[k]
            if self.verifyTransaction(Tx):
                found += 1
                self.valid_but_unconfirmed_transactions[Tx['id']] = Tx
            if found == lookFor:
                break
        return

    # Mine Blocks -- skip genesis block
    def mine(self, startingNonce=0, update=True):
        # self.update_UTXO()
        if update:
            self.update_UTXO()
            self.UTXO_Database_Pending = copy.deepcopy(self.UTXO_Database)
            print(f'Updating UTXO database from valid chain of length {len(self.valid_chain)}')

        addTxnToBlock = []
        if update:
            self.findValidButUnconfirmedTransactions()
        for keys, values in self.valid_but_unconfirmed_transactions.items():
            addTxnToBlock.append(values)
            print(f'Adding Txn {values["number"]}')

        lastBlock = self.last_block()

        print("Previous block hash was: ", self.computeBlockHash(lastBlock))

        dateformat = str(int(time.time()))

        if not lastBlock.index:
            NewBlock = Block(1, addTxnToBlock, dateformat, self.computeBlockHash(lastBlock), self.STUDENT_ID,
                             startingNonce)
        else:
            NewBlock = Block(lastBlock.index + 1, addTxnToBlock, dateformat, self.computeBlockHash(lastBlock),
                             self.STUDENT_ID, startingNonce)

        ## POW ##
        Found, startingNonce = self.proof_of_work(NewBlock)

        if not Found:
            return NewBlock.nonce
        else:
            print("block hash found")
        # Add block to valid chain
        self.valid_chain.append(NewBlock)
        # Save block to physical memory here.
        # Syntax to store block: save_object(new_block,"valid_chain/block{}.block".format(new_block.index))
        save_object(NewBlock, "valid_chain/block{}.block".format(NewBlock.index))

        print(self.computeBlockHash(NewBlock), NewBlock.index)

        self.UTXO_Database = copy.deepcopy(
            self.UTXO_Database_Pending)  # Update the UTXO database IFFFFF this block gets mined

        return 0

    def proof_of_work(self, block):
        """
		This method performs proof of work on the given block.
		Iterates a nonce value,
		which gives a block hash that satisfies PoW dificulty condition.
		"""
        computed_hash = self.computeBlockHash(block)

        counter = 0

        # Check for leading zeros according to self.difficulty and add strategy for selecting next nonce to check here
        target = "0".rjust(self.DIFFICULTY, '0')
        while computed_hash[0:(self.DIFFICULTY)] != target or block.nonce % 10 != 0:
            block.nonce += 1
            computed_hash = self.computeBlockHash(block)
            counter += 1
            if counter >= 5000:
                return 0, block.nonce
        # Return the hash and the nonce value you found
        return computed_hash, block.nonce

    def computeBlockHash(self, block):  # Compute the aggregate transaction hash.
        block_string = json.dumps(block.__dict__, sort_keys=True)
        return sha256(block_string.encode()).hexdigest()

    def sortHelper(self, block):
        return block.index

    def sortHelperNumber(self, Tx):
        return Tx['number']

    def update_UTXO(self, till=-1):
        # Update your UTXO database according to your VALID_CHAIN folder.

        MAIN_DIR = "valid_chain"
        DIR = MAIN_DIR + "/"
        block_indexes = [name for name in os.listdir(DIR) if os.path.isfile(os.path.join(DIR, name))]
        temp_chain = []
        block_indexes.sort()
        for block_index in block_indexes:
            try:
                with open(DIR + '/{}'.format(block_index), 'rb') as inp:
                    block = pickle.load(inp)
                    temp_chain.append(block)
            except:
                pass

        self.UTXO_Database_Pending = {}

        if till < 0:
            till = len(temp_chain)
        temp_chain.sort(key=self.sortHelper)

        for block in temp_chain:
            if not block.index:
                continue
            if block.index > till:
                break
            for Tx in block.transactions:
                self.verifyTransaction(Tx)

        self.UTXO_Database = copy.deepcopy(self.UTXO_Database_Pending)
        return

    def showAccounts(self):
        """return a dictionary with mapping from pubkeyHash to total crypto available
		Uses the PENDING UTXO database
		"""

        balance = {}

        # self.update_UTXO()
        circulation = 0

        for pubkeyHash, listOfUTXOs in self.UTXO_Database_Pending.items():

            totalVal = 0
            if type(listOfUTXOs) is list:
                for UTXO in listOfUTXOs:
                    if type(UTXO) is tuple:
                        tx_hash, output_no, val = UTXO
                        totalVal += val
            if totalVal:
                print(pubkeyHash, totalVal)
            circulation += totalVal

            balance[pubkeyHash] = totalVal

        print("circulation: ", circulation / 1e8)

        return balance

    ## PART TWO ##

    def validate_pending_chains(self):
        """
		DO NOT EDIT
		This method loads pending chains from the 'pending_chains' folder.
		It then calls verify_chain method on each chain performing a series of validity checks
		if all the tests pass, it replaces the current valid chain with pending chain and saves it in valid chain folder.
		"""
        Found = False

        self.valid_chain, self.confirmed_transactions = load_valid_chain()
        MAIN_DIR = "pending_chains"
        subdirectories = [name for name in os.listdir(MAIN_DIR) if os.path.isdir(os.path.join(MAIN_DIR, name))]
        if not subdirectories:
            print("No pending chains found to validate.")
            return False
        for directory in subdirectories:
            temp_chain = []
            DIR = MAIN_DIR + "/" + directory
            block_indexes = [name for name in os.listdir(DIR) if os.path.isfile(os.path.join(DIR, name))]
            block_indexes.sort(key=lambda x: int(re.search(r'\d+', x).group()))
            for block_index in block_indexes:
                try:
                    with open(DIR + '/{}'.format(block_index), 'rb') as inp:
                        block = pickle.load(inp)
                        temp_chain.append(block)
                except:
                    pass
            last_block_index = temp_chain[0].index - 1
            if last_block_index >= len(self.valid_chain):
                print(f'last_block_index {last_block_index} >= len(self.valid_chain) {len(self.valid_chain)} ?')
                print("Rejected chain from", directory)
                shutil.rmtree(DIR, ignore_errors=True)
                continue

            last_block_hash = self.computeBlockHash(self.valid_chain[last_block_index])
            current_longest = self.valid_chain[:last_block_index + 1] + temp_chain
            if (self.verify_chain(current_longest, temp_chain, last_block_hash)):
                print("Replaced valid chain with chain from", directory)
                self.valid_chain = current_longest
                save_chain(current_longest)
                self.valid_chain, self.confirmed_transactions = load_valid_chain()
                Found = True
            else:
                print("Rejected chain from", directory)
            shutil.rmtree(DIR, ignore_errors=True)

        if not Found:
            print("No pending chain replaced your current valid chain.")
        return Found

    def verify_chain(self, current_longest, temp_chain, last_block_hash):
        """
		This method performs the following validity checks on the input temp, or pending, chain.
			- whether length of temp_chain is greater than current valid chain (consider checking indexes)
			- whether previous hashes of blocks correspond to calculated block hashes of previous blocks
			- whether the difficulty setting has been achieved
			- whether each transaction is valid
				- no two or more transactions have same id
				- the signature in transaction is valid
				- The UTXO calculation is correct (input = sum of outputs)
		Return True if all is good
		Return False if failed any one of the checks

		temp_chain: your peer's blocks/chain that is being tested
		current_longest: your valid chain + temp_chain/new blocks your peer mined
		last_block_hash: the hash of your last block

		"""
        # Checking the previous hash of the new block against your last block. This is done for you

        temp_chain.sort(key=self.sortHelper)
        self.valid_chain.sort(key=self.sortHelper)
        current_longest.sort(key=self.sortHelper)

        print(f'The length of valid chain is {len(self.valid_chain)} while length of temp_chain is {len(temp_chain)}')

        print("latest_block_hash: ", last_block_hash)

        # First, figure out if it is, indeed, longer.
        latest_valid_index = self.valid_chain[-1].index
        first_pending_index = temp_chain[0].index

        print(latest_valid_index, first_pending_index)
        latest_pending_index = first_pending_index

        target = "0".rjust(self.DIFFICULTY, '0')
        prevHash = ""

        for i in range(len(temp_chain)):
            if not i:  # Is there even a common point?
                if not temp_chain[0].previous_hash == self.computeBlockHash(self.valid_chain[first_pending_index - 1]):
                    print("The first block's previous hash does not match")
                    return False
                if not temp_chain[0].index == self.valid_chain[first_pending_index - 1].index + 1:
                    print("The indices do not match")
                    return False
                computed_hash = self.computeBlockHash(temp_chain[0])
                if computed_hash[0:self.DIFFICULTY] != target:
                    print(f'block {temp_chain[0].index} does not meet the difficulty criteria {computed_hash[0:12]}')
                    return False
                prevHash = computed_hash  # Make sure that the next blocks point to this
                prevIndex = temp_chain[0].index

            else:
                currentBlock = temp_chain[i]

                # does the previous hash match?
                if not currentBlock.previous_hash == prevHash:
                    print("The previous hash does not match")
                    print(currentBlock.previous_hash, currentBlock.index, prevHash, prevIndex)
                    return False
                if currentBlock.index != (prevIndex + 1):
                    print("indices are not sequential")
                    return False
                computed_hash = self.computeBlockHash(currentBlock)
                if computed_hash[0:self.DIFFICULTY] != target:
                    print(f'block {currentBlock.index} does not meet the difficulty criteria {computed_hash[0:12]}')
                    return False

                prevHash = computed_hash
                prevIndex = currentBlock.index

                latest_pending_index += 1

        print(f'The latest received block that meets the hash criteria is {latest_pending_index}')
        print(
            f'This means that the chain has an overlap until {first_pending_index - 1} and we must verify everything from {first_pending_index} till {latest_pending_index}')
        print(
            f'This means only {latest_pending_index - first_pending_index + 1} of {len(temp_chain)} blocks met the hash criteria and were chained')

        # Construct a UTXO database until first_pending_index - 1
        self.UTXO_Database_Pending = {}

        for i in range(0, first_pending_index):
            if not i:
                continue

            if len(self.valid_chain[i].transactions) > 5:
                print("This block has more than 5 transactions")
                return False

            if len(self.valid_chain[i].transactions) == 0:
                print(
                    "This block has no transactions. While this is allowed in bitcoin, we want you to actually validate at least one transaction")
                return False

            for Tx in self.valid_chain[i].transactions:
                if not self.verifyTransaction(Tx):
                    print("INVALID TRANSACTION FOUND in my valid chain?")
                    return False

        UTXO_pending_index = first_pending_index - 1

        for i in range(latest_pending_index - first_pending_index + 1):

            if len(temp_chain[i].transactions) > 5 or len(temp_chain[i].transactions) < 1:
                print("uh The block ", temp_chain[i].index, " has ", len(temp_chain[i].transactions), " transactions")
                return False

            for Tx in temp_chain[i].transactions:
                if not self.verifyTransaction(Tx):
                    print("INVALID TRANSACTION FOUND")
                    return False
            UTXO_pending_index += 1
        if UTXO_pending_index <= len(self.valid_chain) - 1:
            print("A longer valid chain was not found!")
            return False

        print("A longer valid chain was found")
        print("UTXO pending index, ", UTXO_pending_index, " len(self.valid_chain)", len(self.valid_chain))

        return True

    def print_chain(self):
        """
		DO NOT EDIT
		Prints the current valid chain in the terminal.
		"""
        self.valid_chain, self.confirmed_transactions = load_valid_chain()

        self.valid_chain.sort(key=self.sortHelper)

        for block in self.valid_chain:
            print("***************************")
            print(f"Block index # {block.index}")

            for trans in block.transactions:
                # if not block.index: #This is because the first block is hard coded and may have a different format
                # 	print("Sender: {}".format(trans["sender"]['key']) )
                # 	print("Receiver: {}".format(trans['receiver']['key']))
                # 	print("Token: {}".format(trans["signature_token"]) )
                # 	print("UTXO input: {}".format(trans["UTXO_input"]))
                # 	print("Sender received: {}".format(trans["value_sender"]))
                # 	print("Receiver received: {}".format(trans["value_receiver"]))
                # 	print("ID: {}".format(trans["id"]))
                if block.index:
                    print(f'Transaction number {trans["number"]} with hash {trans["id"]}')

            print("---------------------------")

            print("nonce: {}".format(block.nonce))
            print("previous_hash: {}".format(block.previous_hash))
            print('hash: {}'.format(self.computeBlockHash(block)))
            print('Miner: {}'.format(block.miner))
            print("***************************")
            print("")
