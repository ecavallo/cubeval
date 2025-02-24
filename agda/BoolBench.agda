{-# OPTIONS --cubical #-}

open import Cubical.Foundations.Everything
open import Cubical.Data.Nat
open import Cubical.Data.Bool


BoolPathN : ℕ → Bool ≡ Bool
BoolPathN n = iter n (λ p → p ∙ notEq) notEq

fun : ℕ → Bool → Bool
fun n x = transport (BoolPathN n) x

val : ℕ → Bool
val n = transport (BoolPathN n) true

test : val 350 ≡ false
test = refl

-- all|internal|modules|definitions|sharing|serialize|constraints|metas|interactive|conversion)
