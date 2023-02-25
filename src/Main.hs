{-# options_ghc -Wno-unused-imports #-}

module Main where

import Common
import Elaboration
import Parser
import Pretty


main :: IO ()
main = putStrLn "hello"

-- | Elaborate a string, render output.
justElab :: String -> IO ()
justElab str = do
  top <- parseString "(interactive)" str
  top <- elabTop "(interactive)" str top
  putStrLn $ showTop top

--------------------------------------------------------------------------------

p1 = justElab $ unlines [
   ""
  ,"id : (A : U) → A → A → A := λ A x y. z;"
  ]

p2 = justElab $ unlines [
   ""
  ,"id := (A : U) → A → A;"
  ,"Eq   : (A : U) → A → A → U := λ A x y. (P : A → U) → P x → P y;"
  ,"refl : (A : U)(x : A) → Eq A x x := λ A x P px. px;"
  ,"sym  : (A : U)(x y : A) → Eq A x y → Eq A y x := λ A x y p. p (λ y. Eq A y x) (refl A x) ;"
  ,"trs  : (A : U)(x y z : A) → Eq A x y → Eq A y z → Eq A x z := λ A x y z p q. q (λ z. Eq A x z) p;"
  ]

p3 = justElab $ unlines [
   ""
  ,"test2 : U := (A : U) × A;"
  ,"test3 : (x : (A : U) × A) → x.1 := λ x. x.2;"
  ,"test4 : (A : U) × A → U := λ _. U;"
  ,"test5 : (A : U)(B : A → U)(a : A)(b : B a) → (a : A) × B a := λ A B a b. (a, b);"
  ,"test6 : (A : U)(B : A → U)(x : (a : A) × B a) → A := λ A B x. x.1;"
  ,"test7 : (A : U)(B : A → U)(x : (a : A) × B a) → B x.1 := λ A B x. x.2;"

  ,"refl (A : U)(x : A) : x = x := λ _. x;"

  ,"trans (A : U)(x y z : A) (p : x = y) (q : y = z) : x = z"
  ,"  := λ i. hcom 0 1 [i=0 _. x; i=1 j. q j] (p i);"

  ,"sym (A : U)(x y : A) (p : x = y) : y = x "
  ,"  := λ i. hcom 0 1 [i=0 j. p j; i=1 _. x] x;"

  ,"ap (A B : U)(f : A → B)(x y : A)(p : x = y) : f x = f y"
  ,"   := λ i. f (p i);"

  ,"nestedlet  := let myid (A : U)(x : A) : A := x; myid;"
  ,"nestedlet2 : (A : U) → A → A := let myid (A : U)(x : A) : A := x; myid;"

  ,"testEta (A : U) (x y : A)(p : x = y) : p = p := refl (x = y) (λ i. p i);"

  ,"funext (A : U)(B : A → U)(f g : (a : A) → B a)(p : (a : A) → f a = g a) : f = g"
  ,"  := λ i a. p a i;"

  ,"coerce (A B : U) (p : A = B)(a : A) : B := coe 0 1 i (p i) a;"

  ,"coerceinv (A B : U) (p : A = B)(b : B) : A := coe 1 0 i (p i) b;"

  ,"subst (A : U)(P : A → U)(x y : A)(p : x = y)(px : P x) : P y := coe 0 1 i (P (p i)) px;"

  ,"Sing (A : U) (a : A) : U := (x : A) × (a = x);"

  ,"split (A : U)(a b : A)(p : a = b) : a = a := λ i. hcom 1 0 [i=0 _. a; i=1 j. p j] (p i);"

  ,"connAndWeak (A : U)(a b : A)(p : a = b) : split A a b p ={l. a = p l} p"
  ,"  := λ l k. hcom 1 l [k=0 _. a; k=1 x. p x] (p k);"

  ,"connAnd (A : U)(a b : A)(p : a = b) : (λ _. a) ={i. a = p i} p"
  ,"  := λ i j. hcom 0 1 [i=0 k. connAndWeak A a b p 0 k; i=1 k. connAndWeak A a b p j k;"
  ,"                      j=0 k. connAndWeak A a b p 0 k; j=1 k. connAndWeak A a b p i k;"
  ,"                      i=j k. connAndWeak A a b p i k] a;"

  ]
