from abc import abstractmethod
from calculations.kline_count import get_kline_length_in_seconds
from config.config import KLINE_INTERVAL
from data_types.ohlcv import OHLCV
from data_types.simulation_result import SimulationResult
from data_types.ta_data import TaData
from data_types.step_data import StepData
from portfolio.trade_action import BuyAction, SellAction, TradeAction
from strategy.abstract_strategy import AbstractStrategy
from utilities.unix_ts import unix_ts_to_string

class TaBasedStrategy(AbstractStrategy):

    @abstractmethod
    def row_processing_step(self, dt_str: str, dt_ts: int) -> list:
        pass

    def create_stats_for_row(self, row_idx: int) -> str:
        output = ""
        sort_dict = {}
        stats_dict = {}
        last_row = self.big_table.df.iloc[row_idx]
        for coin in self.coins:
            if not self.big_table.have_coin_data(last_row, coin):
                continue
            ohlcv, ta_data = self.big_table.get_data_for_coin(last_row, coin)
            sort_dict[coin] = self.get_sort_dict_item(ohlcv, ta_data)
            stats_dict[coin] = self.get_stats_dict_item(ohlcv, ta_data)
        sorted_diff_dict = dict(sorted(sort_dict.items(), key=lambda item: item[1], reverse=True))
        for coin, sort_item in sorted_diff_dict.items():
            output += f'{coin}:\t{self.sort_dict_item_to_string(sort_item)}\t'
            output += f'{self.stats_dict_item_to_string(stats_dict[coin])}\n'
        return output

    def simulate(self) -> SimulationResult:

        if self.done:
            raise AssertionError('Simulation already processed.')

        self.init_signal_dict()

        for dt_ts, row in self.big_table.df.to_dict(orient='index').items():
            if self.start_stop.date_in_sim_bounds(dt_ts) == False:
                continue

            dt_str = row['Datetime']
            self.step_dict = {}
            for coin in self.coins:
                if not self.big_table.have_coin_data(row, coin):
                    continue
                ohlcv, ta_data = self.big_table.get_data_for_coin(row, coin)
                step_data = StepData(dt_str, dt_ts, coin, ohlcv, ta_data)
                self.step_dict[ohlcv.coin] = step_data
                self.portfolio.update_coin_price(coin, ohlcv.close, dt_str, dt_ts)

            trade_list = self.row_processing_step(dt_str, dt_ts)

            self.fill_output_row(dt_ts, dt_str)
            self.fill_signal_row(dt_ts, dt_str, trade_list)
        # Close all open positions at the end
        pf_pnl_dict, self.result.coins_left = self.portfolio.close_open_positions()
        self.result.pnl_dict = pf_pnl_dict

        self.result.prepare_output_table(self.output_dict)
        self.result.prepare_signal_table(self.signal_dict)
        self.done = True
        print(self.result.signal_table)

        return self.result

    def init_signal_dict(self):
        self.signal_dict = {'Datetime_UNIX': [], 'Datetime': []}
        for coin in self.coins:
            self.signal_dict[coin] = []

    def fill_signal_row(self, dt_ts: int, dt_str: str, trade_list: list[TradeAction]):
        signal_dt_ts = dt_ts + get_kline_length_in_seconds(KLINE_INTERVAL)
        signal_dt_str = unix_ts_to_string(signal_dt_ts)
        self.signal_dict['Datetime_UNIX'].append(signal_dt_ts)
        self.signal_dict['Datetime'].append(signal_dt_str)
        traded_coins = [trade_action.coin for trade_action in trade_list]
        if len(set(traded_coins)) != len(traded_coins):
            raise AssertionError(f'duplicates in signal table, traded_coins = {traded_coins}')
        for trade_action in trade_list:
            if type(trade_action) is BuyAction:
                mult = 1
            if type(trade_action) is SellAction:
                mult = -1
            self.signal_dict[trade_action.coin].append(trade_action.price * mult)
        for coin in self.coins:
            if coin in traded_coins:
                continue
            self.signal_dict[coin].append(None)

    def get_sort_dict_item(self, _: OHLCV, ta_data: TaData):
        return ta_data.SMA_diff

    def sort_dict_item_to_string(self, item) -> str:
        return f'MA_diff: {item:.1f}%'

    def get_stats_dict_item(self, ohlcv: OHLCV, _: TaData):
        return { 'close': ohlcv.close }

    def stats_dict_item_to_string(self, item) -> str:
        return f"close = {item['close']:.2f}"

