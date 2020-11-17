open import Data.List
open import Data.Unit

open import Relation.Unary hiding (_∈_)
open import Relation.Unary.PredicateTransformer using (Pt)

module Relation.Ternary.Monad.State.Linear
  {ℓ}
  {T : Set ℓ}               -- value types
  (V : T → Pred (List T) ℓ) -- stored values
  where

open import Level hiding (Lift)
open import Function using (_∘_; case_of_)
import Relation.Binary.HeterogeneousEquality as HEq
open import Relation.Binary.PropositionalEquality using (refl; _≡_)
open import Relation.Ternary.Core
open import Relation.Ternary.Structures
open import Relation.Ternary.Structures.Syntax
open import Relation.Ternary.Construct.Product
open import Relation.Ternary.Monad
open import Relation.Ternary.Respect.Propositional

open import Relation.Ternary.Construct.List.Disjoint T
open import Relation.Ternary.Construct.Market disjoint-split
open import Relation.Ternary.Data.Allstar T

open import Data.Product
open import Relation.Ternary.Monad.State disjoint-split public

Cells : List T → List T → Set ℓ
Cells Σ Φ = Allstar V Σ Φ

Heap : List T → Set ℓ
Heap = LeftOver Cells

module HeapOps (M : Pt Market ℓ) where
  open StateTransformer M Heap public

  module _ {{monad : Monad ⊤ (λ _ _ → M) }} where

    -- Creating a reference to a new cell, filled with a given value.
    -- Note that in the market monoid this is pure!
    -- Because we get a reference that consumes the freshly created resource.
    mkref : ∀ {a} → ∀[ V a ⇒ StateT M Heap (One a) ]
    runState (mkref v) ⟨ supplyᵣ σ₂ ⟩ (lift (subtract st σ₁)) =
      let _ , τ₁ , τ₂ = ∙-assocₗ σ₁ σ₂ in return (
        lift refl ∙⟨ supplyᵣ ∙-disjoint ⟩
        lift (subtract (cons (v ∙⟨ ∙-comm τ₁ ⟩ st)) (∙-disjointᵣₗ τ₂)))

    -- A linear read on a store: you lose the reference.
    -- Resources balance, because with the reference being lost, the cell is destroyed: no resources leak.
    read : ∀ {a} → ∀[ One a ⇒ StateT M Heap (V a) ]
    runState (read refl) ⟨ supplyᵣ σ₂ ⟩ (lift (subtract st σ₁))
      with _ , σ₃ , σ₄ ← ∙-assocₗ σ₁ (∙-comm σ₂) with repartition (∙-comm σ₄) st
    ... | cons (v ∙⟨ σ₅ ⟩ nil) ∙⟨ σ₆ ⟩ st' with refl ← ∙-id⁻ʳ σ₅ with ∙-assocᵣ (∙-comm σ₆) σ₃
    ... | _ , τ₁ , τ₂ = return (lift v ∙⟨ supplyᵣ τ₂ ⟩ lift (subtract st' τ₁))

    -- -- Writing into a cell, returning the current contents
    write : ∀ {a b} → ∀[ One b ⇒ (V a) ─✴ StateT M Heap (One a ✴ V b) ]
    runState (write refl ⟨ σ₁ ⟩ v) ⟨ supplyᵣ σ₂ ⟩ (lift (subtract st σ₃)) with ∙-assocᵣ σ₁ σ₂
    -- first we reassociate the arguments in the order that we want to piece it back together
    ... | _ , τ₁ , τ₂ with ∙-assocₗ σ₃ (∙-comm τ₁)
    ... | _ , τ₃ , τ₄ with repartition (∙-comm τ₄) st
    -- then we reorganize the store internally to take out the unit value
    ... | (vb :⟨ σ₅ ⟩: nil) ∙⟨ σ₆ ⟩ st' rewrite ∙-id⁻ʳ σ₅ =
      -- and we put everything back together
      let _ , _ , κ₁ , κ₂ , κ = resplit σ₆ (∙-comm τ₂) τ₃ in
      return (
        lift (refl ∙⟨ consˡ ∙-idˡ ⟩ vb) ∙⟨ supplyᵣ (consˡ κ₁) ⟩ 
        lift (subtract (v :⟨ ∙-comm κ₂ ⟩: st') (∙-disjointᵣₗ (∙-comm κ))))

  module _ {{_ : Strong ⊤ (λ _ _ → M)}} where

    -- A linear (strong) update on the store
    update! : ∀ {a b} → ∀[ One a ⇒ (V a ─✴ StateT M Heap (V b)) ─✴ StateT M Heap (One b) ]
    update! ptr ⟨ σ ⟩ f = do
      f ∙⟨ σ₁ ⟩ a ← read ptr &⟨ ∙-comm σ ⟩ f
      b           ← f ⟨ σ₁ ⟩ a
      mkref b
