import pandas as pd
import requests
import time, datetime
from calculations.kline_interval import KlineInterval
from utilities.unix_ts import string_to_unix_ts, to_unix_ts, unix_ts_to_string
import logging

base_api_url = 'https://api.kucoin.com'

interval_mapping = {
    KlineInterval.M15: '15min',
    KlineInterval.H1: '1hour',
    KlineInterval.H4: '4hour',
    KlineInterval.H8: '8hour',
    KlineInterval.D1: '1day'
}

def get_earliest_valid_kucoin(symbol: str):
    start_date = datetime.datetime(2019, month=1, day=1, tzinfo=datetime.timezone.utc)
    end_date = datetime.datetime.now(datetime.timezone.utc)
    symbol_history = download(symbol, KlineInterval.H8, start_date, end_date)
    index_values = symbol_history.index.values
    unix_ts = index_values[0]
    dt_str = unix_ts_to_string(unix_ts)
    logging.debug(f'unix_ts: {unix_ts}, dt_str = {dt_str}')
    return unix_ts, dt_str

def download(symbol: str, kline_interval: KlineInterval, 
    start_date: datetime, end_date: datetime) -> pd.DataFrame:

    if end_date <= start_date:
        raise AssertionError('StartDate must be greater than EndDate')

    url = (base_api_url +
        f'/api/v1/market/candles?type={interval_mapping[kline_interval]}&symbol={symbol}&' +
        f'startAt={to_unix_ts(start_date)}&endAt={to_unix_ts(end_date)}')
    logging.debug(f'Kucoin API URL: {url}')
    download_success = False
    kline = None
    while not download_success:
        try:
            kline = requests.get(url)
            kline = kline.json()
            kline = pd.DataFrame(kline['data'])
            download_success = True
        except KeyError as e:
            print(e)
            print('KeyError, retrying in 1 second...')
            time.sleep(1)
    kline = kline.rename({0:"Datetime_UNIX",1:"Open",
                    2:"Close",3:"High",4:"Low",5:"Amount",6:"Volume"}, axis='columns')
    if kline.empty:
        raise AssertionError('No data from Kucoin!')
        
    kline['Datetime'] = kline['Datetime_UNIX'].apply(unix_ts_to_string)
    kline = kline.astype({'Datetime_UNIX': int})
    kline.set_index('Datetime_UNIX', inplace=True)
    kline = kline.reindex(index=kline.index[::-1])
    return kline
