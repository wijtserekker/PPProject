module Generator.Generator where


import Parser.AST.AST
import Generator.VariableOffset
import Sprockell


generateCode :: AST -> (OffsetMap, OffsetMap) -> [Instruction]
generateCode (ProgT as) vm              = (generateCode' as vm)++[EndProg]
-- Statements
generateCode (GlobalDeclT t v a) (l,g)  = (generateCode a (l,g))++[Pop regA, WriteInstr regA (DirAddr og)]
                                            where
                                                og = getOffset v g
generateCode (PrivateDeclT t v a) (l,g) = (generateCode a (l,g))++[Pop regA, Store regA (DirAddr ol)]
                                            where
                                                ol = getOffset v l
generateCode (AssignT v a) (l,g)        | ol /= -1      = (generateCode a (l,g))++[Pop regA, Store regA (DirAddr ol)]
                                        | otherwise     = (generateCode a (l,g))++[Pop regA, WriteInstr regA (DirAddr og)]
                                            where
                                                ol = getOffset v l
                                                og = getOffset v g
generateCode (WhileT a as) (l,g)        = bCode ++ [Pop regA, Branch regA (Rel 2), Jump (Rel jumpOver)] ++ wCode ++ [Jump (Rel jumpBack)]
                                            where
                                                bCode = generateCode a (l,g)
                                                wCode = generateCode' as (l,g)
                                                jumpOver = length wCode + 2
                                                jumpBack = -1 * ((length bCode) + (length wCode) + 3)
generateCode (IfOneT a as) (l,g)        = bCode ++ [Pop regA, Branch regA (Rel 2), Jump (Rel jumpOver)] ++ tCode
                                            where
                                                bCode = generateCode a (l,g)
                                                tCode = generateCode' as (l,g)
                                                jumpOver = length tCode + 1
generateCode (IfTwoT a as1 as2) (l,g)   = bCode ++ [Pop regA, Branch regA (Rel 2), Jump (Rel jumpOverT)] ++ tCode ++ [Jump (Rel jumpOverE)] ++ eCode
                                            where
                                                bCode = generateCode a (l,g)
                                                tCode = generateCode' as1 (l,g)
                                                eCode = generateCode' as2 (l,g)
                                                jumpOverT = length tCode + 2
                                                jumpOverE = length eCode + 1
generateCode (ParallelT a as) (l,g)     = []
generateCode (ReadIntT v) (l,g)         | ol /= -1      = [ReadInstr numberIO, Receive regA, Store regA (DirAddr ol)]
                                        | otherwise     = [ReadInstr numberIO, Receive regA, WriteInstr regA (DirAddr og)]
                                            where
                                                ol = getOffset v l
                                                og = getOffset v g
generateCode (WriteIntT a) (l,g)        = (generateCode a (l,g))++[Pop regA, WriteInstr regA numberIO]
-- Expressions
generateCode EmptyT (l,g)               = [Push reg0]
generateCode (IntConstT i) (l,g)        = [Load (ImmValue (read i)) regA, Push regA]
generateCode (BoolConstT b) (l,g)       = [Load (ImmValue (readBoolToInt b)) regA, Push regA]
generateCode (VarT v) (l,g)             | ol /= -1      = [Load (DirAddr ol) regA, Push regA]
                                        | otherwise     = [ReadInstr (DirAddr og), Receive regA, Push regA]
                                            where
                                                ol = getOffset v l
                                                og = getOffset v g
generateCode ThreadIDT (l,g)            = [Push regSprID]
generateCode (OneOpT o a) (l,g)         | o == "-"      = (generateCode a (l,g))++[Pop regA, Load (ImmValue (-1)) regB, Compute Mul regA regB regA, Push regA]
                                        | o == "!"      = (generateCode a (l,g))++[Pop regA, Load (ImmValue 1) regB, Compute Xor regA regB regA, Push regA]
generateCode (TwoOpT a1 o a2) (l,g)     | o == "*"      = generateTwoOpCode a1 a2 Mul (l,g)
                                        | o == "%"      = generateTwoOpCode a1 a2 Div (l,g)
                                        | o == "+"      = generateTwoOpCode a1 a2 Add (l,g)
                                        | o == "-"      = generateTwoOpCode a1 a2 Sub (l,g)
                                        | o == "=="     = generateTwoOpCode a1 a2 Equal (l,g)
                                        | o == ">"      = generateTwoOpCode a1 a2 Gt (l,g)
                                        | o == "<"      = generateTwoOpCode a1 a2 Lt (l,g)
                                        | o == ">="     = generateTwoOpCode a1 a2 GtE (l,g)
                                        | o == "<="     = generateTwoOpCode a1 a2 LtE (l,g)
                                        | o == "!="     = generateTwoOpCode a1 a2 NEq (l,g)
                                        | o == "||"     = generateTwoOpCode a1 a2 Or (l,g)
                                        | o == "&&"     = generateTwoOpCode a1 a2 And (l,g)
                                        | o == "+|"     = generateTwoOpCode a1 a2 Xor (l,g)
generateCode (BracketsT a) (l,g)         = generateCode a (l,g)





generateTwoOpCode :: AST -> AST -> Operator -> (OffsetMap, OffsetMap) -> [Instruction]
generateTwoOpCode a1 a2 o (l,g)     = (generateCode a1 (l,g))++(generateCode a2 (l,g))++[Pop regB, Pop regA, Compute o regA regB regA, Push regA]







generateCode' :: [AST] -> (OffsetMap, OffsetMap) -> [Instruction]
generateCode' [] vm                 = []
generateCode' (a:as) vm             = (generateCode a vm)++(generateCode' as vm)


getOffset :: String -> OffsetMap -> Int
getOffset s []          = -1
getOffset s (o:os)      | fst o == s        = snd o
                        | otherwise         = getOffset s os


readBoolToInt :: String -> Int
readBoolToInt s | s == "\\"     = 0
                | s == "/"      = 1

















--
