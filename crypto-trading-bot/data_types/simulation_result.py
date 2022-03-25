from calculations.big_table import *
from portfolio.simulated_portfolio import SimulatedPortfolio
from calculations.valuations import calc_weighted_valuation

class SimulationResult:

    def __init__(self, portfolio: SimulatedPortfolio, coin_list: list):
        self.portfolio = portfolio
        self.pnl_dict = {coin: Decimal(0) for coin in coin_list}
        self.action_log = []
        self.coins_left = []
        self.output_table = None
        self.signal_table = None
        self.used_coins = []

    def prepare_signal_table(self, signal_dict: dict[str, list]):
        self.signal_table = pd.DataFrame.from_dict(signal_dict)
        self.signal_table = self.signal_table.astype({'Datetime_UNIX': int})
        self.signal_table.set_index('Datetime_UNIX', inplace=True)
        self.signal_table = self.signal_table.loc[:, self.signal_table.any()]
        self.used_coins = list(filter(lambda clmn: clmn.startswith('Datetime') == False,
            self.signal_table.columns))

    def prepare_output_table(self, output_dict: dict[str, list]):
        self.output_table = pd.DataFrame.from_dict(output_dict)
        self.output_table = self.output_table.astype({'Datetime_UNIX': int})
        self.output_table.set_index('Datetime_UNIX', inplace=True)
        self.output_table = self.output_table.loc[:, self.output_table.any()]

    def get_action_log(self, last_n: int = None) -> str:
        if last_n:
            return '\n'.join(self.action_log[-last_n:])
        else:
            return '\n'.join(self.action_log)

    def __str__(self) -> str:
        output = self.portfolio.__str__()
        sorted_pnl_dict = dict(sorted(self.pnl_dict.items(),
            key=lambda item: item[1], reverse=True))
        for coin, pnl in sorted_pnl_dict.items():
            if pnl == 0:
                continue
            output += f'{coin}: {pnl:.2f}\n'
        output += f'Current coins: ' + ' '.join(self.coins_left) + '\n'
        valuation = calc_weighted_valuation(self.output_table)
        output += f'Valuation: {valuation:.2f}'
        return output