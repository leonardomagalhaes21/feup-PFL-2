:- use_module(library(random)).
:- use_module(library(lists)).


% generate_marbles(-Marbles)
% Gera as peças iniciais do jogo (marbles) de forma aleatória e válida.
generate_marbles(Marbles) :-
    repeat,
    generate_marbles_aux(12, 12, [], Marbles),
    check_circular(Marbles),
    !.  % Para após gerar uma configuração válida.

% generate_marbles_aux(+OCount, +XCount, +Acc, -Marbles)
% Função auxiliar para gerar as peças. Termina quando não há mais peças a adicionar.
generate_marbles_aux(0, 0, Acc, Marbles) :-
    reverse(Acc, Marbles).

% Continua a gerar as peças enquanto houver peças restantes ('o' ou 'x').
generate_marbles_aux(OCount, XCount, Acc, Marbles) :-
    valid_choices(OCount, XCount, Acc, Choices),
    random_member(Choice, Choices),
    update_counts(Choice, OCount, XCount, NewOCount, NewXCount),
    generate_marbles_aux(NewOCount, NewXCount, [Choice | Acc], Marbles).


% valid_choices(+OCount, +XCount, +Acc, -Choices)
% Determina as escolhas válidas para a próxima peça ('o' ou 'x').
valid_choices(OCount, XCount, Acc, Choices) :-
    findall(o, (OCount > 0, can_place(o, Acc)), OList),
    findall(x, (XCount > 0, can_place(x, Acc)), XList),
    append(OList, XList, Choices).

% can_place(+Marble, +Acc)
% Verifica se uma peça pode ser colocada na posição atual, com base no estado do acumulador.
can_place(_, []).
can_place(Marble, [H | _]) :-
    Marble \= H.
can_place(Marble, [H1, H2 | _]) :-
    Marble = H1,
    Marble \= H2.
can_place(Marble, [H1 | _]) :-
    Marble \= H1.

% update_counts(+Marble, +OCount, +XCount, -NewOCount, -NewXCount)
% Atualiza os contadores de peças restantes ao adicionar uma nova peça.
update_counts(o, OCount, XCount, NewOCount, XCount) :-
    NewOCount is OCount - 1.
update_counts(x, OCount, XCount, OCount, NewXCount) :-
    NewXCount is XCount - 1.

% check_circular(+Marbles)
% Verifica se a configuração de peças não forma um ciclo (início e fim iguais).
check_circular([Head | Tail]) :-
    last(Tail, Last),
    Head \= Last.

% generate_random_board(-Board)
% Gera o tabuleiro inicial com as peças posicionadas de forma válida.
generate_random_board(Board) :-
    generate_marbles(Marbles),
    Marbles = [M1, M2, M3, M4, M5, M6, M7, M8, M9, M10, M11, M12, M13, M14, M15, M16, M17, M18, M19, M20, M21, M22, M23, M24],
    Board = [
        [empty, M1, M2, M3, M4, M5, M6, empty],
        [M24, empty, empty, empty, empty, empty, empty, M7],
        [M23, empty, empty, empty, empty, empty, empty, M8],
        [M22, empty, empty, empty, empty, empty, empty, M9],
        [M21, empty, empty, empty, empty, empty, empty, M10],
        [M20, empty, empty, empty, empty, empty, empty, M11],
        [M19, empty, empty, empty, empty, empty, empty, M12],
        [empty, M18, M17, M16, M15, M14, M13, empty]
    ].
