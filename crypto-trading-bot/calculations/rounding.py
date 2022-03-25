from database.read_db import *
from decimal import *

coin_filters = get_symbol_filters_from_db(EXCHANGE)

def round_qty_down(coin: str, qty: Decimal) -> Decimal:
    
    if qty <= 0:
        raise AssertionError(f'Trying to round negative qty {qty} for {coin}')

    my_filter = coin_filters[coin]
    qty_as_decimal = Decimal(qty)
    step_size = my_filter.qty_step_size.normalize()
    result = qty_as_decimal.quantize(step_size, rounding=ROUND_DOWN)
    return result

def round_price_down(coin: str, price: Decimal) -> Decimal:

    if price <= 0:
        raise AssertionError(f'Trying to round negative price {price} for {coin}')

    my_filter = coin_filters[coin]
    price_as_decimal = Decimal(price)
    tick_size = my_filter.price_tick_size.normalize()
    result = price_as_decimal.quantize(tick_size, rounding=ROUND_DOWN)
    return result

def round_price_up(coin: str, price: Decimal) -> Decimal:

    if price <= 0:
        raise AssertionError(f'Trying to round negative price {price} for {coin}')

    my_filter = coin_filters[coin]
    price_as_decimal = Decimal(price)
    tick_size = my_filter.price_tick_size.normalize()
    result = price_as_decimal.quantize(tick_size, rounding=ROUND_UP)
    return result