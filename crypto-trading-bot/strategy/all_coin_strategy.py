from abc import abstractmethod
from data_types.ohlcv import OHLCV
from data_types.ta_data import TaData
from strategy.ta_based_strategy import TaBasedStrategy

class AllCoinStrategy(TaBasedStrategy):

    @abstractmethod
    def buy_condition(self, ohlcv: OHLCV, ta_data: TaData) -> bool:
        pass

    @abstractmethod
    def sell_condition(self, ohlcv: OHLCV, ta_data: TaData) -> bool:
        pass

    def row_processing_step(self, dt_str: str, dt_ts: int) -> list:

        trade_list = []

        for coin, step_data in self.step_dict.items():
            ohlcv = step_data.ohlcv
            ta_data = step_data.ta_data

            trade_action = None

            if (not self.portfolio.in_position(coin) and
                self.buy_condition(ohlcv, ta_data)):
                cash = self.calc_cash_for_trade(self.portfolio, len(self.coins))
                trade_action = self.portfolio.enter_position(step_data, ohlcv.close, cash)

            if (self.portfolio.in_position(coin) and self.sell_condition(ohlcv, step_data.ta_data)):
                trade_action = self.portfolio.exit_position(coin, dt_str, dt_ts)

            if trade_action:
                self.process_trade_action(trade_action, step_data)
                trade_list.append(trade_action)

        return trade_list