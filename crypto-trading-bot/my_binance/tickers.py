from binance.client import Client
from calculations.kline_interval import KlineInterval
from my_binance.client import create_client_safely
from utilities.unix_ts import *

interval_mapping = {
    KlineInterval.H4: '4h',
    KlineInterval.H8: '8h',
    KlineInterval.D1: '1d'
}

def get_all_tickers():
    client = create_client_safely()
    prices = client.get_all_tickers()
    usdt_only_prices = list(filter(lambda p: p['symbol'].endswith('USDT'), prices))
    symbols_only = list(map(lambda p: p['symbol'], usdt_only_prices))
    return symbols_only
