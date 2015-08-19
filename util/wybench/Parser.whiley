package wybench

import whiley.lang.*
import char from whiley.lang.ASCII
import string from whiley.lang.ASCII

public type nat is (int x) where x >= 0

// ========================================================
// Parse Ints
// ========================================================

public function parseInt(nat pos, string input) -> (null|int,nat):
    //
    int start = pos
    while pos < |input| && ASCII.isDigit(input[pos]):
        pos = pos + 1
    if pos == start:
        return null,pos
    //
    return Int.parse(Array.slice(input,start,pos)), pos

// Parse list of integers whilst ignoring whitespace
public function parseInts(string input) -> int[]|null:
    //    
    int[] data = [0;0]
    nat pos = skipWhiteSpace(0,input)
    // first, read data
    while pos < |input|:
        int|null i
        i,pos = parseInt(pos,input)
        if i != null:
            data = Array.append(data,i)
            pos = skipWhiteSpace(pos,input)
        else:
            return null
    //
    return data

// Parse lines of integers
public function parseIntLines(string input) -> int[][]|null:
    //    
    int[][] data = [[0;0];0]
    nat pos = skipWhiteSpace(0,input)
    // first, read data
    while pos < |input|:
        int[] line = [0;0]
        while !isWhiteSpace(input[pos]):
            int|null i
            i,pos = parseInt(pos,input)
            if i != null:
                line = Array.append(line,i)
                pos = skipLineSpace(pos,input)
            else:
                return null
        //
        data = append(data,line)
        pos = skipWhiteSpace(pos,input)
    //
    return data

// Should be remove when Array.append become generic
public function append(int[][] items, int[] item) -> int[][]:
    int[][] nitems = [[0;0]; |items| + 1]
    int i = 0
    //
    while i < |items|:
        nitems[i] = items[i]
        i = i + 1
    //
    nitems[i] = item    
    //
    return nitems

// ========================================================
// Parse Reals
// ========================================================

public function parseReal(nat pos, string input) -> (null|real,int):
    //
    int start = pos
    while pos < |input| && (ASCII.isDigit(input[pos]) || input[pos] == '.'):
        pos = pos + 1
    //
    if pos == start:
        return null,pos
    //
    return Real.parse(Array.slice(input,start,pos)),pos

// Parse list of reals whilst ignoring whitespace
public function parseReals(string input) -> real[]|null:
    //
    real[] data = [0.0; 0]
    nat pos = skipWhiteSpace(0,input)
    // first, read data
    while pos < |input|:
        real|null i
        i,pos = parseReal(pos,input)
        if i != null:
            data = append(data,i)
            pos = skipWhiteSpace(pos,input)
        else:
            return null
    //
    return data

// Should be remove when Array.append become generic
public function append(real[] items, real item) -> real[]:
    real[] nitems = [0.0; |items| + 1]
    int i = 0
    //
    while i < |items|:
        nitems[i] = items[i]
        i = i + 1
    //
    nitems[i] = item    
    //
    return nitems

// ========================================================
// Parse Strings
// ========================================================

public function parseString(nat pos, string input) -> (string,nat):
    nat start = pos
    while pos < |input| && !isWhiteSpace(input[pos]):
        pos = pos + 1
    return Array.slice(input,start,pos),pos

// Parse list of reals whilst ignoring whitespace
public function parseStrings(string input) -> string[]:
    //
    string[] data = [[0;0];0]
    nat pos = skipWhiteSpace(0,input)
    // first, read data
    while pos < |input|:
        string s
        s,pos = parseString(pos,input)
        data = append(data,s)
        pos = skipWhiteSpace(pos,input)
    //
    return data

// ========================================================
// SkipWhiteSpace
// ========================================================

public function skipWhiteSpace(nat index, string input) -> nat:
    //
    while index < |input| && isWhiteSpace(input[index]):
        index = index + 1
    //
    return index

// ========================================================
// IsWhiteSpace
// ========================================================

public function isWhiteSpace(char c) -> bool:
    return c == ' ' || c == '\t' || c == '\n' || c == '\r'

// ========================================================
// SkipLineSpace
// ========================================================

public function skipLineSpace(nat index, string input) -> nat:
    //
    while index < |input| && isLineSpace(input[index]):
        index = index + 1
    //
    return index

// ========================================================
// IsLineSpace
// ========================================================

public function isLineSpace(char c) -> bool:
    return c == ' ' || c == '\t'
