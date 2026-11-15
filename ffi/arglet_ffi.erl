%% SPDX-License-Identifier: Apache-2.0

%%% Gather the three travellers before asking where they intend to go.
%%%
%%% Erlang keeps runtime options and plain program arguments in separate places.
%%% Bring back the runtime path, the program location and the user arguments,
%%% with each in its own seat. Convert character lists to UTF-8 binaries for
%%% Pooka, but leave flag parsing to the person who invited the arguments.
%%%
%%% ```erlang
%%% {Runtime, Program, Arguments} = arglet_ffi:load().
%%% %% Runtime and Program are binaries; Arguments is a list of binaries.
%%% ```
-module(arglet_ffi).

-export([load/0]).

%% Read the guest list without rearranging it.
%%
%% Return the three pieces in the order expected by the Pooka Argv wrapper.
%%
%% The executable path comes from the VM's bindir and progname boot arguments.
%% For an escript, the first plain argument is its script path; keep it out of
%% the user arguments. With an ordinary Erlang launch, keep every plain argument
%% and use the current working directory as the program location.
%%
%% ```text
%% escript: ["./lantern", "north", "south"]
%%       -> {Runtime, <<"./lantern">>, [<<"north">>, <<"south">>]}
%% ordinary launch: ["north", "south"]
%%       -> {Runtime, WorkingDirectory, [<<"north">>, <<"south">>]}
%% ```
load() ->
    %% Let the host choose its separators. An absolute progname has already
    %% brought its full address; filename:join/2 keeps that address intact.
    Runtime = filename:join(stringarg(bindir), stringarg(progname)),
    PlainArguments = [unicode:characters_to_binary(Arg, utf8)
                      || Arg <- init:get_plain_arguments()],
    IsEscript = case init:get_argument(escript) of
        {ok, _} -> true;
        _ -> false
    end,
    {Program, Arguments} = program_arguments(IsEscript, PlainArguments),
    {Runtime, Program, Arguments}.

%% Give the script its own seat, rather than counting it as a visitor.
%% An escript marker without a path is an invalid invitation. Name the missing
%% piece instead of quietly pretending this was an ordinary Erlang launch.
%%
%% ```text
%% [<<"./lantern">>, <<"north">>] -> {<<"./lantern">>, [<<"north">>]}
%% ```
program_arguments(true, [Program | Arguments]) when Program =/= <<>> ->
    {Program, Arguments};
program_arguments(true, _) ->
    erlang:error({arglet, missing_escript_path});
program_arguments(false, Arguments) ->
    case file:get_cwd() of
        {ok, Cwd} -> {unicode:characters_to_binary(Cwd, utf8), Arguments};
        {error, Reason} -> erlang:error({arglet, working_directory_unavailable, Reason})
    end.

%% Each boot argument owes us one usable value.
%% If it never arrives, say which one is missing. If it arrives in several
%% pieces or cannot become UTF-8, say that too. An empty binary would only send
%% the caller looking for an executable at an address we had invented.
%%
%% ```erlang
%% %% init:get_argument(bindir) -> {ok, [["/opt/erlang/bin"]]}
%% %% stringarg(bindir)        -> <<"/opt/erlang/bin">>
%% ```
stringarg(Name) ->
    case init:get_argument(Name) of
        error -> erlang:error({arglet, missing_runtime_argument, Name});
        {ok, [[Value]]} when is_list(Value), Value =/= [] ->
            try unicode:characters_to_binary(Value, utf8) of
                Binary when is_binary(Binary), Binary =/= <<>> -> Binary;
                _ -> erlang:error({arglet, invalid_runtime_argument, Name})
            catch
                error:badarg -> erlang:error({arglet, invalid_runtime_argument, Name})
            end;
        _ -> erlang:error({arglet, invalid_runtime_argument, Name})
    end.
