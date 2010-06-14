%% -----------------------------------------------------------------------------
%%
%% Hamcrest Erlang.
%%
%% Copyright (c) 2010 Tim Watson (watson.timothy@gmail.com)
%%
%% Permission is hereby granted, free of charge, to any person obtaining a copy
%% of this software and associated documentation files (the "Software"), to deal
%% in the Software without restriction, including without limitation the rights
%% to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
%% copies of the Software, and to permit persons to whom the Software is
%% furnished to do so, subject to the following conditions:
%%
%% The above copyright notice and this permission notice shall be included in
%% all copies or substantial portions of the Software.
%%
%% THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
%% IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
%% FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
%% AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
%% LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
%% OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
%% THE SOFTWARE.
%% -----------------------------------------------------------------------------
%% @author Tim Watson <watson.timothy@gmail.com>
%% @copyright 2010 Tim Watson.
%% @doc Hamcrest Matchers
%% @reference See <a href="http://code.google.com/p/hamcrest/">Hamcrest</a>
%% for more information.
%% -----------------------------------------------------------------------------

-module(hamcrest_matchers).
-author('Tim Watson <watson.timothy@gmail.com>').

-include("hamcrest_internal.hrl").

-import(hamcrest, [message/4]).

-export([
    anything/0,
    any_of/1,
    is/1,
    is_not/1,
    equal_to/1,
    exactly_equal_to/1,
    greater_than/1,
    greater_than_or_equal_to/1,
    less_than/1,
    less_than_or_equal_to/1,
    contains_string/1,
    starts_with/1,
    ends_with/1,
    will_fail/0,
    will_fail/2]).

-spec(will_fail/0 :: () -> fun((fun(() -> any())) -> any())).
will_fail() ->
    Matcher =
    fun(F) ->
        try F() of
            _ -> false
        catch _:_ -> true
        end
    end,
    #'hamcrest.matchspec'{
        matcher     = Matcher,
        desc        = expected_fail,
        expected    = undefined
    }.

-spec(will_fail/2 :: (atom(), term()) -> #'hamcrest.matchspec'{}).
will_fail(Type, Reason) ->
    Matcher =
    fun(F) ->
        try F() of
            _ -> false
        catch Type:With -> true
        end
    end,
    #'hamcrest.matchspec'{
        matcher     = Matcher,
        desc        = expected_fail,
        expected    = {Type, Reason}
    }.

-spec(anything/0 :: () -> fun((term()) -> true)).
anything() ->
    fun(_) -> true end.

-spec(any_of/1 :: (list(fun((term()) -> boolean()))) -> #'hamcrest.matchspec'{};
                  (list(#'hamcrest.matchspec'{})) -> #'hamcrest.matchspec'{}).
any_of(Matchers) when is_list(Matchers) ->
    MatchFun =
    fun(M) when is_function(M) -> M;
       (#'hamcrest.matchspec'{matcher=F}) -> F
    end,
    fun(X) -> lists:member(true, [ (MatchFun(M))(X) || M <- Matchers ]) end.

-spec(equal_to/1 :: (term()) -> #'hamcrest.matchspec'{}).
equal_to(Y) ->
    #'hamcrest.matchspec'{
        matcher     = fun(X) -> X == Y end,
        desc        = fun(Expected,Actual) ->
                        message(value, "equal to", Expected, Actual)
                      end,
        expected    = Y
    }.

-spec(exactly_equal_to/1 :: (term()) -> #'hamcrest.matchspec'{}).
exactly_equal_to(X) ->
    #'hamcrest.matchspec'{
        matcher     = fun(Y) -> X =:= Y end,
        desc        = fun(Expected,Actual) ->
                        message(value, "exactly equal to", Expected, Actual)
                      end,
        expected    = X
    }.

-spec(is/1 :: (Y::fun((X::term()) -> boolean())) -> fun((X::term()) -> boolean());
              (Y::#'hamcrest.matchspec'{}) -> #'hamcrest.matchspec'{};
              (Y) -> fun((Y) -> boolean())).
is(Matcher) when is_function(Matcher) ->
    Matcher;
is(Matcher) when is_record(Matcher, 'hamcrest.matchspec') ->
    Matcher;
is(Term) ->
    equal_to(Term).

-spec(is_not/1 :: (Y::fun((X::term()) -> boolean())) -> fun((X::term()) -> boolean());
                  (Y::#'hamcrest.matchspec'{}) -> #'hamcrest.matchspec'{};
                  (term()) -> #'hamcrest.matchspec'{}).
is_not(Matcher) when is_function(Matcher, 1) ->
    fun(X) -> not(Matcher(X)) end;
is_not(#'hamcrest.matchspec'{ matcher=MatchFun }=MatchSpec) when is_record(MatchSpec, 'hamcrest.matchspec') ->
    MatchSpec#'hamcrest.matchspec'{ matcher = (fun(X) -> not(MatchFun(X)) end) };
is_not(Term) ->
    is_not(equal_to(Term)).

-spec(greater_than/1 :: (number()) -> #'hamcrest.matchspec'{}).
greater_than(X) ->
    #'hamcrest.matchspec'{
        matcher     = fun(Y) -> Y > X end,
        desc        = fun(Expected,Actual) ->
                        message(value, "greater than", Expected, Actual)
                      end,
        expected    = X
    }.

-spec(greater_than_or_equal_to/1 :: (number()) -> #'hamcrest.matchspec'{}).
greater_than_or_equal_to(X) ->
    #'hamcrest.matchspec'{
        matcher     = fun(Y) -> Y >= X end,
        desc        = fun(Expected,Actual) ->
                        message(value, "greater than or equal to", Expected, Actual)
                      end,
        expected    = X
    }.

-spec(less_than/1 :: (number()) -> #'hamcrest.matchspec'{}).
less_than(X) ->
    #'hamcrest.matchspec'{
        matcher     = fun(Y) -> Y < X end,
        desc        = fun(Expected,Actual) ->
                        message(value, "less than", Expected, Actual)
                      end,
        expected    = X
    }.

-spec(less_than_or_equal_to/1 :: (number()) -> #'hamcrest.matchspec'{}).
less_than_or_equal_to(X) ->
    #'hamcrest.matchspec'{
        matcher     = fun(Y) -> Y =< X end,
        desc        = fun(Expected,Actual) ->
                        message(value, "less than or equal to", Expected, Actual)
                      end,
        expected    = X
    }.

-spec(contains_string/1 :: (string()) -> fun((string()) -> boolean())).
contains_string([_|_]=X) ->
    fun(Y) -> string:str(Y, X) > 0 end.

-spec(starts_with/1 :: (string()) -> fun((string()) -> boolean())).
starts_with(X) ->
    fun(Y) -> string:str(Y, X) == 1 end.

-spec(ends_with/1 :: (string()) -> fun((string()) -> boolean())).
ends_with(X) ->
    fun(Y) -> string:equal(string:right(Y, length(X)), X) end.
