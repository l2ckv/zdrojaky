import copy
import time
from typing import Callable
from calculations.big_table import BigTable
from data_types.sim_config import SimConfig
from data_types.start_stop_date import StartStopDate
from data_types.optimization_result import OptimizationResult
from optimizer.create_combinations import create_combinations
from strategy.abstract_strategy import AbstractStrategy
from calculations.valuations import  calc_weighted_valuation
import logging
import random as rd

def optimization_function(strategy_name: str, sim_cfg: SimConfig,
    sim_start_stop: StartStopDate,
    coins: list, big_table: BigTable, optr: dict,
    create_strategy_fun: Callable[[SimConfig, StartStopDate, dict], AbstractStrategy],
    random = False, n_attempts = None):

    result = OptimizationResult(strategy_name, 'Best')

    new_combis = create_combinations(optr)
    logging.info(f'Trying strategy {strategy_name}')
    logging.info(f'Number of combinations: {len(new_combis)}')
    
    combis_to_try = []
    if random and n_attempts and n_attempts < len(new_combis):
        combis_to_try = rd.sample(new_combis, n_attempts)
    else:
        combis_to_try = new_combis

    for combi in combis_to_try:
        start = time.time()
        strategy = create_strategy_fun(sim_cfg, sim_start_stop, combi)
        strategy.load_data(big_table, coins)
        cur_result = strategy.simulate()
        cur_valuation = calc_weighted_valuation(cur_result.output_table)
        if result.sim_result is None or cur_valuation > result.valuation:
            result.valuation = cur_valuation
            result.sim_result = copy.deepcopy(cur_result)
            result.winning_params = combi
            logging.info(f'New best result, valuation = {cur_valuation:.2f}, time={time.time() - start:.1f}s')
            logging.info(result.winning_params)

    return result