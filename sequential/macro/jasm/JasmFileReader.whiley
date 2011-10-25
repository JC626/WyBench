import whiley.lang.*
import * from whiley.lang.Errors
import * from ClassFile

public ClassFile read(string input) throws SyntaxError:
    tokens = tokenify(input)
    return parse(tokens)

// =======================================================
// Lexer
// =======================================================

define Number as { int value, int start, int end }
define Identifier as { string id, int start, int end }
define JavaString as { string str, int start, int end }
define Operator as { char op, int start, int end }
define Token as Number | Identifier | JavaString | Operator

[Token] tokenify(string input) throws SyntaxError:
    index = 0
    tokens = []
    while index < |input|:
        lookahead = input[index]
        if Char.isWhiteSpace(lookahead):
            index = skipWhiteSpace(input,index)
        else if Char.isDigit(lookahead):
            token,index = parseNumber(input,index)
            tokens = tokens + [token]
        else if isIdentifierStart(lookahead):
            token,index = parseIdentifier(input,index)
            tokens = tokens + [token]
        else:
            index = index + 1
            token = Operator(lookahead,index-1,index)
            tokens = tokens + [token]
    return tokens
    
(Identifier, int) parseIdentifier(string input, int index):    
    start = index
    txt = ""
    // inch forward until end of identifier reached
    while index < |input| && isIdentifierStart(input[index]):
        txt = txt + input[index]
        index = index + 1
    while index < |input| && isIdentifierBody(input[index]):
        txt = txt + input[index]
        index = index + 1
    return Identifier(txt,start,index),index

bool isIdentifierStart(char c):
    return Char.isLetter(c) || c == '_'

bool isIdentifierBody(char c):
    return Char.isDigit(c) || Char.isLetter(c) || c == '_'

(Number, int) parseNumber(string input, int index) throws SyntaxError:    
    start = index
    txt = ""
    // inch forward until end of identifier reached
    while index < |input| && Char.isDigit(input[index]):
        txt = txt + input[index]
        index = index + 1
    return Number(String.toInt(txt),start,index),index
    
int skipWhiteSpace(string input, int index):
    while index < |input| && Char.isWhiteSpace(input[index]):
        index = index + 1
    return index

Identifier Identifier(string identifier, int start, int end):
    return {id: identifier, start: start, end: end}

Number Number(int value, int start, int end):
    return {value: value, start: start, end: end}

Operator Operator(char op, int start, int end):
    return {op: op, start: start, end: end}

// =======================================================
// Parser
// =======================================================

ClassFile parse([Token] tokens) throws SyntaxError:
    modifiers,index = parseClassModifiers(tokens,0)
    if matches("class",tokens,index):
        index = match("class",tokens,index)
    else if matches("interface",tokens,index):
        index = match("interface",tokens,index)
        modifiers = modifiers + {ACC_INTERFACE}
    else:
        throw nSyntaxError("expected class or interface",tokens[index])
    name,index = matchIdentifier(tokens,index)
    // parse extends clause (if present)
    super = JvmType.JAVA_LANG_OBJECT
    if matches("extends",tokens,index):
        index = match("extends",tokens,index)
        super,index = parseJvmClassType(tokens,index)
    // parse implements clause (if present)
    interfaces = []
    if matches("implements",tokens,index):
        index = match("implements",tokens,index)
        // could do with a do-while construct
        type,index = parseJvmClassType(tokens,index)
        interfaces = [type]
        while matches(',',tokens,index):
            index = match(',',tokens,index)            
            type,index = parseJvmClassType(tokens,index)
            interfaces = interfaces + [type]
    // now parse field and method declarations
    fields,methods = parseClassBody(tokens,index)
    return {
        minor_version: 0,
        major_version: 49,
        modifiers: modifiers,
        type: JvmType.Class("",name),
        super: super,
        interfaces: interfaces,
        fields: fields,
        methods: methods
    }

([FieldInfo],[MethodInfo]) parseClassBody([Token] tokens, int index) throws SyntaxError:
    fields = []
    methods = []
    index = match('{',tokens,index)
    while index < |tokens| && !matches('}',tokens,index):
        //modifiers,index = parseModifiers
    index = match('}',tokens,index)
    return fields,methods

({Modifier},int) parseModifiers({Modifier} permitted, [Token] tokens, int index) throws SyntaxError:
    modifiers = {ACC_SUPER}
    oldIndex = -1
    while index < |tokens| && index != oldIndex:
        oldIndex = index
        token = tokens[index]
        if token is Identifier:
            modifier = null
            switch(token.id):
                case "public":
                    modifier = ACC_PUBLIC
                    break
                case "final":
                    modifier = ACC_FINAL
                    break               
                case "abstract":
                    modifier = ACC_ABSTRACT
                    break
                case "strict":
                    modifier = ACC_STRICT
                    break
                case "synthetic":
                    modifier = ACC_SYNTHETIC
                    break
                case "annotation":
                    modifier = ACC_ANNOTATION
                    break
                case "enum":
                    modifier = ACC_ENUM
                    break
            if modifier != null:
                if modifier in permitted:
                    modifiers = modifiers + {modifier}
                    index = index + 1
                else:
                    throw nSyntaxError("modifier not permitted here",token)
    // finished!
    return modifiers,index

(JvmType.Class,int) parseJvmClassType([Token] tokens, int index) throws SyntaxError:
    name,index = matchIdentifier(tokens,index)
    pkg = ""
    firstTime = true
    // parse package
    while matches('.',tokens,index):
        if !firstTime:
            pkg = pkg + "."
        firstTime=false
        pkg = pkg + name
        name,index = matchIdentifier(tokens,index)
    // parse inner classes
    return JvmType.Class(pkg,name),index

(string,int) matchIdentifier([Token] tokens, int index) throws SyntaxError:
    if index < |tokens|:
        token = tokens[index]
        if token is Identifier:
            return token.id,index+1
        else:
            throw nSyntaxError("identifier expected",token)
    throw SyntaxError("unexpected end-of-file",index,index+1)

int match(string id, [Token] tokens, int index) throws SyntaxError:
    if index < |tokens|:
        token = tokens[index]
        if token is Identifier && token.id == id:
            return index+1
        else:
            throw nSyntaxError("identifier expected",tokens[index])
    throw SyntaxError("unexpected end-of-file",index,index+1)

int match(char op, [Token] tokens, int index) throws SyntaxError:
    if index < |tokens|:
        token = tokens[index]
        if token is Operator && token.op == op:
            return index+1
        else:
            throw nSyntaxError("operator expected",tokens[index])
    throw SyntaxError("unexpected end-of-file",index,index+1)

bool matches(string id, [Token] tokens, int index):
    if index < |tokens|:
        token = tokens[index]
        if token is Identifier:
            return token.id == id
    return false

bool matches(char op, [Token] tokens, int index):
    if index < |tokens|:
        token = tokens[index]
        if token is Operator:
            return token.op == op
    return false

// =======================================================
// Misc
// =======================================================

SyntaxError nSyntaxError(string msg, Token token):
    return SyntaxError(msg,token.start,token.end)
