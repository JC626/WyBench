// This file implements a parse for chess games in Portable Game
// Notation (PGN) format.  This is based around short-algebraic notation.
// Such moves are, by themselves, incomplete.  We must have access to the 
// current board state in order to decode them.
//
// See http://en.wikipedia.org/wiki/Algebraic_chess_notation for more.

import whiley.lang.*
import * from whiley.lang.Errors
import * from ShortMove
import * from Board

type state is {ASCII.string input, int pos}

public function parseChessGame(ASCII.string input) -> [ShortRound]|null:
    int pos = 0
    [ShortRound] moves = []
    while pos < |input|:        
        ShortRound|null round
        round,pos = parseRound(pos,input)
        if round is null:
            return null
        else:
            moves = moves ++ [round]
    return moves

function parseRound(int pos, ASCII.string input) -> (ShortRound|null,int):
    ShortMove white
    ShortMove|null black
    int|null npos = parseNumber(pos,input)
    if npos == null:
        return null,pos
    pos = parseWhiteSpace(npos,input)
    white,pos = parseMove(pos,input,true)
    pos = parseWhiteSpace(pos,input)
    if pos < |input|:
        black,pos = parseMove(pos,input,false)
        pos = parseWhiteSpace(pos,input)
    else:
        black = null
    return (white,black),pos

function parseNumber(int pos, ASCII.string input) -> int|null:
    while pos < |input| && input[pos] != '.':
        pos = pos + 1
    if pos == |input|:
        return null
    else:
        return pos+1

function parseMove(int pos, ASCII.string input, bool isWhite) -> (ShortMove,int):
    ShortMove move
    // first, we check for castling moves    
    if |input| >= (pos+5) && input[pos..(pos+5)] == "O-O-O":
        move = Move.Castle(isWhite, false)
        pos = pos + 5
    else if |input| >= (pos+3) && input[pos..(pos+3)] == "O-O":
        move = Move.Castle(isWhite, true)
        pos = pos + 3
    else:
        Piece p
        ShortPos f, ShortPos t
        bool flag
        // not a castling move
        p,pos = parsePiece(pos,input,isWhite)
        f,pos = parseShortPos(pos,input)
        if input[pos] == 'x':
            pos = pos + 1
            flag = true
        else:
            flag = false
        t,pos = parsePos(pos,input)
        move = { piece: p, from: f, to: t, isTake: flag }
    // finally, test for a check move
    if pos < |input| && input[pos] == '+':
        pos = pos + 1
        move = {check: move}     
    return move,pos

function parsePiece(int index, ASCII.string input, bool isWhite) -> (Piece,int):
    ASCII.char lookahead = input[index]
    int piece
    switch lookahead:
        case 'N':
            piece = KNIGHT
        case 'B':
            piece = BISHOP
        case 'R':
            piece = ROOK
        case 'K':
            piece = KING
        case 'Q':
            piece = QUEEN
        default:
            index = index - 1
            piece = PAWN
    return {kind: piece, colour: isWhite}, index+1
    
function parsePos(int pos, ASCII.string input) -> (Pos,int):
    int c = (int) input[pos] - 'a'
    int r = (int) input[pos+1] - '1'
    return { col: c, row: r },pos+2

function parseShortPos(int index, ASCII.string input) -> (ShortPos,int):
    ASCII.char c = input[index]
    if ASCII.isDigit(c):
        // signals rank only
        return { row: (int) c - '1' },index+1
    else if c != 'x' && ASCII.isLetter(c):
        // so, could be file only, file and rank, or empty
        ASCII.char d = input[index+1]
        if ASCII.isLetter(d):
            // signals file only
            return { col: (int) c - 'a' },index+1         
        else if (index+2) < |input| && ASCII.isLetter(input[index+2]):
            // signals file and rank
            return { col: ((int) c - 'a'), row: (int) d - '1' },index+2
    // no short move given
    return null,index

function parseWhiteSpace(int index, ASCII.string input) -> int:
    while index < |input| && isWhiteSpace(input[index]):
        index = index + 1
    return index

function isWhiteSpace(ASCII.char c) -> bool:
    return c == ' ' || c == '\t' || c == '\n'

