-module(e_shop).
-behavior(gen_server).
-compile(export_all).

-record(e_shop_state,
	{
		users = dict:new(),
		items = [],
		item_count = 0,
		orders = [],
		order_count = 0
	}).
-record(e_shop_user_data,
	{
		password,
		orders = []
	}).
-record(e_shop_item,
	{
		id,
		added_by,
		name,
		description,
		price
	}).
-record(e_shop_order_item,
	{
		item_id,
		quantity,
		price
	}).
-record(e_shop_order,
	{
		id,
		user,
		items,
		total,
		state_actor_pid
	}).

-define(TIME_UNIT, 100).

start_link() ->
	gen_server:start_link({local, e_shop}, ?MODULE, [], []).

register_user(Username, Password) ->
	gen_server:call(e_shop, {register, Username, Password}).

log_in(Username, Password, Timeout) ->
	gen_server:call(e_shop, {log_in, Username, Password, Timeout}).

log_out(SessionId) ->
	gen_server:call(e_shop, {log_out, SessionId}).

get_all_items(SessionId) ->
	StringResult = gen_server:call(e_shop, {get_all_items, SessionId}),
	io:format("~s~n", [StringResult]).

add_new_item(SessionId, Name, Description, Price) ->
	gen_server:call(e_shop, {add_new_item, SessionId, Name, Description, Price}).

make_order(SessionId, Items) ->
	gen_server:call(e_shop, {make_order, SessionId, Items}).

get_my_orders(SessionId) ->
	StringResult = gen_server:call(e_shop, {get_my_orders, SessionId}),
	io:format("~s~n", [StringResult]).

get_order_state(SessionId, OrderId) ->
	gen_server:call(e_shop, {get_order_state, SessionId, OrderId}).

init(_Args) ->
	{ok, #e_shop_state{}}.

get_password_for_user(Username, State) ->
	UserDict = State#e_shop_state.users,
	case dict:find(Username, UserDict) of
		{ok, UserData} ->
			UserPassword = UserData#e_shop_user_data.password,
			{ok, UserPassword};
		error ->
			no_such_user
	end.
	
handle_call({register, Username, Password}, _From, State) ->
	UserDict = State#e_shop_state.users,
	case dict:find(Username, UserDict) of
		{ok, _Value} ->
			{reply, user_already_exists, State};
		error ->
			NewUserData = #e_shop_user_data
			{
				password = Password
			},
			NewUsers = dict:store(Username, NewUserData, UserDict),
			NewState = State#e_shop_state
			{
				users = NewUsers
			},
			io:format("registered user ~s~n", [Username]),
			{reply, registration_ok, NewState}
	end;

handle_call({log_in, Username, Password, Timeout}, _From, State) ->
	QueryResult = get_password_for_user(Username, State),
	case QueryResult of
		{ok, RealPassword} ->
			case string:equal(RealPassword, Password) of
				true ->
					SessionPid = spawn(?MODULE, session_actor, [Username, Timeout]),
					{reply, {ok, SessionPid}, State};
				false ->
					{reply, invalid_password, State}
			end;
		no_such_user ->
			{reply, no_such_user, State}
	end;

handle_call({log_out, SessionId}, _From, State) ->
	check_auth_and_perform_action(SessionId, State, fun(_) ->
		SessionId ! {self(), destroy_session},
		receive
			{SessionId, ok} ->
				{reply, log_out_ok, State}
		after ?TIME_UNIT ->
			io:format("session lost~n"),
			{reply, log_out_error, State}
		end
	end);

handle_call({get_all_items, SessionId}, _From, State) ->
	check_auth_and_perform_action(SessionId, State, fun(_) ->
		ItemData = State#e_shop_state.items,
		ItemString = item_list_to_string(ItemData),
		{reply, ItemString, State}
	end);

handle_call({add_new_item, SessionId, Name, Description, Price}, _From, State) ->
	check_auth_and_perform_action(SessionId, State, fun(Username) ->
		OldItemCount = State#e_shop_state.item_count,
		NewItemCount = OldItemCount + 1,
		NewItemID = NewItemCount,
		NewItem = #e_shop_item
		{
			id = NewItemID,
			added_by = Username,
			name = Name,
			description = Description,
			price = Price
		},
		OldItems = State#e_shop_state.items,
		NewItems = [ NewItem | OldItems ],
		NewState = State#e_shop_state
		{
			items = NewItems,
			item_count = NewItemCount
		},
		{reply, item_added, NewState}
	end);

handle_call({make_order, SessionId, Items}, _From, State) ->
	check_auth_and_perform_action(SessionId, State, fun(Username) ->
	
		OldOrderCount = State#e_shop_state.order_count,
		NewOrderCount = OldOrderCount + 1,
		NewOrderID = NewOrderCount,
		
		StateActorPid = spawn(
			?MODULE, order_state_keeping_actor,
			[NewOrderID, placed]),
		
		NewOrder = #e_shop_order
		{
			id = NewOrderID,
			user = Username,
			items = Items,
			total = calculate_order_total(Items),
			state_actor_pid = StateActorPid
		},
		
		UserUpdateFun = fun(OldUserData) ->
			OldOrders = OldUserData#e_shop_user_data.orders,
			NewOrders = [ NewOrderID | OldOrders ],
			OldUserData#e_shop_user_data
			{
				orders = NewOrders
			}
		end,
		UserDict = State#e_shop_state.users,
		NewUsers = dict:update(Username, UserUpdateFun, UserDict),
		
		OldOrders = State#e_shop_state.orders,
		NewOrders = [ NewOrder | OldOrders ],
		NewState = State#e_shop_state
		{
			users = NewUsers,
			orders = NewOrders,
			order_count = NewOrderCount
		},
		
		spawn(?MODULE, order_state_changing_actor, [NewOrderID]),
		
		{reply, {order_placed, NewOrderID}, NewState}
	end);

handle_call({get_my_orders, SessionId}, _From, State) ->
	check_auth_and_perform_action(SessionId, State, fun(Username) ->
		UserDict = State#e_shop_state.users,
		UserData = dict:fetch(Username, UserDict),
		OrderIdList = UserData#e_shop_user_data.orders,
		UserOrders = lists:filter(fun(Elem) ->
			lists:member(Elem#e_shop_order.id, OrderIdList)
		end, State#e_shop_state.orders),
		FormattedOrders = order_list_to_string(UserOrders),
		{reply, FormattedOrders, State}
	end);

handle_call({get_order_state, SessionId, OrderId}, _From, State) ->
	check_auth_and_perform_action(SessionId, State, fun(Username) ->
		UserDict = State#e_shop_state.users,
		UserData = dict:fetch(Username, UserDict),
		OrderIdList = UserData#e_shop_user_data.orders,
		case lists:member(OrderId, OrderIdList) of
			true ->
				OrderData = get_order_data(State, OrderId),
				OrderState = fetch_order_state(OrderData),
				{reply, OrderState, State};
			false ->
				{reply, no_such_order, State}
		end
	end).

get_order_data(State, OrderId) ->
	% could be more effective since
	% only one item will match
	OrderDataList = lists:filter(fun(Elem) ->
		Elem#e_shop_order.id =:= OrderId
	end, State#e_shop_state.orders),
	[ OrderData | [] ] = OrderDataList,
	OrderData.

fetch_order_state(OrderData) ->
	StateActorPid = OrderData#e_shop_order.state_actor_pid,
	StateActorPid ! {self(), get_order_state},
	receive
		{StateActorPid, OrderState} ->
			{ok, OrderState}
	after
		?TIME_UNIT ->
			error
	end.

order_list_to_string(OrderList) ->
	string:join(lists:map(fun(Order) ->
		FormatString = "ID: ~B, Total: ~w",
		lists:flatten(io_lib:format(FormatString,
			[Order#e_shop_order.id,
			 Order#e_shop_order.total]))
	end, OrderList), "\r\n").

item_list_to_string(ItemList) ->
	string:join(lists:map(fun(Item) ->
		FormatString =
			"ID: ~B, Added by: ~s, Name: ~s, " ++
			"Description: ~s, Price: ~.2f",
		lists:flatten(io_lib:format(FormatString,
			[Item#e_shop_item.id,
			 Item#e_shop_item.added_by,
			 Item#e_shop_item.name,
			 Item#e_shop_item.description,
			 Item#e_shop_item.price]))
	end, ItemList), "\r\n").

calculate_order_total(Items) ->
	Subtotals = lists:map(fun(OrderItem) ->
		Price = OrderItem#e_shop_order_item.price,
		Quantity = OrderItem#e_shop_order_item.quantity,
		Price * Quantity
	end, Items),
	lists:sum(Subtotals).
	
check_auth_and_perform_action(SessionId, State, Action) ->
	SessionId ! {self(), check_existence},
	AuthResult = receive
		{SessionId, ReceivedUsername} ->
			{auth_ok, ReceivedUsername}
	after
		?TIME_UNIT ->
			no_such_session
	end,
	case AuthResult of
		{auth_ok, Username} ->
			Action(Username);
		no_such_session ->
			{reply, no_such_session, State}
	end.

session_actor(Owner, Timeout) ->
	receive
		{From, check_existence} ->
			From ! {self(), Owner};
		{From, destroy_session} ->
			From ! {self(), ok},
			io:format("session of user ~s exiting (log out)~n", [Owner]),
			exit(normal);
		_ ->
			io:format("session_actor: received unknown data~n")
	after
		Timeout * ?TIME_UNIT ->
			io:format("session of user ~s timed out~n", [Owner]),
			exit(normal)
	end,
	session_actor(Owner, Timeout).

order_state_changing_actor(OrderId) ->
	receive
	after
		?TIME_UNIT ->
			gen_server:cast(?MODULE, {change_order_state, OrderId, packaged})
	end,
	receive
	after
		?TIME_UNIT * 2 ->
			gen_server:cast(?MODULE, {change_order_state, OrderId, shipped})
	end,
	receive
	after
		?TIME_UNIT * 5 ->
			gen_server:cast(?MODULE, {change_order_state, OrderId, delivered})
	end.

order_state_keeping_actor(OrderId, State) ->
	receive
		{Pid, get_order_state} ->
			Pid ! {self(), State},
			order_state_keeping_actor(OrderId, State);
		{Pid, change_order_state, NewState} ->
			Pid ! {self(), ok},
			order_state_keeping_actor(OrderId, NewState);
		_ ->
			io:format("order_state_keeping_actor: received unknown data~n")
	end.
			
handle_cast({change_order_state, OrderId, NewState}, State) ->
	io:format("changing state of order ~B to ~p~n", [OrderId, NewState]),
	OrderData = get_order_data(State, OrderId),
	StateKeepingActorPid = OrderData#e_shop_order.state_actor_pid,
	StateKeepingActorPid ! {self(), change_order_state, NewState},
	receive
		{StateKeepingActorPid, ok} ->
			io:format("state change ok~n")
	after
		?TIME_UNIT ->
			io:format("could not change order state~n")
	end,
	{noreply, State}.

handle_info(_Msg, _State) ->
	ok.

terminate(_Reason, _State) ->
	ok.

code_change(_OldVersion, _State, _Extra) ->
	ok.

test1_user_operations() ->
	registration_ok = register_user("user1", "pass1"),
	user_already_exists = register_user("user1", "pass1"),
	no_such_user = log_in("baduser", "badpass", 5),
	invalid_password = log_in("user1", "badpass", 5),
	{ok, User1Login} = log_in("user1", "pass1", 5),
	log_out_ok = log_out(User1Login),
	registration_ok = register_user("user2", "pass2"),
	{ok, User2Login} = log_in("user2", "pass2", 1),
	receive
	after
		?TIME_UNIT * 2 ->
			no_such_session = log_out(User2Login)
	end,
	ok.

test2_item_operations() ->
	{ok, User1Login} = log_in("user1", "pass1", 5),
	item_added = add_new_item(User1Login, "title1", "text1", 5.00),
	item_added = add_new_item(User1Login, "title2", "text2", 10.00),
	AllItems = get_all_items(User1Login),
	log_out_ok = log_out(User1Login),
	AllItems.

test3_order_operations() ->
	{ok, User2Login} = log_in("user2", "pass2", 10),
	OrderItems1 = 
	[
		#e_shop_order_item
		{
			item_id = 1,
			quantity = 3,
			price = 5.00
		},
		#e_shop_order_item
		{
			item_id = 2,
			quantity = 5,
			price = 10.00
		}
	],
	{order_placed, OrderId} = make_order(User2Login, OrderItems1),	
	MyOrders = get_my_orders(User2Login),
	{ok, placed} = get_order_state(User2Login, OrderId),
	receive
	after
		?TIME_UNIT * 2 ->
			{ok, packaged} = get_order_state(User2Login, OrderId)
	end,
	receive
	after
		?TIME_UNIT * 2 ->
			{ok, shipped} = get_order_state(User2Login, OrderId)
	end,
	receive
	after
		?TIME_UNIT * 5 ->
			{ok, delivered} = get_order_state(User2Login, OrderId)
	end,
	log_out_ok = log_out(User2Login),
	MyOrders.