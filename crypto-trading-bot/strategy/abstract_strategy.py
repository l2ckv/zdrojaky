from abc import ABC, abstractmethod
from decimal import Decimal
import logging
from calculations.big_table import BigTable
from data_types.sim_config import SimConfig
from data_types.start_stop_date import StartStopDate
from data_types.simulation_result import SimulationResult
from portfolio.simulated_portfolio import SimulatedPortfolio
from portfolio.trade_action import BuyAction, SellAction, TradeAction
from data_types.step_data import BasicStepData

class AbstractStrategy(ABC):

    def __init__(self, sim_cfg: SimConfig, start_stop: StartStopDate):
        self.big_table = None
        self.coins = None
        self.done = False
        self.sim_cfg = sim_cfg
        self.start_stop = start_stop
        self.step_dict = {}

    @abstractmethod
    def simulate(self) -> SimulationResult:
        pass

    @abstractmethod
    def init_output_dict_extras(self):
        pass

    @abstractmethod
    def fill_output_row_extras(self):
        pass

    def load_data(self, big_table: BigTable, coins: list):
        self.big_table = big_table
        self.coins = coins
        self.init_output_dict()
        self.portfolio = SimulatedPortfolio(self.sim_cfg)
        self.result = SimulationResult(self.portfolio, coins)
        self.done = False

    def __create_buy_msg(self, step: BasicStepData, buy_action: BuyAction):
        return (f'{step.dt_str}: Buy  {buy_action.coin_amount:.4f} ' +
                f'{step.coin} for {buy_action.cash_total:.2f} USD, ' +
                f'price = {buy_action.price}')

    def __create_sell_msg(self, step: BasicStepData, sell_action: SellAction):
        return (f'{step.dt_str}: Sell {sell_action.coin_amount:.4f} {step.coin} for ' +
                f'{sell_action.cash_total:.2f} USD, ' +
                f'price = {sell_action.price}, ' +
                f', P&L = {sell_action.pnl:.2f}')

    def process_trade_action(self, trade_action: TradeAction, step: BasicStepData):

        if trade_action and type(trade_action) is BuyAction:
            buy_msg = self.__create_buy_msg(step, trade_action)
            self.result.action_log.append(buy_msg)

        if trade_action and type(trade_action) is SellAction:
            sell_msg = self.__create_sell_msg(step, trade_action)
            self.result.action_log.append(sell_msg)

    def init_output_dict(self):
        self.output_dict = {'Datetime_UNIX': [], 'Datetime': []}
        for coin in self.coins:
            self.output_dict[f'{coin}.QTY'] = []
            self.output_dict[f'{coin}.Value'] = []
            self.output_dict[f'{coin}.Price'] = []
        self.output_dict['N coins'] = []
        self.output_dict['Equity'] = []
        self.output_dict['Free capital'] = []
        self.output_dict['Bank account'] = []
        self.output_dict['Coins'] = []
        self.output_dict['Allocations'] = []
        self.init_output_dict_extras()

    def fill_output_row(self, dt_ts: int, dt_str: str):
        self.output_dict['Datetime_UNIX'].append(dt_ts)
        self.output_dict['Datetime'].append(dt_str)
        for coin in self.coins:
            qty, val, price = self.portfolio.get_position(coin)
            self.output_dict[f'{coin}.QTY'].append(qty)
            self.output_dict[f'{coin}.Value'].append(val)
            self.output_dict[f'{coin}.Price'].append(price)
        self.output_dict['N coins'].append(self.portfolio.n_positions)
        self.output_dict['Equity'].append(self.portfolio.get_equity())
        self.output_dict['Free capital'].append(self.portfolio.get_free_cap())
        self.output_dict['Bank account'].append(self.portfolio.bank_account)
        self.output_dict['Coins'].append(list(self.portfolio.get_open_positions()))
        self.output_dict['Allocations'].append(self.portfolio.get_allocation_string())
        self.fill_output_row_extras()

    def calc_cash_for_trade(self, portfolio: SimulatedPortfolio, n_coins: int) -> Decimal:
        n_positions = portfolio.get_n_positions()
        if n_coins == n_positions:
            logging.warning('Zero cash for trade')
            return Decimal(0)
        cash = Decimal(portfolio.get_free_cap() / (n_coins  - n_positions))
        return cash