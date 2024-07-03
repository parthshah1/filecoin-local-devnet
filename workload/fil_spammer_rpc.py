import requests
import json
import os
import time
import subprocess
import random

class fil_spammer_rpc():
    def __init__(self, rpc_url:str, auth_token:str, common_mount_path:str):
        self.auth_token = auth_token
        self.rpc_url = rpc_url
        self.basepath = common_mount_path

    def do_request(self, method:str, payload:dict) -> dict:
        headers = {
            "Content-Type": "application/json",
            "Authorization": f'Bearer {self.auth_token}'
        }

        if method in ['get', 'post', 'put', 'delete', 'head', 'options']:
            payload_mapping = {
                'get': 'params',
                'post': 'data',
            }
            kwargs = {}
            if bool(payload):
                if method in payload_mapping.keys():
                    kwargs.update({payload_mapping[method]: payload})

            func = getattr(requests, method)
            response = func(self.rpc_url, headers=headers, **kwargs)
            response_json = response.json()

            return {
                'request': {
                    'url': self.rpc_url,
                    'headers': headers,
                    'payload': payload,
                },
                'response': response,
                'response_json': response_json
            }

    def create_wallet(self) -> str:
        method = 'Filecoin.WalletNew'
        payload = json.dumps({
            "jsonrpc": "2.0",
            "id": "1",
            "method": method,
            "params": [1]
        })
        res = self.do_request('post', payload)

        if res['response'].status_code != 200:
            print(f'Bad response from {method}')
            print(res['response_json'])
            return False

        return res['response_json']['result']

    def get_chainhead(self):
        method = 'Filecoin.ChainHead'
        payload = json.dumps({
            "jsonrpc": "2.0",
            "id": "1",
            "method": method
        })
        res = self.do_request('post', payload)

        if res['response'].status_code != 200:
            print(f'Bad response from {method}')
            print(res['response_json'])
            return False

        response_body = res['response_json']
        if len(response_body['result']['Cids']) > 0:
            cid = response_body['result']['Cids'][0]
            if '/' in cid:
                cid = cid['/']
            return cid
        return None

    def get_genesis_wallet(self):
        genesis_wallet = False
        method = 'Filecoin.WalletList'
        payload = json.dumps({
            "jsonrpc": "2.0",
            "id": "1",
            "method": method
        })
        res = self.do_request('post', payload)

        if res['response'].status_code != 200:
            print(f'Bad response from {method}')
            print(res['response_json'])
            return False

        example_non_genesis_wallet = "t1sua7sz4h43j3rhsh3x7f5ciysyck7bqzme3dtxy"
        response_body = res['response_json']
        for wallet in response_body['result']:
            if len(wallet) > len(example_non_genesis_wallet):
                genesis_wallet = wallet

        return genesis_wallet

    def transfer_from_genesis(self, genesis_wallet, destination_wallet_id:str, amount:str):
        command = [
            "./lotus-local-net/lotus",
            "send",
            "--from",
            genesis_wallet,
            destination_wallet_id,
            amount
        ]
        result = subprocess.run(command, capture_output=True, text=True)
        return result

    def _estimate_message_gas(self, wallet_from_id:str, wallet_to_id:str, amount:str) -> dict:
        method = 'Filecoin.GasEstimateMessageGas'
        payload = json.dumps({
            "jsonrpc": "2.0",
            "id": "1",
            "method": method,
            "params": [
                {
                    "To": wallet_to_id,
                    "From": wallet_from_id,
                    "Value": amount,
                    "GasLimit": 10000000,
                    "Method": 0,
                },
                {
                    "MaxFee": "0"
                }, None
            ]
        })

        res = self.do_request('post', payload)

        if res['response'].status_code != 200:
            print(f'Bad response from {method}')
            print(res['response_json'])
            return False

        return res['response_json']['result']

    def push_message(self, wallet_from_id:str, wallet_to_id: str, amount:str, nonce:int):
        cid = self.get_chainhead()
        if not bool(cid):
            print('Failed to get CID from chainhead RPC call')
            return

        gas_info = self._estimate_message_gas(wallet_from_id, wallet_to_id, amount)
        if not bool(gas_info):
            print('Failed to get gas information to do MpoolPushMessage')
            return

        method = 'Filecoin.MpoolPushMessage'
        payload = json.dumps({
            "jsonrpc": "2.0",
            "id": "1",
            "method": method,
            "params": [
                {
                    "Version": 0,
                    "To": wallet_to_id,
                    "From": wallet_from_id,
                    "Nonce": nonce,
                    "Value": amount,
                    "GasLimit": gas_info['GasLimit'],
                    "GasFeeCap": gas_info['GasFeeCap'],
                    "GasPremium": gas_info['GasPremium'],
                    "Method": 0,
                    "Params": "",
                    "CID": {
                        "/": cid
                    }
                },
                {
                    "MaxFee": "0"
                }
            ]
        })
        res = self.do_request('post', payload)

        if res['response'].status_code != 200:
            print(f'Bad response from {method}')
            print(res['response_json'])
            return False
        return res

    def fuzz_push_message(self, wallet_from_id:str, wallet_to_id: str, amount:str, nonce:int):
        # Define possible fuzzing scenarios
        fuzz_cases = [
            {"Nonce": -1},  # Invalid nonce
            {"Value": "0"},  # Zero amount
            {"Value": "-100"},  # Negative amount
            {"Value": "1000000000000000000000"},  # Excessively high amount
            {"GasLimit": "0"},  # Zero gas limit
            {"GasLimit": "-1000"},  # Negative gas limit
            {"To": "t1invalidwallet"},  # Invalid recipient address
            {"GasFeeCap": "0"},  # Zero gas price
            {"GasFeeCap": "-1000"},  # Negative gas price
        ]

        for fault in fuzz_cases:  # Test each fault separately
            cid = self.get_chainhead()
            if not bool(cid):
                print('Failed to get CID from chainhead RPC call')
                continue

            gas_info = self._estimate_message_gas(wallet_from_id, wallet_to_id, amount)
            if not bool(gas_info):
                print('Failed to get gas information to do MpoolPushMessage')
                continue

            method = 'Filecoin.MpoolPushMessage'
            fuzz_payload = {
                "Version": 0,
                "To": wallet_to_id,
                "From": wallet_from_id,
                "Nonce": nonce,
                "Value": amount,
                "GasLimit": gas_info['GasLimit'],
                "GasFeeCap": gas_info['GasFeeCap'],
                "GasPremium": gas_info['GasPremium'],
                "Method": 0,
                "Params": "",
                "CID": {"/": cid}
            }

            # Inject the fault
            fuzz_payload.update(fault)

            payload = json.dumps({
                "jsonrpc": "2.0",
                "id": "1",
                "method": method,
                "params": [fuzz_payload, {"MaxFee": "0"}]
            })

            res = self.do_request('post', payload)
            print(f'Fuzzing with fault {fault}: response', res['response_json'])

if __name__ == '__main__':
    # Get environment variables
    rpc_url = os.getenv('RPC_URL', 'http://10.20.20.24:1234')
    token_path = os.getenv('TOKEN_PATH', '/root/devgen/jwt')
    num_wallets = int(os.getenv('NUM_WALLETS', 10))
    num_transactions = int(os.getenv('NUM_TRANSACTIONS', 100))

    with open(token_path) as f:
        auth_token = f.read().strip()

    spammer = fil_spammer_rpc(rpc_url, auth_token, os.path.dirname(token_path))

    # Create wallets
    wallets = []
    for _ in range(num_wallets):
        wallet_id = spammer.create_wallet()
        wallets.append(wallet_id)

    print(f'Created wallets: {wallets}')

    # Get the genesis wallet
    genesis_wallet = spammer.get_genesis_wallet()
    if not genesis_wallet:
        print('Unable to retrieve genesis wallet')
        exit(1)
    print(f'Genesis wallet: {genesis_wallet}')

    # Distribute FIL from genesis wallet to created wallets
    for wallet_id in wallets:
        res = spammer.transfer_from_genesis(genesis_wallet, wallet_id, '1000')
        print(f'Transfer to {wallet_id} response:', res.stdout)

    # Sleep for a while to ensure the funds are properly transferred
    time.sleep(15)

    # Get and print the ChainHead CID
    chainhead_cid = spammer.get_chainhead()
    print(f'ChainHead CID: {chainhead_cid}')

    # Send multiple transactions
    nonce = 0
    for i in range(num_transactions):
        from_wallet = wallets[i % len(wallets)]
        to_wallet = wallets[(i + 1) % len(wallets)]
        amount = str(100 + (i % 100))  # Example varying amounts

        # Randomly decide whether to fuzz or send a good transaction
        if random.random() < 0.5:  # 50% chance to fuzz
            spammer.fuzz_push_message(from_wallet, to_wallet, amount, nonce)
        else:
            res = spammer.push_message(from_wallet, to_wallet, amount, nonce)
            print(f'Push message {i+1} from {from_wallet} to {to_wallet} response:', res['response_json'])

        nonce += 1
