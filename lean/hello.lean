-- 1. Evaluato:r check: run computations at elaboration time␍
#eval 2 + 2

-- 2. Simple function␍
def square (n : Nat) : Nat :=
  n * n

def cube (n : Nat) : Nat :=
  n * n * n

#eval square 5

#eval cube 5

-- 3. Simple proposition and proof␍
theorem simple_add (n : Nat) : n + 0 = n := by
  rfl

-- 4. Interactive proof state practice␍
theorem and_comm1 (p q : Prop) : p ∧ q → q ∧ p := by
  intro h
  cases h with
  | intro hp hq =>
    constructor
    · exact hq
    · exact hp
