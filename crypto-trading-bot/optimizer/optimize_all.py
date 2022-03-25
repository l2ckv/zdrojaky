import copy
from data_types.sim_config import SimConfig
from data_types.start_stop_date import StartStopDate
from data_types.optimization_result import OptimizationResult
from optimizer.optimize_sma_diff import optimize_SMA_diff
from optimizer.optimize_sorted import optimize_sorted
from strategy.buy_and_hold_strategy import BuyAndHoldStrategy
from calculations.valuations import calc_weighted_valuation
import logging
import pandas as pd

opt_funs = {
    'SMA_diff': optimize_SMA_diff,
    'Sorted-Coin': optimize_sorted
}

def optimize_all(sim_cfg: SimConfig, sim_start_stop: StartStopDate, coins: list,
    big_pd: pd.DataFrame, print_result: bool = False):

    base_strategy = BuyAndHoldStrategy(sim_cfg, sim_start_stop)
    base_strategy.load_data(big_pd, coins)
    best_opt_result = OptimizationResult('Buy & Hold', 'Best')
    buy_and_hold_result = base_strategy.simulate(False)
    best_opt_result.sim_result = buy_and_hold_result
    best_opt_result.valuation = calc_weighted_valuation(buy_and_hold_result.output_pd)
    all_results = [best_opt_result]
    logging.debug(f'Valuation for Buy&Hold: {best_opt_result.valuation:.2f}')

    for function in opt_funs.values():
        cur_opt_result = function(sim_cfg, sim_start_stop, coins, big_pd)
        all_results.append(cur_opt_result)
        if cur_opt_result.valuation > best_opt_result.valuation:
            best_opt_result = copy.deepcopy(cur_opt_result)
            logging.debug('Found a new best_opt_result')
            logging.debug(best_opt_result)

    logging.debug('At end of function optimize_all(), here is best_opt_result')
    logging.debug(best_opt_result)

    sorted_results = sorted(all_results, key = lambda OR: OR.valuation)
    sorted_dict = {}
    for single_result in sorted_results:
        if print_result:
            print(single_result)
        sorted_dict[single_result.strategy_name] = single_result

    return sorted_dict