:- consult('board.pl').

default(empty).

char(o, 'O').
char(x, 'X').
char(empty, ' ').

player(1, player1).
player(2, player2).

switch_player(o, x).
switch_player(x, o).

board([
    [empty, o, o, x, x, o, o, empty],
    [x, empty, empty, empty, empty, empty, empty, x],
    [x, empty, empty, empty, empty, empty, empty, x],
    [o, empty, empty, empty, empty, empty, empty, o],
    [o, empty, empty, empty, empty, empty, empty, o],
    [x, empty, empty, empty, empty, empty, empty, x],
    [x, empty, empty, empty, empty, empty, empty, x],
    [empty, o, o, x, x, o, o, empty]
]).

% between(+Low, +High, -Value)
% Gera um valor entre dois limites (Low e High), inclusive.
between(Low, High, Low) :- Low =< High.
between(Low, High, Value) :-
    Low < High,
    NextLow is Low + 1,
    between(NextLow, High, Value).

% sum_list(+List, -Sum)
% Calcula a soma dos elementos de uma lista.
sum_list([], 0).
sum_list([H|T], Sum) :-
    sum_list(T, S),
    Sum is H + S.

% max_list(+List, -Max)
% Determina o maior valor em uma lista.
max_list([X], X).
max_list([H|T], Max) :-
    max_list(T, M),
    Max is max(H, M).

% product_list(+List, -Product)
% Calcula o produto dos elementos de uma lista.
product_list([], 1).
product_list([H|T], Product) :- 
    product_list(T, P), 
    Product is H * P.

% cell_player(+Board, +RowIdx, +ColIdx, +Player)
% Verifica se uma célula pertence ao jogador especificado.
cell_player(Board, RowIdx, ColIdx, Player) :-
    nth1(RowIdx, Board, Row),
    nth1(ColIdx, Row, Player).

% bfs(+Board, +Player, +Queue, +Visited, -Size, -NewVisited)
% Implementa a busca em largura (BFS) para calcular grupos conectados de células.
bfs(_, _, [], Visited, 0, Visited) :- !.
bfs(Board, Player, [[Row, Col] | Queue], Visited, Size, NewVisited) :- 
    \+ member([Row, Col], Visited),
    cell_player(Board, Row, Col, Player),
    findall(
        [R, C], 
        (neighbor([Row, Col], [R, C]),
         R > 0, R =< 8, C > 0, C =< 8, 
         cell_player(Board, R, C, Player), 
         \+ member([R, C], Visited)
        ), 
        Neighbors
    ),
    append(Queue, Neighbors, NewQueue),
    bfs(Board, Player, NewQueue, [[Row, Col] | Visited], S, NewVisited),
    Size is S + 1, !.
bfs(Board, Player, [_ | Queue], Visited, Size, NewVisited) :- 
    bfs(Board, Player, Queue, Visited, Size, NewVisited).

% calculate_largest_group(+Board, +Player, -MaxSize)
% Calcula o maior grupo de células conectadas para um jogador.
calculate_largest_group(Board, Player, MaxSize) :- 
    findall(Size, (
        member(RowIdx, [1,2,3,4,5,6,7,8]),
        member(ColIdx, [1,2,3,4,5,6,7,8]),
        cell_player(Board, RowIdx, ColIdx, Player), 
        bfs(Board, Player, [[RowIdx, ColIdx]], [], Size, _)
    ), Sizes), 
    max_list(Sizes, MaxSize).

% calculate_group_sizes(+Board, +Player, -Sizes)
% Calcula os tamanhos de todos os grupos conectados de células de um jogador.
calculate_group_sizes(Board, Player, Sizes) :- 
    calculate_group_sizes_aux(Board, Player, [], Sizes).

% calculate_group_sizes_aux(+Board, +Player, +Visited, -Sizes)
% Função auxiliar para calcular os tamanhos de grupos conectados.
calculate_group_sizes_aux(_, _, Visited, []) :- 
    length(Visited, L), L >= 64, !.
calculate_group_sizes_aux(Board, Player, Visited, Sizes) :- 
    member(RowIdx, [1,2,3,4,5,6,7,8]),
    member(ColIdx, [1,2,3,4,5,6,7,8]),
    \+ member([RowIdx, ColIdx], Visited),
    \+ cell_player(Board, RowIdx, ColIdx, Player),
    calculate_group_sizes_aux(Board, Player, [[RowIdx, ColIdx] | Visited], Sizes), !.
calculate_group_sizes_aux(Board, Player, Visited, [Size | Sizes]) :- 
    member(RowIdx, [1,2,3,4,5,6,7,8]), 
    member(ColIdx, [1,2,3,4,5,6,7,8]), 
    \+ member([RowIdx, ColIdx], Visited), 
    cell_player(Board, RowIdx, ColIdx, Player), 
    bfs(Board, Player, [[RowIdx, ColIdx]], Visited, Size, NewVisited),
    Size > 0,
    calculate_group_sizes_aux(Board, Player, NewVisited, Sizes), !.

% neighbor(+Cell, -Neighbor)
% Retorna as coordenadas das células vizinhas de uma célula especificada.
neighbor([Row, Col], [Row1, Col]) :- Row1 is Row - 1. % Célula acima
neighbor([Row, Col], [Row1, Col]) :- Row1 is Row + 1. % Célula abaixo
neighbor([Row, Col], [Row, Col1]) :- Col1 is Col - 1. % Célula à esquerda
neighbor([Row, Col], [Row, Col1]) :- Col1 is Col + 1. % Célula à direita

% calculate_scores(+Board, -OScore, -XScore, +Rules)
% Calcula as pontuações com base nas regras de jogo especificadas.
calculate_scores(Board, OScore, XScore, default_rules) :- 
    calculate_largest_group(Board, o, OScore),
    calculate_largest_group(Board, x, XScore).

calculate_scores(Board, OScore, XScore, optional_rules) :- 
    calculate_group_sizes(Board, o, OSizes),
    calculate_group_sizes(Board, x, XSizes),
    product_list(OSizes, OScore),
    product_list(XSizes, XScore).

% not_on_edge(+Cell)
% Verifica se uma célula está na borda do tabuleiro.
not_on_edge([EndRow, EndCol]) :-
    EndRow > 1, EndRow < 8,
    EndCol > 1, EndCol < 8.

% within_bounds(+Row, +Col)
% Verifica se uma célula está dentro dos limites do tabuleiro (1 a 8).
within_bounds(Row, Col) :-
    Row >= 1, Row =< 8,
    Col >= 1, Col =< 8.

% cell_belongs_to_player(+Board, +Cell, +Player)
% Verifica se uma célula pertence ao jogador especificado.
cell_belongs_to_player(Board, [Row, Col], Player) :-
    nth1(Row, Board, BoardRow),
    nth1(Col, BoardRow, Cell),
    Cell = Player.

% valid_direction(+Start, +End)
% Determina se o movimento é horizontal e válido.
valid_direction([StartRow, StartCol], [StartRow, EndCol]) :-
    StartCol \= EndCol.

% Determina se o movimento é vertical e válido.
valid_direction([StartRow, StartCol], [EndRow, StartCol]) :-
    StartRow \= EndRow.

% check_horizontal_slide(+Board, +Row, +StartCol, +EndCol)
% Verifica se o deslizamento horizontal da célula é válido.
check_horizontal_slide(Board, Row, StartCol, EndCol) :-
    StartCol < EndCol,
    check_horizontal_slide_left_to_right(Board, Row, StartCol, EndCol).
check_horizontal_slide(Board, Row, StartCol, EndCol) :-
    StartCol >= EndCol,
    check_horizontal_slide_right_to_left(Board, Row, StartCol, EndCol).

% check_horizontal_slide_left_to_right(+Board, +Row, +StartCol, +EndCol)
% Valida o deslizamento horizontal da esquerda para a direita.
check_horizontal_slide_left_to_right(Board, Row, StartCol, EndCol) :-
    findall(Cell, (
        C is EndCol - 1,
        between(StartCol, C, Col),
        nth1(Row, Board, BoardRow),
        nth1(Col, BoardRow, Cell),
        Cell \= empty
    ), Marbles),
    length(Marbles, M1),

    findall(Cell, (
        between(EndCol, 7, Col),
        nth1(Row, Board, BoardRow),
        nth1(Col, BoardRow, Cell),
        Cell = empty
    ), EmptySpaces),
    length(EmptySpaces, EmptyCount),

    EmptyCount >= M1.

% check_horizontal_slide_right_to_left(+Board, +Row, +StartCol, +EndCol)
% Valida o deslizamento horizontal da direita para a esquerda.
check_horizontal_slide_right_to_left(Board, Row, StartCol, EndCol) :-
    findall(Cell, (
        C is EndCol + 1,
        between(C, StartCol, Col),
        nth1(Row, Board, BoardRow),
        nth1(Col, BoardRow, Cell),
        Cell \= empty
    ), Marbles),
    length(Marbles, M1),

    findall(Cell, (
        between(2, EndCol, Col),
        nth1(Row, Board, BoardRow),
        nth1(Col, BoardRow, Cell),
        Cell = empty
    ), EmptySpaces),
    length(EmptySpaces, EmptyCount),

    EmptyCount >= M1.

% check_vertical_slide(+Board, +Col, +StartRow, +EndRow)
% Verifica se o deslizamento vertical da célula é válido.
check_vertical_slide(Board, Col, StartRow, EndRow) :-
    StartRow < EndRow,
    check_vertical_slide_top_to_bottom(Board, Col, StartRow, EndRow).
check_vertical_slide(Board, Col, StartRow, EndRow) :-
    StartRow >= EndRow,
    check_vertical_slide_bottom_to_top(Board, Col, StartRow, EndRow).

% check_vertical_slide_top_to_bottom(+Board, +Col, +StartRow, +EndRow)
% Valida o deslizamento vertical de cima para baixo.
check_vertical_slide_top_to_bottom(Board, Col, StartRow, EndRow) :-
    findall(Cell, (
        R is EndRow - 1,
        between(StartRow, R, Row),
        nth1(Row, Board, BoardRow),
        nth1(Col, BoardRow, Cell),
        Cell \= empty
    ), Marbles),
    length(Marbles, M1),

    findall(Cell, (
        between(EndRow, 7, Row),
        nth1(Row, Board, BoardRow),
        nth1(Col, BoardRow, Cell),
        Cell = empty
    ), EmptySpaces),
    length(EmptySpaces, EmptyCount),

    EmptyCount >= M1.

% check_vertical_slide_bottom_to_top(+Board, +Col, +StartRow, +EndRow)
% Valida o deslizamento vertical de baixo para cima.
check_vertical_slide_bottom_to_top(Board, Col, StartRow, EndRow) :-
    findall(Cell, (
        R is EndRow + 1,
        between(R, StartRow, Row),
        nth1(Row, Board, BoardRow),
        nth1(Col, BoardRow, Cell),
        Cell \= empty
    ), Marbles),
    length(Marbles, M1),

    findall(Cell, (
        between(2, EndRow, Row),
        nth1(Row, Board, BoardRow),
        nth1(Col, BoardRow, Cell),
        Cell = empty
    ), EmptySpaces),
    length(EmptySpaces, EmptyCount),

    EmptyCount >= M1.

% valid_slide(+Board, +Start, +End)
% Verifica se o deslizamento (horizontal ou vertical) é válido.
valid_slide(Board, [StartRow, StartCol], [StartRow, EndCol]) :-
    check_horizontal_slide(Board, StartRow, StartCol, EndCol).
valid_slide(Board, [StartRow, StartCol], [EndRow, StartCol]) :-
    check_vertical_slide(Board, StartCol, StartRow, EndRow).

% valid_move(+Board, +Start, +End, +Player)
% Verifica se um movimento específico é válido.
valid_move(Board, [StartRow, StartCol], [EndRow, EndCol], Player) :-
    not_on_edge([EndRow, EndCol]),
    \+ not_on_edge([StartRow, StartCol]),
    within_bounds(StartRow, StartCol),
    within_bounds(EndRow, EndCol),
    cell_belongs_to_player(Board, [StartRow, StartCol], Player),
    valid_direction([StartRow, StartCol], [EndRow, EndCol]),
    valid_slide(Board, [StartRow, StartCol], [EndRow, EndCol]).

% generate_moves(+Board, +Player, -Moves)
% Gera todos os movimentos válidos para o jogador atual.
% Percorre todas as combinações possíveis de posições iniciais e finais no tabuleiro (8x8), verificando se cada movimento é válido.
generate_moves(Board, Player, Moves) :-
    findall([StartRow, StartCol, EndRow, EndCol], (
        between(1, 8, StartRow),
        between(1, 8, StartCol),
        between(1, 8, EndRow),
        between(1, 8, EndCol),
        valid_move(Board, [StartRow, StartCol], [EndRow, EndCol], Player)
    ), Moves).

% execute_move(+Board, +Move, -NewBoard)
% Executa um movimento no tabuleiro, alterando o estado.
execute_move(Board, [StartRow, StartCol, EndRow, EndCol], NewBoard) :-
    cell_player(Board, StartRow, StartCol, Player),
    move_marbles(Board, [StartRow, StartCol], [EndRow, EndCol], Player, NewBoard).

% move_marbles(+Board, +StartPos, +EndPos, +Player, -NewBoard)
% Move as peças no tabuleiro na direção especificada (horizontal ou vertical).
% Calcula a direção do movimento com base nas diferenças de linhas e colunas.
move_marbles(Board, [StartRow, StartCol], [EndRow, EndCol], Player, NewBoard) :-
    DeltaRow is sign(EndRow - StartRow),
    DeltaCol is sign(EndCol - StartCol),
    move_marbles_aux(Board, [StartRow, StartCol], DeltaRow, DeltaCol, [EndRow, EndCol], Player, NewBoard).

% move_marbles_aux(+Board, +CurrentPos, +DeltaRow, +DeltaCol, +EndPos, +Player, -NewBoard)
% Caso base: Se a posição atual for igual à posição final, o movimento termina.
move_marbles_aux(Board, [Row, Col], _, _, [Row, Col], _, Board).

% Recursivamente move as peças até a posição final.
move_marbles_aux(Board, [Row, Col], DeltaRow, DeltaCol, [EndRow, EndCol], Player, NewBoard) :-
    move_marble_to_next(Board, [Row, Col], DeltaRow, DeltaCol, TempBoard),
    NextRow is Row + DeltaRow,
    NextCol is Col + DeltaCol,
    move_marbles_aux(TempBoard, [NextRow, NextCol], DeltaRow, DeltaCol, [EndRow, EndCol], Player, NewBoard).

% move_marble_to_next(+Board, +CurrentPos, +DeltaRow, +DeltaCol, -NewBoard)
% Move a peça da posição atual para a próxima célula, considerando o estado da próxima célula.
move_marble_to_next(Board, [Row, Col], DeltaRow, DeltaCol, NewBoard) :-
    NextRow is Row + DeltaRow,
    NextCol is Col + DeltaCol,
    cell_player(Board, Row, Col, Player),
    handle_next_position(Board, [Row, Col], [NextRow, NextCol], Player, DeltaRow, DeltaCol, NewBoard).

% handle_next_position(+Board, +CurrentPos, +NextPos, +Player, +DeltaRow, +DeltaCol, -NewBoard)
% Caso 1: A próxima posição está vazia.
handle_next_position(Board, [Row, Col], [NextRow, NextCol], Player, _, _, NewBoard) :-
    cell_player(Board, NextRow, NextCol, empty),
    place_marble(Board, [NextRow, NextCol], Player, TempBoard),
    clear_cell(TempBoard, [Row, Col], NewBoard).

% Caso 2: A próxima posição está ocupada (empurra as peças para frente).
handle_next_position(Board, [Row, Col], [NextRow, NextCol], Player, DeltaRow, DeltaCol, NewBoard) :-
    cell_player(Board, NextRow, NextCol, NextPlayer),
    NextPlayer \= empty,
    move_marble_to_next(Board, [NextRow, NextCol], DeltaRow, DeltaCol, TempBoard),
    place_marble(TempBoard, [NextRow, NextCol], Player, TempBoard2),
    clear_cell(TempBoard2, [Row, Col], NewBoard).

% place_marble(+Board, +Pos, +Player, -NewBoard)
% Coloca uma peça em uma célula específica do tabuleiro.
place_marble(Board, [Row, Col], Player, NewBoard) :-
    nth1(Row, Board, OldRow),
    replace_in_list(Col, OldRow, Player, NewRow),
    replace_in_list(Row, Board, NewRow, NewBoard).

% clear_cell(+Board, +Pos, -NewBoard)
% Remove a peça de uma célula específica do tabuleiro.
clear_cell(Board, [Row, Col], NewBoard) :-
    nth1(Row, Board, OldRow),
    replace_in_list(Col, OldRow, empty, NewRow),
    replace_in_list(Row, Board, NewRow, NewBoard).

% replace_in_list(+Index, +List, +Element, -NewList)
% Substitui um elemento em uma lista por outro, mantendo o restante.
replace_in_list(Index, List, Element, NewList) :-
    nth1(Index, List, _, Rest),
    nth1(Index, NewList, Element, Rest).

% valid_moves_check(+NewBoard, +CurrentPlayer, +NextPlayer, +Player1Type, +Player2Type, +Rules, +Player1Name, +Player2Name, +Difficulty, +NextPlayerMoves, -NewGameState)
% Verifica movimentos válidos para o próximo estado do jogo.
valid_moves_check(NewBoard, CurrentPlayer, _NextPlayer, Player1Type, Player2Type, Rules, Player1Name, Player2Name, Difficulty, [], [NewBoard, CurrentPlayer, Player1Type, Player2Type, Rules, Player1Name, Player2Name, Difficulty]).
valid_moves_check(NewBoard, _CurrentPlayer, NextPlayer, Player1Type, Player2Type, Rules, Player1Name, Player2Name, Difficulty, NextPlayerMoves, [NewBoard, NextPlayer, Player1Type, Player2Type, Rules, Player1Name, Player2Name, Difficulty]) :-
    NextPlayerMoves \= [].

% check_winner(+OMoves, +XMoves, +OScore, +XScore, -Winner)
% Determina o vencedor do jogo com base nas pontuações finais.
check_winner([], [], OScore, XScore, 'o') :- OScore > XScore.
check_winner([], [], OScore, XScore, 'x') :- XScore > OScore.
check_winner([], [], OScore, XScore, 'draw') :- OScore =:= XScore.

% simulate_move(+GameState, +Move, -Value)
% Simula um movimento e calcula o valor do estado resultante.
simulate_move(GameState, Move, Value) :-
    move(GameState, Move, NewGameState),
    NewGameState = [_, CurrentPlayer, _, _, _, _, _, _],
    switch_player(CurrentPlayer, Player),
    value(NewGameState, Player, Value).









presentation1 :-
    board(Board),
    GameState = [Board, o, computer, computer, optional_rules, pc1, pc2, 2],
    play_game(GameState).
