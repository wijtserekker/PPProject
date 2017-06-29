module Parser.AST.AST where

import FPPrac.Trees
import Parser.ParseBasis

-- ======================================================================================= --
-- ================================= AST definition ====================================== --
-- ======================================================================================= --
data VScope = SGlob | SPriv
            deriving (Show, Eq)

-- Data structure for the AST
data AST    = ProgT [AST]
            -- Statements
            | DeclT VScope String String AST
            | AssignT String AST
            | ArrayAssignT String AST AST -- TODO support dis in functions
            | WhileT AST [AST]
            | IfOneT AST [AST]
            | IfTwoT AST [AST] [AST]
            | ParallelT String [AST]
            | SyncT String [AST]
            | ReadIntT String
            | WriteIntT AST
            -- Expressions
            | EmptyT
            | IntConstT String
            | BoolConstT String
            | VarT String
            | ThreadIDT
            | ArrayExprT String AST -- TODO support dis in functions
            | OneOpT String AST
            | TwoOpT AST String AST
            | BracketsT AST
            | EmptyArrayT String -- ArrayInit
            | FillArrayT [AST]
            deriving (Show, Eq)


-- ======================================================================================= --
-- =========================== Tree Conversion Functions ================================= --
-- ======================================================================================= --

-- Converts parse tree (result of parser) to AST
-- Arguments:
--  - ParseTree     the parse tree that is to be converted.
-- Returns:         the converted parse tree as AST
parsetoast :: ParseTree -> AST
parsetoast (PNode Prog stats)  = ProgT (map parsetoast stats)
parsetoast (PNode Stat [stat]) = parseStattoast stat
parsetoast (PNode Expr nodes)  = parseExprtoast (PNode Expr nodes)

parseStattoast :: ParseTree -> AST
parseStattoast (PNode Decl [t, n])                         = DeclT SPriv (getType t) (getTokenString n) EmptyT
parseStattoast (PNode Decl [t, n, e])                      = DeclT SPriv (getType t) (getTokenString n) (parseExprtoast e)
parseStattoast (PNode Decl [_, t, n])                      = DeclT SGlob (getType t) (getTokenString n) EmptyT
parseStattoast (PNode Decl [_, t, n, e])                   = DeclT SGlob (getType t) (getTokenString n) (parseExprtoast e)
parseStattoast (PNode ArrayDecl [PNode ArrayType [t], n, e])            = DeclT SPriv ("[" ++ (getType t) ++ "]") (getTokenString n) (parseExprtoast e)
parseStattoast (PNode ArrayDecl [_, PNode ArrayType [t], n, e])         = DeclT SGlob ("[" ++ (getType t) ++ "]") (getTokenString n) (parseExprtoast e)
parseStattoast (PNode Assign [n, e])                                    = AssignT (getTokenString n) (parseExprtoast e)
parseStattoast (PNode ArrayAssign [n, e])                                    = AssignT (getTokenString n) (parseExprtoast e)
parseStattoast (PNode While [e, PNode Block s])                         = WhileT (parseExprtoast e) (map parsetoast s)
parseStattoast (PNode IfOne [e, PNode Block s])                         = IfOneT (parseExprtoast e) (map parsetoast s)
parseStattoast (PNode IfTwo [e, PNode Block st, PNode Block se])        = IfTwoT (parseExprtoast e) (map parsetoast st) (map parsetoast se)
parseStattoast (PNode Parallel [PNode IntConst [i], PNode Block st])    = ParallelT (getTokenString i) (map parsetoast st)
parseStattoast (PNode Sync [PNode Var [i], PNode Block st])             = SyncT (getTokenString i) (map parsetoast st)
parseStattoast (PNode ReadInt [PNode Var [v]])                          = ReadIntT (getTokenString v)
parseStattoast (PNode WriteInt [e])                                     = WriteIntT (parseExprtoast e)

getType :: ParseTree -> String
getType (PNode Type [t]) = getTokenString t

parseExprtoast :: ParseTree -> AST
parseExprtoast (PNode Expr [l, PNode TwoOp [t], r]) = TwoOpT (parseExprtoast l) (getTokenString t) (parseExprtoast r)
parseExprtoast (PNode Expr [PNode OneOp [o], e])    = OneOpT (getTokenString o) (parseExprtoast e)
parseExprtoast (PNode Expr [e])                     = parseExprtoast e
parseExprtoast (PNode Brackets [e])                 = BracketsT (parseExprtoast(e))
parseExprtoast (PNode Val [PNode IntConst [i]])     = IntConstT (getTokenString i)
parseExprtoast (PNode Val [PNode BoolConst [b]])    = BoolConstT (getTokenString b)
parseExprtoast (PNode Val [PNode Var [v]])          = VarT (getTokenString v)
parseExprtoast (PNode Val [PNode ThreadID []])      = ThreadIDT
parseExprtoast (PNode ArrayInit [PNode IntConst [i]]) = EmptyArrayT (getTokenString i)
parseExprtoast (PNode ArrayInit exprs)              = FillArrayT (map parseExprtoast exprs)


-- Statements
-- parsetoast (PNode Stat [PNode Decl [PNode Type [t], n]])         = PrivateDeclT (getTokenString t) (getTokenString n) EmptyT
-- parsetoast (PNode Stat [PNode Decl [PNode Type [t], n, e]])      = PrivateDeclT (getTokenString t) (getTokenString n) (parsetoast e)
-- parsetoast (PNode Stat [_, PNode Decl [PNode Type [t], n]])      = GlobalDeclT (getTokenString t) (getTokenString n) EmptyT
-- parsetoast (PNode Stat [_, PNode Decl [PNode Type [t], n, e]])   = GlobalDeclT (getTokenString t) (getTokenString n) (parsetoast e)
-- parsetoast (PNode Stat [PNode Assign [n, e]])       = AssignT (getTokenString n) (parsetoast e)
-- parsetoast (PNode Stat [PNode While [e, PNode Block s]])                    = WhileT (parsetoast e) (map parsetoast s)
-- parsetoast (PNode Stat [PNode IfOne [e, PNode Block s]])                    = IfOneT (parsetoast e) (map parsetoast s)
-- parsetoast (PNode Stat [PNode IfTwo [e, PNode Block st, PNode Block se]])   = IfTwoT (parsetoast e) (map parsetoast st) (map parsetoast se)
-- parsetoast (PNode Stat [PNode Parallel [PNode IntConst [i], PNode Block st]])   = ParallelT (getTokenString i) (map parsetoast st)
-- parsetoast (PNode Stat [PNode Sync [PNode Var [i], PNode Block st]])        = SyncT (getTokenString i) (map parsetoast st)
-- parsetoast (PNode Stat [PNode ReadInt [PNode Var [v]]])                     = ReadIntT (getTokenString v)
-- parsetoast (PNode Stat [PNode WriteInt [e]])                                = WriteIntT (parsetoast e)
-- -- Expressions
-- parsetoast (PNode Expr [PNode Brackets [v], PNode TwoOp [t], e])            = TwoOpT (parsetoast (PNode Expr [PNode Brackets [v]])) (getTokenString (t)) (parsetoast(e))
-- parsetoast (PNode Expr [v, PNode TwoOp [t], e])                             = TwoOpT (parsetoast v) (getTokenString (t)) (parsetoast e)
-- parsetoast (PNode Expr [PNode Expr e])                                      = parsetoast (PNode Expr e)
-- parsetoast (PNode Expr [PNode OneOp [o], PNode Expr e])                     = OneOpT (getTokenString o) (parsetoast (PNode Expr e))
-- parsetoast (PNode Expr [PNode Brackets [e]])                                = BracketsT (parsetoast(e))
-- parsetoast (PNode Expr [PNode Val [PNode IntConst [i]]])                    = IntConstT (getTokenString i)
-- parsetoast (PNode Expr [PNode Val [PNode BoolConst [b]]])                   = BoolConstT (getTokenString b)
-- parsetoast (PNode Expr [PNode Val [PNode Var [v]]])                         = VarT (getTokenString v)
-- parsetoast (PNode Expr [PNode Val [PNode ThreadID []]])                     = ThreadIDT
-- parsetoast (PNode Val [PNode IntConst [i]])                                 = IntConstT (getTokenString i)
-- parsetoast (PNode Val [PNode BoolConst [b]])                                = BoolConstT (getTokenString b)
-- parsetoast (PNode Val [PNode Var [v]])                                      = VarT (getTokenString v)
-- parsetoast (PNode Val [PNode ThreadID []])                                  = ThreadIDT
-- Rest
-- parsetoast x = error ("Error in parsetoast on: " ++ show(x))

-- Converts an AST to a rose tree so that it can be shown
-- Arguments:
--  - AST           the AST that is to be converted
-- Returns:         the converted AST as a rose tree
asttorose :: AST -> RoseTree
asttorose (ProgT asts)              = RoseNode "ProgT" (map asttorose asts)
--
asttorose (DeclT SGlob s1 s2 ast)   = RoseNode ("DeclT _" ++ s1 ++ " " ++ s2) [asttorose ast]
asttorose (DeclT SPriv s1 s2 ast)  = RoseNode ("DeclT " ++ s1 ++ " " ++ s2) [asttorose ast]
asttorose (AssignT s ast)           = RoseNode ("AssignT " ++ s) [asttorose ast]
asttorose (WhileT ast asts)         = RoseNode "WhileT" ((asttorose ast):(map asttorose asts))
asttorose (IfOneT ast asts)         = RoseNode "IfOneT" ((asttorose ast):(map asttorose asts))
asttorose (IfTwoT ast asts1 asts2)  = RoseNode "IfTwoT" (((asttorose ast):(map asttorose asts1)) ++ (map asttorose asts2))
asttorose (ParallelT s asts)        = RoseNode ("ParallelT "++s) (map asttorose asts)
asttorose (SyncT s asts)            = RoseNode ("SyncT "++s) (map asttorose asts)
asttorose (ReadIntT s)              = RoseNode ("ReadIntT " ++ s) []
asttorose (WriteIntT ast)           = RoseNode "WriteIntT" [asttorose ast]
-- Expressions
asttorose EmptyT                    = RoseNode "EmptyT" []
asttorose (IntConstT x)             = RoseNode ("IntConstT " ++ x) []
asttorose (BoolConstT b)            = RoseNode ("BoolConstT " ++ b) []
asttorose (VarT s)                  = RoseNode ("VarT " ++ s) []
asttorose ThreadIDT                 = RoseNode ("ThreadIDT") []
asttorose (OneOpT s ast)            = RoseNode ("OneOpT " ++ s) [asttorose ast]
asttorose (TwoOpT ast1 s ast2)      = RoseNode ("TwoOpT " ++ s) ((asttorose ast1):[asttorose ast2])
asttorose (BracketsT ast)           = RoseNode "BracketsT" [asttorose ast]

-- Gets the token value of a leaf in the parse tree
-- Arguments:
--  - ParseTree     the parse tree (leaf) of which the token is to be returned
-- Returns:         the token corresponding to the leaf in the argument
getTokenString :: ParseTree -> String
getTokenString pt   = case pt of
    PLeaf (a, s)-> s
    otherwise   -> error "IN getTokenString : is not a leaf"
