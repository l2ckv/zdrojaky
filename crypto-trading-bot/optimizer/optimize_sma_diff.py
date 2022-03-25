from calculations.big_table import BigTable
from data_types.sim_config import SimConfig
from data_types.start_stop_date import StartStopDate
from optimizer.optimization_function import optimization_function
from strategy.sma_diff_strategy import SMA_DifferenceStrategy

def optimize_SMA_diff(sim_cfg: SimConfig, sim_start_stop: StartStopDate,
    coins: list, big_table: BigTable):

    optr = {
        'high': [-3, 0, 3],
        'low': [-3, 0, 3]
    }

    result = optimization_function(strategy_name='SMA_Difference', sim_cfg=sim_cfg,
        sim_start_stop=sim_start_stop, coins=coins, big_table=big_table, optr=optr,
        create_strategy_fun=lambda sim_cfg, start_stop_date, params:
            SMA_DifferenceStrategy(sim_cfg, start_stop_date, params))
    return result
