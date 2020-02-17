open import Data.List
open import Data.Unit

open import Relation.Unary hiding (_∈_)
open import Relation.Unary.PredicateTransformer using (Pt)

module Relation.Ternary.Monad.State.Linear
  {ℓ}

  -- value types
  {T : Set ℓ}

  -- stored values
  (V : T → Pred (List T) ℓ) 
  where

open import Level hiding (Lift)
open import Function using (_∘_; case_of_)
import Relation.Binary.HeterogeneousEquality as HEq
open import Relation.Binary.PropositionalEquality using (refl; _≡_)
open import Relation.Ternary.Core
open import Relation.Ternary.Structures
open import Relation.Ternary.Construct.Product
open import Relation.Ternary.Monad
open import Relation.Ternary.Construct.Market
open import Relation.Ternary.Respect.Propositional

open import Relation.Ternary.Construct.List.Interleave T
open import Relation.Ternary.Data.Allstar T

open import Data.Product
open import Data.List.Relation.Ternary.Interleaving.Propositional as I
  
module HeapOps 
  -- inner monad
  (M : Pt (Market (List T)) ℓ)
  {{monad : Monad ⊤ (λ _ _ → M) }}
  where
  Cells : Pred (List T × List T) ℓ
  Cells (Σ , Φ) = Allstar V Σ Φ

  open import Relation.Ternary.Monad.State
  open StateTransformer M public

  -- Creating a reference to a new cell, filled with a given value.
  -- Note that in the market monoid this is pure!
  -- Because we get a reference that consumes the freshly created resource.
  mkref : ∀ {a} → ∀[ V a ⇒ StateT M Cells (Just a) ]
  (mkref v) ⟨ offerᵣ σ₂ ⟩ (lift st σ₁) =
    let _ , τ₁ , τ₂ = ∙-assocᵣ (∙-comm σ₂) σ₁
    in return (
      lift refl
        ∙⟨ offerᵣ ∙-∙ ⟩
      lift (cons (v ∙⟨ τ₂ ⟩ st)) (∙-∙ₗ τ₁))

  -- A linear read on a store: you lose the reference.
  -- This is pure, because with the reference being lost, the cell is destroyed: no resources leak.
  read : ∀ {a} → ∀[ Just a ⇒ StateT M Cells (V a) ]
  (read refl) ⟨ offerᵣ σ₂ ⟩ (lift st σ₁) with ∙-assocᵣ σ₂ σ₁
  ... | _ , σ₃ , σ₄ with repartition σ₃ st
  ... | cons (v ∙⟨ σ₅ ⟩ nil) ∙⟨ σ₆ ⟩ st' with ∙-id⁻ʳ σ₅ | ∙-assocᵣ (∙-comm σ₆) (∙-comm σ₄)
  ... | refl | _ , τ₁ , τ₂ = return (lift v ∙⟨ offerᵣ τ₂ ⟩ lift st' (∙-comm τ₁))

  -- Writing into a cell, returning the current contents
  write : ∀ {a b} → ∀[ Just b ⊙ (V a) ⇒ StateT M Cells (Just a ⊙ V b) ]
  write (refl ∙⟨ σ₁ ⟩ v) ⟨ offerᵣ σ₃ ⟩ (lift st σ₂) with ∙-assocᵣ (∙-comm σ₁) σ₃
  -- first we reassociate the arguments in the order that we want to piece it back together
  ... | _ , τ₁ , τ₂ with ∙-assocᵣ (∙-comm τ₁) σ₂
  ... | _ , τ₃ , τ₄ with ∙-assocᵣ τ₂ τ₃
  ... | _ , τ₅ , τ₆
  -- then we reorganize the store internally to take out the unit value
    with repartition τ₅ st
  ... | cons (vb ∙⟨ σ₅ ⟩ nil) ∙⟨ σ₆ ⟩ st' rewrite ∙-id⁻ʳ σ₅ = 
    let 
      _ , κ₁ , κ₂ = ∙-assocₗ τ₄ (∙-comm σ₆) 
      _ , κ₃ , κ₄ = ∙-assocᵣ κ₂ (∙-comm τ₆)
    in return (
      lift (refl ∙⟨ consˡ ∙-idˡ ⟩ vb)
        ∙⟨ offerᵣ (consˡ κ₄) ⟩
      lift (cons (v ∙⟨ κ₁ ⟩ st')) (∙-∙ₗ (∙-comm κ₃)))

  -- A linear (strong) update on the store
  update! : ∀ {a b} → ∀[ Just a ⇒ (V a ─⊙ StateT M Cells (V b)) ─⊙ StateT M Cells (Just b) ]
  update! ptr ⟨ σ ⟩ f = do
    f ∙⟨ σ₁ ⟩ a ← read ptr &⟨ ∙-comm σ ⟩ f
    b           ← f ⟨ σ₁ ⟩ a
    mkref b
