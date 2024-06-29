'''
@todo: 
1. Adding leader/follower entrypoint to generate a RPC token and place it in a common volume mount
2. Create argparser to pass in the RPC endpoint and read the token from common volume mount and pass it in from the entrypoint
3. Create an entrypoint for the workload to wait for the token to be created (which means start up more or less completed before it starts to do things)
4. Message in the workload that actually start the fault
'''

import requests, json, random
# import json

class fil_spammer_rpc():
    '''
    spamming fil across a local network
    '''
    def __init__(self, rpc_url:str, auth_token:str, common_mount_path:str):
        '''
        The auth token should be generated from  the cli before starting the workload
        lotus auth create-token --perm <read,write,sign,admin>
        https://lotus.filecoin.io/reference/basics/api-access/
        '''
        self.auth_token = auth_token
        # url:1234/rpc/v0
        self.rpc_url = rpc_url
        self.basepath = common_mount_path

    def do_request(self, method:str, payload:dict) -> dict:
        '''
        Making raw api requests
        @param method - get | post
        @param payload - request payload
        '''
        # default headers
        headers = {
            "Content-Type": "application/json",
            # "Accept": "application/json",
            "Authorization": f'Bearer {self.auth_token}'
        }

        if method in ['get', 'post', 'put', 'delete', 'head', 'options']:
            # @todo: need to provide stuffing of additional kwargs
            # payloads are mapped differently in the request call
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

            return {
                'request': {
                    'url': self.rpc_url,
                    'headers': headers,
                    'payload': payload,
                },
                'response': response
            }

    def create_wallets(self, node:str = 'lotus-1', num_wallets:int = 10) -> None:
        '''
        Creating the initial development wallets for spamming
        '''

        wallet_list_path = f'{self.basepath}/wallet-{node}.json'

        wallets_created = {}
        for _ in range(num_wallets):
            id = self.create_wallet()
            wallets_created[id] = ''

        with open(wallet_list_path, 'w') as fh:
            fh.write(json.dumps(wallets_created))

        print(f'Created {num_wallets} wallets on {node}')
        print(wallets_created)

    def get_wallet_pks(self):
        '''
        Getting wallet private keys so we can use them in transactions
        '''
        # wallet_list_path = f'{self.basepath}/wallet-{node}.txt'


    def read_wallets(self, node:str = 'lotus-1') -> str:
        wallets = []
        with open(f'{self.basepath}/wallet-{node}.json', 'r') as fh:
            wallets = json.load(fh)

        return wallets


        cid = self.get_chainhead()
        if (not bool(cid)):
            print('Failed to get CID from chainhead RPC call')
            return

        method = 'Filecoin.MpoolPushUntrusted'
        payload = json.dumps({
            "jsonrpc": "2.0",
            "id": "1",
            "method": method,
            "params": [
                {
                    "Message": {
                    # "Version": 42,
                    "To": wallet_to_id,
                    "From": wallet_from_id,
                    # "Nonce": 42,
                    "Value": amount,
                    "GasLimit": 10000000,
                    "GasFeeCap": "10000000",
                    "GasPremium": "0",
                    "Method": 1,
                    "Params": wallet_from_pk,
                    "CID": {
                        "/": cid,
                    }
                    },
                    "Signature": {
                    "Type": 2,
                    "Data": wallet_from_pk
                    },
                    "CID": {
                    "/": cid,
                    }
                }
            ]
        })
        res = self.do_request('post', payload)

        if res['response'].status_code != 200:
            print(f'Bad response from {method}')
            print(res)
            # return False

        return res

    def _estimate_message_gas(self, wallet_from_id:str, wallet_to_id:str, amount:str) -> dict:
        '''
        Estiamte gas for a mPool message
        return a dictionary with
        Nonce, Value, GasLimit, GasFeeCap, GasPremium
        '''
        method = 'Filecoin.GasEstimateMessageGas'
        payload = json.dumps({
            "jsonrpc": "2.0",
            "id": "1",
            "method": method,
            "params": [
                {
                    # "Version": 42,
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
            # print(res)
            return False

        data = res['response'].json()
        return data['result']

    def transfer(self, wallet_from_id:str, wallet_from_pk:str, wallet_to_id: str, amount:str):

        cid = self.get_chainhead()
        if (not bool(cid)):
            print('Failed to get CID from chainhead RPC call')
            return

        gas_info = self._estimate_message_gas(wallet_from_id, wallet_to_id, amount)
        if (not bool(gas_info)):
            print('Failed to get gas information to do MpoolPushMessage')
            return

        method = 'Filecoin.MpoolPushMessage'
        payload = json.dumps({
            "jsonrpc": "2.0",
            "id": "1",
            "method": method,
            "params": [
                {
                    # "Version": 42,
                    "To": wallet_to_id,
                    "From": wallet_from_id,
                    "Value": amount,
                    "GasLimit": gas_info['GasLimit'],
                    "GasFeeCap": gas_info['GasFeeCap'],
                    "GasPremium": gas_info['GasPremium'],
                    "Method": 0,
                    # "Params": wallet_from_pk,
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
            print(res)
            # return False
        return res

    def transfer_from_genesis(self, destination_wallet_id:str, amount:str):
        genesis_wallet = self.get_genesis_wallet()
        if not bool(genesis_wallet):
            print('Unable to retrieve genesis wallet')
            return

        genesis_pk = self.get_wallet_pk(genesis_wallet)

        print(f'Genesis wallet: {genesis_wallet}')
        print(f'Genesis wallet pk: {genesis_pk}')
        print(f'Destination wallet: {destination_wallet_id}')

        return self.transfer(genesis_wallet, genesis_pk, destination_wallet_id, amount)

    def create_wallet(self) -> str:
        '''
        @param lotus_node - the lotus node in which the wallet is created
        @return the wallet id created
        '''
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
            return False

        data = res['response'].json()

        return data['result']
    
    def get_wallet_pk(self, wallet_id) -> str:
        '''
        Getting the private key for a wallet so we can use it to send transactions
        '''
        method = 'Filecoin.WalletExport'
        payload = json.dumps({
            "jsonrpc": "2.0",
            "id": "1",
            "method": method,
            "params": [wallet_id]
        })
        res = self.do_request('post', payload)

        if res['response'].status_code != 200:
            print(f'Bad response from {method}')
            return False

        data = res['response'].json()

        return data['result']['PrivateKey']

    def get_genesis_wallet(self):
        '''
        Get the wallet address of the genesis wallet which has all of the FIL we need to transfer
        '''
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
            return False

        # Crude logic to retrieve the genesis wallet, should be on the primary leader node
        example_non_genesis_wallet = "t1sua7sz4h43j3rhsh3x7f5ciysyck7bqzme3dtxy"

        response_body = res['response'].json()
        for wallet in response_body['result']:
            if len(wallet) > len(example_non_genesis_wallet):
                genesis_wallet = wallet

        return genesis_wallet

    def get_chainhead(self):
        '''
        This method doesn't need auth
        @return cid that we can potentially use to push messages
        '''
        cid = ''
        method = 'Filecoin.ChainHead'
        payload = json.dumps({
            "jsonrpc": "2.0",
            "id": "1",
            "method": method
        })
        res = self.do_request('post', payload)

        if res['response'].status_code != 200:
            print(f'Bad response from {method}')
            return False

        response_body = res['response'].json()

        if len(response_body['result']['Cids']) > 0:
            cid = response_body['result']['Cids'][0]
            # pretty bad here
            if '/' in cid:
                cid = cid['/']

        return cid

if __name__ == '__main__':

    lotus1 = 'http://10.20.20.24:1234/rpc/v0'
    base_path = '/root/devgen'

    auth_token = ''
    with open(f'{base_path}/lotus-1-token.txt') as f:
        auth_token = f.read()

    auth_token = auth_token.rstrip()

    print(f'Auth token: ({auth_token})')

    spammer = fil_spammer_rpc(lotus1, auth_token, base_path)

    print('Genesis wallet')
    print(spammer.get_genesis_wallet())

    # spammer.create_wallets()

    # wallets = spammer.read_wallets()
    # print(wallets)


    # print(spammer.create_wallet())

    res = spammer.transfer_from_genesis('t1y22of2obqrgrqnswiicjpwlwhtyb7szjkefhfii', '100000')
    print(res)
    print(res['response'].text)

    print('done')
