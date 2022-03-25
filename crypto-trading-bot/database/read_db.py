from decimal import Decimal
import sqlite3
from calculations.kline_interval import KlineInterval
from my_binance.filters import SymbolFilter
from utilities.unix_ts import string_to_datetime
from config.config import *

def get_earliest_dates_from_db(exchange: str, kline_interval: KlineInterval) -> dict:
    connection = sqlite3.connect('database/coins.sqlite')
    cursor = connection.cursor()
    query = (f"SELECT pair_symbol, earliest_date_string from kline_info WHERE " +
        f"exchange='{exchange}' AND kline_interval='{kline_interval.name}'")
    result_dict = {}
    for row in cursor.execute(query):
        dt_str = row[1]
        dt_obj = string_to_datetime(dt_str)
        result_dict[row[0]] = dt_obj
    return result_dict

def get_symbol_filters_from_db(exchange: str) -> dict[str, SymbolFilter]:
    connection = sqlite3.connect('database/coins.sqlite')
    cursor = connection.cursor()
    query = (f"SELECT pair_symbol, price_tick_size, qty_step_size from symbol_filter WHERE " +
        f"exchange='{exchange}'")
    result_dict = {}
    for row in cursor.execute(query):
        pair_symbol = row[0]
        symbol_filter = SymbolFilter()
        symbol_filter.price_tick_size = Decimal(row[1])
        symbol_filter.qty_step_size = Decimal(row[2])
        result_dict[pair_symbol] = symbol_filter
    return result_dict

def get_coins_from_db(exchange: str, kline_interval: KlineInterval):
    earliest_dates = get_earliest_dates_from_db(exchange, kline_interval)
    return list(earliest_dates.keys())