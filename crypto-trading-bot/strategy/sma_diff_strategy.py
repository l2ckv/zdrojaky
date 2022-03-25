from data_types.sim_config import SimConfig
from data_types.start_stop_date import StartStopDate
from data_types.ohlcv import OHLCV
from data_types.ta_data import TaData
from strategy.all_coin_strategy import AllCoinStrategy
from data_types.step_data import StepData

class SMA_DifferenceStrategy(AllCoinStrategy):

    def __init__(self, sim_cfg: SimConfig, start_stop: StartStopDate, params: dict):
        super().__init__(sim_cfg, start_stop)
        self.high = params['high']
        self.low = params['low']

    def buy_condition(self, _: OHLCV, ta_data: TaData) -> bool:
        return ta_data.SMA_diff > self.high

    def sell_condition(self, _: OHLCV, ta_data: TaData) -> bool:
        return ta_data.SMA_diff < self.low

    def get_sort_dict_item(self, _: OHLCV, ta_data: TaData):
        return ta_data.SMA_diff

    def sort_dict_item_to_string(self, item) -> str:
        return f'MA_diff: {item:.1f}%'

    def get_stats_dict_item(self, ohlcv: OHLCV, ta_data: TaData):
        return {
            'RSI': ta_data.RSI,
            'CLS': ohlcv.close
        }

    def stats_dict_item_to_string(self, item) -> str:
        return (f"CLS = {item['CLS']:.2f}\tRSI = {item['RSI']:.0f}")

    def get_stats_for_step(self, step: StepData) -> str:
        return (f'MA_diff = {step.ta_data.SMA_diff:.1f}')
