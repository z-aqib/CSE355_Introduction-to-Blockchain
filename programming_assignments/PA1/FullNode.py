from logging.config import valid_ident
import time
import pickle
from Block import Block
import os
import re
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

    ## PART ONE - UTXO Database Construction##

    ## Add code for part 1 here (You can make as many helper function you want)
    def _normalize_corrupt_store(self):
        """The skeleton initializes corrupt_transactions as a dict, but helpers expect iterable tx dicts."""
        if isinstance(self.corrupt_transactions, dict):
            self.corrupt_transactions = []

    def _get_output_from_db(self, db, txid, output_index):
        """Fetch a referenced output from the UTXO-style dictionary."""
        entry = db.get(txid)
        if not isinstance(entry, dict):
            return None
        return entry.get(output_index)

    def _find_parent_output_anywhere(self, txid, output_index):
        """Find the referenced parent output in any known transaction set.

        This is used for signature / ownership checks. Existence as *unspent* is checked against
        UTXO_Database_Pending separately.
        """
        sources = []
        sources.extend(self.confirmed_transactions)
        sources.extend(self.all_unconfirmed_transactions)
        sources.extend(self.unconfirmed_transactions)

        for tx in sources:
            if tx['id'] == txid:
                if 0 <= output_index < len(tx['outputs']):
                    value, pubkey_hash = tx['outputs'][output_index]
                    return {'value': value, 'pubkeyhash': pubkey_hash}
        return None

    def _add_transaction_outputs(self, db, Tx):
        """Add all outputs of a valid transaction into the supplied UTXO database."""
        if Tx['id'] not in db or not isinstance(db.get(Tx['id']), dict):
            db[Tx['id']] = {}
        for idx, output in enumerate(Tx['outputs']):
            value, pubkey_hash = output
            db[Tx['id']][idx] = {'value': value, 'pubkeyhash': pubkey_hash}

    def _remove_spent_output(self, db, txid, output_index):
        """Remove an output that has just been spent from the UTXO database."""
        if txid in db and isinstance(db[txid], dict) and output_index in db[txid]:
            del db[txid][output_index]
            if len(db[txid]) == 0:
                del db[txid]

    def verifyTransaction(self, Tx):
        """Check integrity + validity, and update UTXO_Database_Pending on success."""
        self._normalize_corrupt_store()

        # Work on a deep copy so invalid transactions do not mutate pending state.
        temp_utxo = copy.deepcopy(self.UTXO_Database_Pending)

        input_sum = 0
        output_sum = sum(output[0] for output in Tx['outputs'])

        # Coinbase transactions create 5e9 satoshis out of thin air.
        if Tx['COINBASE']:
            if Tx['id'] in temp_utxo:
                return False
            if output_sum > int(5e9):
                if Tx not in self.corrupt_transactions:
                    self.corrupt_transactions.append(Tx)
                return False
            # Duplicate-prevention marker required by the handout.
            temp_utxo[Tx['id']] = True
            self._add_transaction_outputs(temp_utxo, Tx)
            self.UTXO_Database_Pending = temp_utxo
            return True

        # Regular transactions: verify every input.
        tx_string_ex_sig = stringifyTransactionExcludeSig(Tx)
        current_hash = calculateHash(tx_string_ex_sig)

        for inp in Tx['inputs']:
            prev_txn_id, output_number, signature, pubkey = inp

            # 1) Integrity check: the signature must match parentHash:currentHash.
            final_string = str(prev_txn_id) + ':' + str(current_hash)
            final_hash = calculateHash(final_string)
            tentative_hash = UnlockSignature(final_string, signature, pubkey)
            if tentative_hash != final_hash:
                if Tx not in self.corrupt_transactions:
                    self.corrupt_transactions.append(Tx)
                return False
            # Also use the provided helper to stay aligned with the assignment utilities.
            if not VerifySignature(final_string, signature, pubkey):
                if Tx not in self.corrupt_transactions:
                    self.corrupt_transactions.append(Tx)
                return False

            # 2) The parent output must exist somewhere and belong to the supplied public key.
            parent_output = self._find_parent_output_anywhere(prev_txn_id, output_number)
            if parent_output is None:
                return False
            if parent_output['pubkeyhash'] != hashPubKey(pubkey):
                if Tx not in self.corrupt_transactions:
                    self.corrupt_transactions.append(Tx)
                return False

            # 3) UTXO validity check: it must still be unspent in the pending DB.
            live_output = self._get_output_from_db(temp_utxo, prev_txn_id, output_number)
            if live_output is None:
                return False

            input_sum += live_output['value']
            self._remove_spent_output(temp_utxo, prev_txn_id, output_number)

        # Regular transactions may leave a fee for the miner, so outputs
        # must not exceed inputs.
        if input_sum < output_sum:
            if Tx not in self.corrupt_transactions:
                self.corrupt_transactions.append(Tx)
            return False

        self._add_transaction_outputs(temp_utxo, Tx)
        self.UTXO_Database_Pending = temp_utxo
        return True

    def findValidButUnconfirmedTransactions(self):
        # find 5 valid transactions that are NOT in a block yet
        self.valid_but_unconfirmed_transactions = {}
        # Start from the committed UTXO snapshot so sequential validation can build on it.
        self.UTXO_Database_Pending = copy.deepcopy(self.UTXO_Database)

        valid_transactions = []
        seen_ids = set()
        for Tx in sorted(self.unconfirmed_transactions, key=self.sortHelperNumber):
            if Tx['id'] in seen_ids:
                continue
            if self.verifyTransaction(Tx):
                valid_transactions.append(Tx)
                self.valid_but_unconfirmed_transactions[Tx['id']] = Tx
                seen_ids.add(Tx['id'])
            if len(valid_transactions) >= 5:
                break
        return valid_transactions

	## PART TWO - Mining and Proof-Of-Work ##
	# Mine Blocks -- skip genesis block
    # Suggested steps:
    # 1. Update UTXO if update==True
    # 2. Copy to pending
    # 3. Collect valid transactions
    # 4. Create block
    # 5. Run proof_of_work
    # 6. Append and save block
    # 7. Update UTXO
    def mine(self, startingNonce=0, update=True):
        """
        Mines a new block containing valid unconfirmed transactions.

        Because proof_of_work may exit early without finding a valid hash,
        mine() is designed to be called repeatedly until it succeeds.
        The calling loop in main.py already handles this — study it before
        implementing this function, as your return values must match what
        it expects.

        Parameters:
            startingNonce (int): The nonce value to start searching from.
                                 Passed in by main.py — 0 on the first call,
                                 and whatever this function last returned on
                                 subsequent calls.
            update (bool): Whether to rebuild the UTXO database and collect
                           fresh transactions. Passed in by main.py — True on
                           the first call only, False on resume calls.

        Returns:
            0              if a block was successfully mined.
            nonce (int)    if proof_of_work exited early; main.py will pass
                           this back in as startingNonce on the next call.

        You should check what proof_of_work returns and handle both cases.
        """
        if update or self._candidate_block is None:
            self.valid_chain, self.confirmed_transactions = load_valid_chain()
            self.update_UTXO()
            transactions = self.findValidButUnconfirmedTransactions()

            if not transactions:
                print("No valid unconfirmed transactions available to mine")
                return 0

            previous_block = self.last_block()
            previous_hash = self.computeBlockHash(previous_block)
            new_index = previous_block.index + 1
            timestamp = str(int(time.time()))
            self._candidate_block = Block(
                new_index,
                transactions,
                timestamp,
                previous_hash,
                str(self.STUDENT_ID),
                startingNonce,
            )
        else:
            self._candidate_block.nonce = startingNonce

        computed_hash, nonce = self.proof_of_work(self._candidate_block)

        if computed_hash == 0:
            return nonce

        print("block hash found")
        print(computed_hash)
        self.valid_chain.append(self._candidate_block)
        save_object(self._candidate_block, "valid_chain/block{}.block".format(self._candidate_block.index))
        self.update_UTXO()
        self._candidate_block = None
        return 0

    def proof_of_work(self, block):
        """
        Performs Proof-Of-Work on the given block by iterating the nonce until
        the block hash meets the difficulty condition (self.DIFFICULTY leading zeros)
        AND the nonce is a multiple of 10.

        To avoid blocking the program indefinitely, this function exits early
        after a fixed number of iterations if no valid hash is found yet.
        In that case, return (0, block.nonce) so the caller knows to resume
        from this nonce in the next call.

        If a valid hash IS found, return (computed_hash, block.nonce).

        Returns: (hash_string, nonce)  on success
                 (0, nonce)            on early exit (limit reached, keep trying)
        """
        max_iterations = 5000
        target_prefix = '0' * self.DIFFICULTY

        # Ensure the nonce sequence always respects the "multiple of 10" rule.
        if block.nonce % 10 != 0:
            block.nonce += (10 - (block.nonce % 10))

        for _ in range(max_iterations):
            computed_hash = self.computeBlockHash(block)
            if block.nonce % 10 == 0 and computed_hash.startswith(target_prefix):
                return computed_hash, block.nonce
            block.nonce += 10

        return 0, block.nonce

    def computeBlockHash(self, block):  # Compute the aggregate transaction hash.
        block_string = json.dumps(block.__dict__, sort_keys=True)
        return sha256(block_string.encode()).hexdigest()

    def sortHelper(self, block):
        return block.index

    def sortHelperNumber(self, Tx):
        return Tx['number']

    def update_UTXO(self, till=-1):
        # Update your UTXO database according to your VALID_CHAIN folder.
        self.valid_chain, self.confirmed_transactions = load_valid_chain()
        self.UTXO_Database_Pending = {}
        self.UTXO_Database = {}

        if till == -1:
            till = len(self.valid_chain) - 1

        for block in sorted(self.valid_chain, key=self.sortHelper):
            if block.index == 0 or block.index > till:
                continue
            for Tx in block.transactions:
                self.verifyTransaction(Tx)

        self.UTXO_Database = copy.deepcopy(self.UTXO_Database_Pending)
        return

    def showAccounts(self):
        """return a dictionary with mapping from pubkeyHash to total crypto available
        Uses the PENDING UTXO database
        """
        balances = {}

        # Collect all addresses we have seen so users with zero balance still appear
        all_transactions = []
        all_transactions.extend(self.confirmed_transactions)
        all_transactions.extend(self.all_unconfirmed_transactions)
        all_transactions.extend(self.unconfirmed_transactions)

        for Tx in all_transactions:
            # Skip anything malformed / non-transaction-like
            if not isinstance(Tx, dict):
                continue
            if 'outputs' not in Tx:
                continue

            for value, pubkey_hash in Tx['outputs']:
                balances.setdefault(pubkey_hash, 0)

        # Sum only actual UTXOs from the pending database
        for txid, entry in self.UTXO_Database_Pending.items():
            # Skip non-dict entries if any marker/value exists
            if not isinstance(entry, dict):
                continue

            for output_index, utxo in entry.items():
                # Skip malformed entries
                if not isinstance(utxo, dict):
                    continue
                if 'pubkeyhash' not in utxo or 'value' not in utxo:
                    continue

                balances[utxo['pubkeyhash']] = balances.get(utxo['pubkeyhash'], 0) + utxo['value']

        for pubkey_hash in sorted(balances.keys()):
            print(pubkey_hash, balances[pubkey_hash])

        return balances

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
                print(f' last_block_index {last_block_index} >= len(self.valid_chain) {len(self.valid_chain)} ?')
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
        # current_longest is the longest chain including any overlap with your valid chain
		# temp_chain is only the difference between your valid chain and the current longest chain
		# last_block_hash is the hash of the previous block of temp_chain[0]. If there is no overlap, for example, this should be
		# the hash of the genesis block
        # Steps to be followed:
        # Step 1: Check linkage
        # Step 2: Check indices
        # Step 3: Check PoW
        # Step 4: Rebuild UTXO and validate transactions
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
        if not temp_chain:
            return False

        target_prefix = '0' * self.DIFFICULTY

        # Step 1 + 2 + 3: linkage, sequential indices, PoW.
        expected_prev_hash = last_block_hash
        expected_index = temp_chain[0].index
        for block in temp_chain:
            if block.index != expected_index:
                return False
            if block.previous_hash != expected_prev_hash:
                return False
            block_hash = self.computeBlockHash(block)
            if not block_hash.startswith(target_prefix):
                return False
            if block.nonce % 10 != 0:
                return False
            expected_prev_hash = block_hash
            expected_index += 1

        # Step 4: rebuild UTXO and validate all transactions in the candidate longest chain.
        seen_tx_ids = set()
        backup_utxo = copy.deepcopy(self.UTXO_Database)
        backup_pending = copy.deepcopy(self.UTXO_Database_Pending)
        backup_corrupt = copy.deepcopy(self.corrupt_transactions)

        self.UTXO_Database = {}
        self.UTXO_Database_Pending = {}
        self._normalize_corrupt_store()
        self.corrupt_transactions = []

        try:
            for block in sorted(current_longest, key=self.sortHelper):
                if block.index == 0:
                    continue
                for Tx in block.transactions:
                    if Tx['id'] in seen_tx_ids:
                        return False
                    seen_tx_ids.add(Tx['id'])
                    if not self.verifyTransaction(Tx):
                        return False
            return True
        finally:
            self.UTXO_Database = backup_utxo
            self.UTXO_Database_Pending = backup_pending
            self.corrupt_transactions = backup_corrupt

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
