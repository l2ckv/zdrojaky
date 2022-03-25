import datetime
import pandas as pd
from calculations.kline_interval import KlineInterval
from my_binance.client import create_client_safely
from utilities.unix_ts import *
import logging

MAX_RETRIES = 5

interval_mapping = {
    KlineInterval.M15: '15m',
    KlineInterval.H4: '4h',
    KlineInterval.H8: '8h',
    KlineInterval.D1: '1d'
}

def get_earliest_valid(symbol: str, kline_interval: KlineInterval):
    kline_interval_value = interval_mapping[kline_interval]
    client = create_client_safely()
    unix_ts = client._get_earliest_valid_timestamp(symbol, kline_interval_value)
    dt_str = unix_ms_to_string(unix_ts, True)
    logging.info(f'Eariest valid for {symbol}: {dt_str} ({unix_ts})')
    return unix_ts, dt_str

def download(symbol: str, kline_interval: KlineInterval, 
    start_date: datetime, end_date: datetime) -> pd.DataFrame:

    if end_date <= start_date:
        raise AssertionError('StartDate must be greater than EndDate')

    client = create_client_safely()
    kline_interval_value = interval_mapping[kline_interval]

    start_date_ms = to_unix_ms(start_date)
    end_date_ms = to_unix_ms(end_date)
    i = 0
    while i < MAX_RETRIES:
        try:
            klines = client.get_historical_klines(symbol, kline_interval_value,
                start_date_ms, end_date_ms,limit=1000)
            break
        except Exception as e:
            logging.warning(e)
            i += 1

    for line in klines:
        del line[6:]

    df = pd.DataFrame(klines)
    df = df.rename({0: 'Datetime_UNIX',
                    1: 'Open', 2: 'High', 3: 'Low', 4: 'Close', 5: 'Amount'},
                   axis='columns')
    data_includes_time = kline_interval != KlineInterval.D1
    df['Datetime_UNIX'] = df['Datetime_UNIX'].apply(lambda ms: ms / 1000)
    df['Datetime'] = df['Datetime_UNIX'].apply(unix_ts_to_string, args=[data_includes_time])
    df = df.astype({'Datetime_UNIX': int})
    df.set_index('Datetime_UNIX', inplace=True)
    
    logging.debug(df.head())

    return df