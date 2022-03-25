import pandas as pd
import requests

base_api_url = 'https://api.kucoin.com'

def get_all_symbols() -> list:
    url = base_api_url + '/api/v1/symbols'
    result = requests.get(url)
    result_json = result.json()
    pd_table = pd.DataFrame(result_json['data'])
    usdt_only = pd_table[pd_table['quoteCurrency'] == 'USDT']
    result_list = usdt_only['symbol'].tolist()
    return result_list