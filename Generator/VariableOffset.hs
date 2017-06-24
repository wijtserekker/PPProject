module Generator.VariableOffset where

import Parser.AST.AST

type OffsetMap = [(String, Int)]

calculateVarOffset :: AST -> Int -> (OffsetMap, OffsetMap)
calculateVarOffset ast gOff = let (res,_,_) = calculateVarOffset' (([],[]),0,gOff) ast in res

calculateVarOffset' :: ((OffsetMap, OffsetMap), Int, Int) -> AST -> ((OffsetMap, OffsetMap), Int, Int)
calculateVarOffset' world (ProgT asts)          = calculateVarOffsetList world asts
calculateVarOffset' world (WhileT ast asts)     = calculateVarOffsetList world asts
calculateVarOffset' world (IfOneT ast asts)     = calculateVarOffsetList world asts
calculateVarOffset' world (IfTwoT ast as1 as2)  = calculateVarOffsetList (calculateVarOffsetList world as1) as2
calculateVarOffset' world (ParallelT s asts)    = calculateVarOffsetList world asts
calculateVarOffset' world (GlobalDeclT _ s _)   | offMapsContains s offmaps = world
                                                | otherwise                 = ((local,(s,curGOff):global),curLOff,curGOff+1)
                                                where
                                                    (offmaps, curLOff, curGOff) = world
                                                    (local, global) = offmaps
calculateVarOffset' world (PrivateDeclT _ s _)  | offMapsContains s offmaps = world
                                                | otherwise                 = (((s,curLOff):local,global),curLOff+1,curGOff)
                                                where
                                                    (offmaps, curLOff, curGOff) = world
                                                    (local, global) = offmaps
calculateVarOffset' world _                     = world



calculateVarOffsetList :: ((OffsetMap, OffsetMap), Int, Int) -> [AST] -> ((OffsetMap, OffsetMap), Int, Int)
calculateVarOffsetList world []             = world
calculateVarOffsetList world (a:as)         = calculateVarOffsetList newworld as
                                            where
                                                newworld = calculateVarOffset' world a

offMapsContains :: String -> (OffsetMap, OffsetMap) -> Bool
offMapsContains s (m1,m2) = case (lookup s m1, lookup s m2) of
                                (Just _, _)     -> True
                                (_, Just _)     -> True
                                _               -> False

calculateThreadAmount :: AST -> Int
calculateThreadAmount (ProgT as)                = calculateThreadAmount' as
-- Statements
calculateThreadAmount (PrivateDeclT s1 s2 a)    = calculateThreadAmount a
calculateThreadAmount (GlobalDeclT s1 s2 a)     = calculateThreadAmount a
calculateThreadAmount (AssignT s a)             = calculateThreadAmount a
calculateThreadAmount (WhileT a as)             = maximum [calculateThreadAmount a, calculateThreadAmount' as]
calculateThreadAmount (IfOneT a as)             = maximum [calculateThreadAmount a, calculateThreadAmount' as]
calculateThreadAmount (IfTwoT a as1 as2)        = maximum [calculateThreadAmount a, calculateThreadAmount' as1, calculateThreadAmount' as2]
calculateThreadAmount (ParallelT s as)          = read s
calculateThreadAmount (ReadIntT s)              = 1
calculateThreadAmount (WriteIntT a)             = calculateThreadAmount a
--Expressions
calculateThreadAmount EmptyT                    = 1
calculateThreadAmount (IntConstT s)             = 1
calculateThreadAmount (BoolConstT s)            = 1
calculateThreadAmount (VarT s)                  = 1
calculateThreadAmount ThreadIDT                 = 1
calculateThreadAmount (OneOpT s a)              = calculateThreadAmount a
calculateThreadAmount (TwoOpT a1 s a2)          = maximum [calculateThreadAmount a1, calculateThreadAmount a2]
calculateThreadAmount (BracketsT a)             = calculateThreadAmount a


calculateThreadAmount' :: [AST] -> Int
calculateThreadAmount' as = maximum (map calculateThreadAmount as)














--
