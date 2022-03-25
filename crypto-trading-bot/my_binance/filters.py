from dataclasses import dataclass
from my_binance.client import create_client_safely
from secrets.binance_keys import *
from decimal import Decimal

@dataclass
class SymbolFilter:
    price_tick_size: Decimal = None
    qty_step_size: Decimal = None

def get_filters_for_coins(coins: list[str]) -> dict[str, SymbolFilter]:

    client = create_client_safely()
    exchange_info = client.get_exchange_info()

    relevant_entries = [entry for entry in
        exchange_info['symbols'] if entry['symbol'] in coins]
    filter_dict = {entry['symbol']: entry['filters'] for entry in relevant_entries}

    my_filters = {}
    for coin_symbol, filter_list in filter_dict.items():
        symbol_filter = SymbolFilter()
        for single_filter in filter_list:
            if single_filter['filterType'] == 'PRICE_FILTER':
                symbol_filter.price_tick_size = Decimal(single_filter['tickSize'])
            if single_filter['filterType'] == 'LOT_SIZE':
                symbol_filter.qty_step_size = Decimal(single_filter['stepSize'])
        my_filters[coin_symbol] = symbol_filter

    print(my_filters)
    return my_filters