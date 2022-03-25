import itertools
import logging

def create_combinations(optr: dict) -> list[dict]:
    optr_list = []
    for key in optr.keys():
        optr_list.append([(key, value) for value in optr[key]])
    logging.debug(optr_list)
    
    all_combis = list(itertools.product(*optr_list))
    new_combis = []
    for combi in all_combis:
        new_dict = {}
        for item in combi:
            new_dict[item[0]] = item[1]
        new_combis.append(new_dict)
    return new_combis