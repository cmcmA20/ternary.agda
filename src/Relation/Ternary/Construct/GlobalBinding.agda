module Relation.Ternary.Construct.GlobalBinding {ℓ} (T : Set ℓ) where

open import Level hiding (Lift)
open import Data.Product
open import Data.List
open import Data.List.Extra

open import Relation.Unary hiding (_∈_)
open import Relation.Binary hiding (_⇒_)
open import Relation.Binary.Structures
open import Relation.Binary.PropositionalEquality as PEq using (_≡_)
open IsEquivalence {{...}}

open import Relation.Ternary.Core
open import Relation.Ternary.Structures
open import Relation.Ternary.Respect.Propositional

private
  Labels = List T
  variable
    u₁ u₂ u₃ d₁ d₂ d₃ u d : Labels

open import Relation.Ternary.Construct.Duplicate T as Dup public
open import Relation.Ternary.Construct.List.Interdivide duplicate as Overlapping
open Overlapping public renaming
  (split-positive to overlap-positive
  ;split-isSemigroup to overlap-semigroup
  ;split-isMonoid to overlap-monoid)

_∪_≣_ = Rel₃._∙_≣_ Overlapping.splits

open import Data.Unit
instance splits-intuitive : Intuitionistic {A = Labels} Overlapping.splits
Intuitionistic.Condition splits-intuitive _ = ⊤
Intuitionistic.∙-copy splits-intuitive {[]} = ∙-idˡ
Intuitionistic.∙-copy splits-intuitive {x ∷ xs} = Overlapping.divide dup ∙-copy

open import Relation.Ternary.Construct.Empty T public
open import Relation.Ternary.Construct.List.Interdivide empty-rel as Disjoint
open Disjoint public using
  (split-positive
  ;split-isSemigroup
  ;split-isMonoid)

_⊎_≣_ = Rel₃._∙_≣_ Disjoint.splits

_/_≣_ = λ xs ys zs → ys ⊎ zs ≣ xs

module _ where

  -- Global binding modularized:
  -- At every part of the tree we have some labels that are exported (up)
  -- and some that are imported (down)
  infixr 1 _↕_
  record Binding : Set ℓ where
    constructor _↕_
    field
      exp : Labels
      imp : Labels

    pair : Labels × Labels
    pair = exp , imp

  open Binding public

  data Down (P : Pred Labels ℓ) : Pred Binding ℓ where
    ↓ : ∀ {x} → P x → Down P ([] ↕ x)

  data Up (P : Pred Labels ℓ) : Pred Binding ℓ where
    ↑ : ∀ {x} → P x → Up P (x ↕ [])

private
  variable
    ud₁ ud₂ ud : Binding

module _ where

  open import Data.List.Relation.Binary.Permutation.Propositional

  open import Data.Product.Relation.Binary.Pointwise.NonDependent
  _≈_ : Binding → Binding → Set _
  a ≈ b = Pointwise _↭_ _↭_ (pair a) (pair b)

  instance binding-≈-equivalence : IsEquivalence _≈_
  IsEquivalence.refl binding-≈-equivalence  = ↭-refl , ↭-refl
  IsEquivalence.sym binding-≈-equivalence   (e₁ , e₂) = ↭-sym e₁ , ↭-sym e₂
  IsEquivalence.trans binding-≈-equivalence (e₁ , e₂) (f₁ , f₂) = ↭-trans e₁ f₁ , ↭-trans e₂ f₂

  {- Subtraction with duplication -}
  data _-_≣_ : Labels → Labels → Binding → Set ℓ where
    sub : ∀ {e e' d' u'} →
          d' ⊎ e  ≣ d → -- disjoint, so that demand is only bound once 
          u' ∪ e' ≣ u → -- with overlap, so that binders can be reused
          e ↭ e' →
          d - u ≣ (u' ↕ d')

  []-sub : ∀ {xs} → [] - xs ≣ (xs ↕ [])
  []-sub = sub ∙-idˡ ∙-idʳ ↭-refl

  sub-[] : ∀ {xs} → xs - [] ≣ ([] ↕ xs)
  sub-[] = sub ∙-idʳ ∙-idˡ ↭-refl

  []-sub⁻ : ∀ {xs ys zs} → [] - xs ≣ (ys ↕ zs) → ys ≡ xs × zs ≡ []
  []-sub⁻ (sub x x₁ x₂) with ε-split x
  ... | PEq.refl , PEq.refl with ↭-[] (↭-sym x₂)
  ... | PEq.refl = ∙-id⁻ʳ x₁ , PEq.refl

  sub-[]⁻ : ∀ {xs ys zs} → xs - [] ≣ (ys ↕ zs) → zs ≡ xs × ys ≡ []
  sub-[]⁻ (sub x x₁ x₂) with ε-split x₁
  ... | PEq.refl , PEq.refl with ↭-[] x₂
  ... | PEq.refl = ∙-id⁻ʳ x , PEq.refl

  data Binds : Binding → Binding → Binding → Set ℓ where
    -- exchange the rings and bind 'm
    ex : ∀ {u₁' d₁' u₂' d₂'} →
      -- exchange lhs to rhs and vice versa
      d₁ - u₂ ≣ (u₂' ↕ d₂') →
      d₂ - u₁ ≣ (u₁' ↕ d₁') →

      -- add the remaining supply and demand
      u₁' ⊎ u₂' ≣ u →
      d₁' ∪ d₂' ≣ d →

      Binds (u₁ ↕ d₁) (u₂ ↕ d₂) (u ↕ d)

  instance binding-rel : Rel₃ Binding
  binding-rel = record { _∙_≣_ = Binds }

  instance intuitive : Intuitionistic {A = Binding} binding-rel
  Intuitionistic.Condition intuitive (u ↕ d) = u ≡ [] 
  Intuitionistic.∙-copy intuitive {.[] ↕ xs} ⦃ PEq.refl ⦄ = ex sub-[] sub-[] ∙-idˡ ∙-copy

  instance binding-comm : IsCommutative binding-rel
  IsCommutative.∙-comm binding-comm (ex x₁ x₂ x₃ x₄) = ex x₂ x₁ (∙-comm x₃) (∙-comm x₄)

  postulate binding-semigroupˡ : IsPartialSemigroupˡ _≡_ binding-rel
  -- IsPartialSemigroupˡ.≈-equivalence binding-semigroupˡ = PEq.isEquivalence
  -- IsPartialSemigroupˡ.assocᵣ binding-semigroupˡ σ₁ (ex x x₁ (consˡ x₂) x₃) = {!!}
  -- IsPartialSemigroupˡ.assocᵣ binding-semigroupˡ σ₁ (ex x x₁ (consʳ x₂) x₃) = {!!}

  -- IsPartialSemigroupˡ.assocᵣ binding-semigroupˡ σ₁ (ex x x₁ [] (divide x₂ x₃)) = {!!}
  -- IsPartialSemigroupˡ.assocᵣ binding-semigroupˡ σ₁ (ex x x₁ [] (consˡ x₃)) = {!!}
  -- IsPartialSemigroupˡ.assocᵣ binding-semigroupˡ σ₁ (ex x x₁ [] (consʳ x₃)) = {!!}
  -- IsPartialSemigroupˡ.assocᵣ binding-semigroupˡ σ₁ (ex x x₁ [] []) = -, {!!} , {!!}

  instance binding-semigroup : IsPartialSemigroup _≡_ binding-rel
  binding-semigroup = IsPartialSemigroupˡ.semigroupˡ binding-semigroupˡ

  instance binding-emptiness : Emptiness ([] ↕ [])
  binding-emptiness = record {}

  binding-isMonoidˡ : IsPartialMonoidˡ _≡_ binding-rel ([] ↕ [])
  IsPartialMonoidˡ.ε-uniq binding-isMonoidˡ PEq.refl = PEq.refl
  IsPartialMonoidˡ.identityˡ binding-isMonoidˡ = ex []-sub sub-[] ∙-idˡ ∙-idʳ
  IsPartialMonoidˡ.identity⁻ˡ binding-isMonoidˡ (ex x₁ x₂ x₃ x₄) with sub-[]⁻ x₂ | []-sub⁻ x₁
  ... | PEq.refl , PEq.refl | PEq.refl , PEq.refl with ∙-id⁻ˡ x₃ | ∙-id⁻ʳ x₄
  ... | PEq.refl | PEq.refl = PEq.refl

  instance binding-isMonoid : IsPartialMonoid _≡_ binding-rel ([] ↕ [])
  binding-isMonoid = IsPartialMonoidˡ.partialMonoidˡ binding-isMonoidˡ