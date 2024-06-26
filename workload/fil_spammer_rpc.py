'''
@todo: 
1. Adding leader/follower entrypoint to generate a RPC token and place it in a common volume mount
2. Create argparser to pass in the RPC endpoint and read the token from common volume mount and pass it in from the entrypoint
3. Create an entrypoint for the workload to wait for the token to be created (which means start up more or less completed before it starts to do things)
4. Message in the workload that actually start the fault
'''

import requests, json
# import json

class fil_spammer_rpc():
    '''
    spamming fil across a local network
    '''
    def __init__(self, rpc_url:str, auth_token:str, wallet_filepath:str):
        '''
        The auth token should be generated from  the cli before starting the workload
        lotus auth create-token --perm <read,write,sign,admin>
        https://lotus.filecoin.io/reference/basics/api-access/
        '''
        self.auth_token = auth_token
        # url:1234/rpc/v0
        self.rpc_url = rpc_url
        self.wallet_filepath = wallet_filepath

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
        # lotus_node = 'lotus-1'
        # with open('/etc/hostname', 'r') as fh:
        #     lotus_node = fh.read()

        wallet_list_path = f'{self.wallet_filepath}/wallet-{node}.txt'

        wallets_created = []
        for _ in range(num_wallets):
            wallet_created = self.create_wallet()
            wallets_created.append(f'{wallet_created}\n')

        print(f'Created {len(wallets_created)} wallets on {node}')
        print(wallets_created)

        with open(wallet_list_path, 'w') as fh:
            fh.writelines(wallets_created)

    def read_wallets(self, node:str = 'lotus-1') -> str:
        wallets = []
        with open(f'{self.wallet_filepath}/wallet-{node}.txt', 'r') as fh:
            wallets = fh.readlines()

        return wallets

    def transfer_from_genesis_wallet(genesis_wallet_id:str, destination_wallet:str, amount:int):

        pass


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
            "params": ['secp256k1']
        })
        res = self.do_request('post', payload)

        if res['response'].status_code != 200:
            print(f'Bad response from {method}')
            return False

        data = res['response'].json()

        return data['result']

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

if __name__ == '__main__':

    lotus1 = 'http://10.20.20.24:1234/rpc/v0'
    auth_token = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJBbGxvdyI6WyJyZWFkIiwid3JpdGUiLCJzaWduIiwiYWRtaW4iXX0.svZiMvSuo3lOvOpL9ut_4ZZzS1CnIyayCNTRos8jReU'
    base_path = '/root/devgen'

    spammer = fil_spammer_rpc(lotus1, auth_token, base_path)

    print(spammer.get_genesis_wallet())
    # spammer.create_wallets()


    # wallets = spammer.read_wallets()
    # print(wallets)

    print('done')


