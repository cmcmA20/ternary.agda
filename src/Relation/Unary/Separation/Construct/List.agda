module Relation.Unary.Separation.Construct.List where

open import Data.Product
open import Data.List
open import Data.List.Properties using (++-isMonoid)
open import Data.List.Relation.Ternary.Interleaving.Propositional as I
open import Data.List.Relation.Ternary.Interleaving.Properties
open import Data.List.Relation.Binary.Equality.Propositional
open import Data.List.Relation.Binary.Permutation.Inductive

open import Relation.Binary.PropositionalEquality as P hiding ([_])
open import Relation.Unary hiding (_∈_; _⊢_)
open import Relation.Unary.Separation

module _ {a} {A : Set a} where
  private
    C = List A

  instance separation : RawSep C
  separation = record { _⊎_≣_ = Interleaving }

  -- TODO add to stdlib
  interleaving-assoc : ∀ {a b ab c abc : List A} →
            Interleaving a b ab → Interleaving ab c abc →
            ∃ λ bc → Interleaving a bc abc × Interleaving b c bc
  interleaving-assoc l (consʳ r)         = let _ , p , q = interleaving-assoc l r in -, consʳ p , consʳ q
  interleaving-assoc (consˡ l) (consˡ r) = let _ , p , q = interleaving-assoc l r in -, consˡ p , q
  interleaving-assoc (consʳ l) (consˡ r) = let _ , p , q = interleaving-assoc l r in -, consʳ p , consˡ q
  interleaving-assoc [] []               = [] , [] , []

  instance ctx-has-sep : IsSep separation
  ctx-has-sep = record
    { ⊎-comm = I.swap
    ; ⊎-assoc = interleaving-assoc
    }

  instance ctx-hasUnitalSep : IsUnitalSep _ _
  IsUnitalSep.isSep ctx-hasUnitalSep               = ctx-has-sep
  IsUnitalSep.⊎-idˡ ctx-hasUnitalSep               = right (≡⇒≋ P.refl)
  IsUnitalSep.⊎-id⁻ˡ ctx-hasUnitalSep []           = refl
  IsUnitalSep.⊎-id⁻ˡ ctx-hasUnitalSep (refl ∷ʳ px) = cong (_ ∷_) (⊎-id⁻ˡ px)

  instance ctx-concattative : IsConcattative separation
  IsConcattative._∙_ ctx-concattative = _++_
  IsConcattative.⊎-∙ₗ ctx-concattative {Φₑ = []} ps = ps
  IsConcattative.⊎-∙ₗ ctx-concattative {Φₑ = x ∷ Φₑ} ps = consˡ (⊎-∙ₗ ps)

  instance ctx-unitalsep : UnitalSep _
  ctx-unitalsep = record
    { isUnitalSep = ctx-hasUnitalSep }

  instance ctx-resource : MonoidalSep _
  ctx-resource = record
    { sep = separation
    ; isSep = ctx-has-sep
    ; isUnitalSep   = ctx-hasUnitalSep
    ; isConcat      = ctx-concattative
    ; monoid = ++-isMonoid }

{- We can split All P xs over a split of xs -}
module All {t v} {T : Set t} {V : T → Set v} where

  open import Data.List.All

  all-split : ∀ {Γ₁ Γ₂ Γ} → Γ₁ ⊎ Γ₂ ≣ Γ → All V Γ → All V Γ₁ × All V Γ₂
  all-split [] [] = [] , []
  all-split (consˡ s) (px ∷ vs) = let xs , ys = all-split s vs in px ∷ xs , ys
  all-split (consʳ s) (px ∷ vs) = let xs , ys = all-split s vs in xs , px ∷ ys


{- Useful predicates -}
module _ {t} {T : Set t} where

  Just : T → Pred (List T) t
  Just t = Exactly (t ∷ ε)

  -- Membership
  _∈_ : T → Pred (List T) t
  a ∈ as = [ a ] ≤ as

module _ {a t} {T : Set t} {A : Set a} {{r : RawSep A}} {u} {{s : IsUnitalSep r u}} where

  repartition : ∀ {p} {P : T → Pred A p} {Σ₁ Σ₂ Σ : List T} →
                Σ₁ ⊎ Σ₂ ≣ Σ → ∀[ Allstar P Σ ⇒ Allstar P Σ₁ ✴ Allstar P Σ₂ ]
  repartition [] nil   = nil ×⟨ ⊎-idˡ ⟩ nil
  repartition (consˡ σ) (cons (a ×⟨ σ′ ⟩ qx)) = 
    let
      xs ×⟨ σ′′ ⟩ ys = repartition σ qx
      _ , τ₁ , τ₂    = ⊎-unassoc σ′ σ′′
    in (cons (a ×⟨ τ₁ ⟩ xs)) ×⟨ τ₂ ⟩ ys
  repartition (consʳ σ) (cons (a ×⟨ σ′ ⟩ qx)) =
    let
      xs ×⟨ σ′′ ⟩ ys = repartition σ qx
      _ , τ₁ , τ₂    = ⊎-unassoc σ′ (⊎-comm σ′′)
    in xs ×⟨ ⊎-comm τ₂ ⟩ (cons (a ×⟨ τ₁ ⟩ ys))