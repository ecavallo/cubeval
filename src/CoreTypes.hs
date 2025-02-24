{-# options_ghc -funbox-strict-fields -Wno-orphans #-}

module CoreTypes where

import Common
import Interval
import qualified Data.LvlMap as LM

-- Syntax
--------------------------------------------------------------------------------

data WithIS a = WIS {withISBody :: a, withISIvars :: IVarSet}
  deriving (Show)

data RecInfo = RI {
    recInfoRecId    :: Lvl
  , recInfoRecTy    :: ~Ty
  , recInfoRecTyVal :: ~VTy
  , recInfoName     :: Name
  , recInfoPos      :: {-# nounpack #-} SourcePos
  }

instance Show RecInfo where
  show (RI _ _ _ x _) = x

data DefInfo = DI {
    defInfoDefId    :: Lvl
  , defInfoDef      :: Tm
  , defInfoDefVal   :: ~Val
  , defInfoDefTy    :: ~Ty
  , defInfoDefTyVal :: ~VTy
  , defInfoName     :: Name
  , defInfoPos      :: {-# nounpack #-} SourcePos
  }

instance Show DefInfo where
  show (DI _ _ _ _ _ x _) = x

data TyConInfo = TCI {
    tyConInfoTyId         :: Lvl
  , tyConInfoParamTypes   :: Tel
  , tyConInfoConstructors :: IORef (LM.Map DConInfo)
  , tyConInfoFrozen       :: IORef Bool
  , tyConInfoName         :: Name
  , tyConInfoPos          :: {-# nounpack #-} SourcePos
  }

instance Show TyConInfo where
  show (TCI _ _ _ _ x _) = x

data DConInfo = DCI {
    dConInfoConId      :: Lvl
  , dConInfoFieldTypes :: Tel
  , dConInfoName       :: Name
  , dConInfoTyConInfo  :: {-# nounpack #-} TyConInfo
  , dConInfoPos        :: {-# nounpack #-} SourcePos
  }

instance Show DConInfo where
  show (DCI _ _ x _ _) = x

data HDConInfo = HDCI {
    hDConInfoConId      :: Lvl
  , hDConInfoFieldTypes :: Tel
  , hDConInfoIsCoherent :: Bool
  , hDConInfoIfields    :: [Name]
  , hDConInfoBoundary   :: Sys
  , hDConInfoName       :: Name
  , hDConInfoTyConInfo  :: {-# nounpack #-} HTyConInfo
  , hDConInfoPos        :: {-# nounpack #-} SourcePos
  }

instance Show HDConInfo where
  show (HDCI _ _ _ _ _ x _ _) = x

data HTyConInfo = HTCI {
    hTyConInfoTyId         :: Lvl
  , hTyConInfoParamTypes   :: Tel
  , hTyConInfoConstructors :: IORef (LM.Map HDConInfo)
  , hTyConInfoFrozen       :: IORef Bool
  , hTyConInfoName         :: Name
  , hTyConInfoPos          :: {-# nounpack #-} SourcePos
  }

instance Show HTyConInfo where
  show (HTCI _ _ _ _ x _) = x

--------------------------------------------------------------------------------

type Ty = Tm
type CaseTag = Int

data Tel
  = TNil
  | TCons Name Ty Tel
  deriving Show

data Spine
  = SPNil
  | SPCons Tm Spine
  deriving Show

data LazySpine
  = LSPNil
  | LSPCons ~Tm LazySpine
  deriving Show

data Tm
  = TopVar        {-# nounpack #-} DefInfo
  | RecursiveCall {-# nounpack #-} RecInfo
  | LocalVar Ix
  | Let Name Tm Ty Tm

  | TyCon {-# nounpack #-} TyConInfo Spine
  | DCon  {-# nounpack #-} DConInfo  Spine

  | HTyCon {-# nounpack #-} HTyConInfo Spine
  -- LazySpine is for params which are usually quoted from syntax.
  | HDCon {-# nounpack #-} HDConInfo LazySpine Spine Sub
  | HCase Tm Name ~Ty CaseTag HCases
  | HSplit Name ~Ty CaseTag HCases

  | Case Tm Name ~Ty CaseTag Cases
  | Split Name ~Ty CaseTag Cases

  | Pi Name Ty Ty
  | App Tm Tm
  | Lam Name Tm

  | Sg Name Ty Ty
  | Pair Name Tm Tm
  | Proj1 Tm Name
  | Proj2 Tm Name

  | Wrap Name Ty
  | Pack Name Tm
  | Unpack Tm Name

  | U

  | Path Name Ty Tm Tm    -- PathP i.A x y
  | PApp ~Tm ~Tm Tm I      -- (x : A i0)(y : A i1)(t : PathP i.A x y)(j : I)
  | PLam ~Tm ~Tm Name Tm   -- endpoints, body

  | Line Name Tm           -- (i : I) → A
  | LApp Tm I
  | LLam Name Tm

  | Coe I I Name Ty Tm      -- coe r r' i.A t
  | HCom I I Ty SysHCom Tm  -- hcom r r' i A [α → t] u

  -- we switch the field orders here compared to the papers, because
  -- this one is the sensible "dependency" order
  | GlueTy Ty Sys            -- Glue A [α ↦ B]      (B : Σ X (X ≃ A))
  | Glue   Tm ~Sys ~Sys      -- glue a <equiv> <fib>
  | Unglue Tm ~Sys           -- unglue g [α ↦ B]

  | Hole Hole

  | Com I I Name Tm SysHCom Tm

  | WkI Tm

  -- builtins
  | Refl ~Tm
  | Sym ~Tm ~Tm ~Tm Tm
  | Trans ~Tm ~Tm ~Tm ~Tm Tm Tm
  | Ap Tm ~Tm ~Tm Tm
  deriving Show

data Hole
  = SrcHole (Maybe Name) (DontShow SourcePos)
  | ErrHole String
  deriving Show

data Cases
  = CSNil
  | CSCons Name [Name] Tm Cases
  deriving Show

data HCases
  = HCSNil
  | HCSCons Name [Name] [Name] Tm HCases
  deriving Show

snocHCases :: HCases -> Name -> [Name] -> [Name] -> Tm -> HCases
snocHCases cs x xs is t = case cs of
  HCSNil                   -> HCSCons x xs is t HCSNil
  HCSCons x' xs' is' t' cs -> HCSCons x' xs' is' t' (snocHCases cs x xs is t)

-- | Atomic equation.
data CofEq = CofEq I I
  deriving Show

-- | Conjunction of equations.
data Cof = CTrue | CAnd CofEq Cof
  deriving Show

data Sys = SEmpty | SCons Cof Tm Sys
  deriving Show

data SysHCom = SHEmpty | SHCons Cof Name Tm SysHCom
  deriving Show

-- Values
--------------------------------------------------------------------------------

data NamedClosure = NCl {
    namedClosureName    :: Name
  , namedClosureClosure :: Closure }
  deriving Show

data NamedIClosure = NICl {
    namedIClosureName    :: Name
  , namedIClosureClosure :: IClosure }
  deriving Show

data NeCof
  = NCEq I I
  | NCAnd NeCof NeCof
  deriving Show

data NeCof' = NeCof' {
    neCof'Extended :: NCof
  , neCof'Extra    :: NeCof}
  deriving Show

data VCof
  = VCTrue
  | VCFalse
  | VCNe NeCof' IVarSet
  deriving Show

data Env
  = ENil
  | EDef Env ~Val

instance Show Env where
  show = show . go [] where
    go acc ENil         = acc
    go acc (EDef env v) = go (v:acc) env

type EnvArg = (?env :: Env)

--------------------------------------------------------------------------------

data BindI a = BindI {
    bindIName  :: Name
  , bindIBinds :: IVar
  , bindIBody  :: a}
  deriving Show

data BindILazy a = BindILazy {
    bindILazyName  :: Name
  , bindILazyBinds :: IVar
  , bindILazyBody  :: ~a}
  deriving Show

data BindCof a = BindCof {
    bindCofBinds :: NeCof
  , bindCofBody  :: a}
  deriving Show

data BindCofLazy a = BindCofLazy {
    bindCofLazyBinds :: NeCof
  , bindCofLazyBody  :: ~a}
  deriving Show

--------------------------------------------------------------------------------

data NeSys
  = NSEmpty
  | NSCons (BindCofLazy Val) NeSys
  deriving Show

type NeSys' = WithIS NeSys

data NeSysHCom
  = NSHEmpty
  | NSHCons (BindCof (BindILazy Val)) NeSysHCom
  deriving Show

type NeSysHCom' = WithIS NeSysHCom

-- TODO: unbox
data VSys
  = VSTotal Val
  | VSNe NeSys'
  deriving Show

-- TODO: unbox
data VSysHCom
  = VSHTotal (BindILazy Val)
  | VSHNe NeSysHCom'
  deriving Show

type VTy = Val

data Val
  = VSub Val Sub

  -- Neutrals. Not stable under substitution, no computation can ever match on them.
  | VNe Ne IVarSet

  -- Semineutrals. Not stable under substitution but computation can match on them.
  | VGlueTy VTy NeSys'                                        -- coe can act on it
  | VHDCon {-# nounpack #-} HDConInfo Env VDSpine Sub IVarSet -- case can act on it
  | VHCom I I VTy NeSysHCom' Val IVarSet                      -- coe and case can act on it
  | VGlue Val ~NeSys' NeSys IVarSet                            -- unglue can act on it

  -- Canonicals. Stable under substitution.
  | VPi VTy NamedClosure
  | VLam NamedClosure
  | VPath NamedIClosure Val Val
  | VPLam ~Val ~Val NamedIClosure  -- annotated with endpoints
  | VSg VTy NamedClosure
  | VPair Name Val Val
  | VWrap Name VTy
  | VPack Name Val
  | VU
  | VLine NamedIClosure
  | VLLam NamedIClosure
  | VTyCon {-# nounpack #-} TyConInfo Env
  | VHTyCon {-# nounpack #-} HTyConInfo Env
  | VDCon {-# nounpack #-} DConInfo VDSpine

  -- misc
  | VHole VHole
  deriving Show

data VHole = VSrcHole (Maybe Name) (DontShow SourcePos) Sub Env
           | VErrHole String
  deriving Show

data Ne
  = NLocalVar Lvl
  | NDontRecurse {-# nounpack #-} RecInfo
  | NSub Ne Sub
  | NApp Ne Val
  | NPApp ~Val ~Val Ne I
  | NLApp Ne I
  | NProj1 Ne Name
  | NProj2 Ne Name
  | NUnpack Ne Name
  | NCoe I I (BindI Val) Val
  | NUnglue Ne NeSys
  | NCase Val NamedClosure CaseTag (EvalClosure Cases)
  | NHCase Val NamedClosure CaseTag (EvalClosure HCases)
  deriving Show

data VDSpine
  = VDNil
  | VDCons Val VDSpine
  deriving Show

--------------------------------------------------------------------------------

vVar :: Lvl -> Val
vVar x = VNe (NLocalVar x) mempty
{-# inline vVar #-}

type DomArg  = (?dom  :: Lvl)    -- fresh LocalVar
type IDomArg = (?idom :: IVar)   -- fresh LocalVar

--------------------------------------------------------------------------------

data Recurse = Recurse ~(DontShow Val) | DontRecurse
  deriving Show

type RecurseArg = (?recurse :: Recurse)

data EvalClosure a = EC Sub Env Recurse a
  deriving Show

-- | Defunctionalized closures.
data Closure
  -- ^ Body of vanilla term evaluation.
  = CEval (EvalClosure Tm)

  -- ^ Body of lambdaCase
  | CSplit NamedClosure CaseTag (EvalClosure Cases)
  | CHSplit NamedClosure CaseTag (EvalClosure HCases) -- HIT version

  -- ^ Body of function coercions.
  | CCoePi I I (BindI VTy) (BindI NamedClosure) Val

  -- ^ Body of function hcom.
  | CHComPi I I VTy NamedClosure NeSysHCom Val

  | CConst Val

  | C'λ'a''a        -- λ a. a
  | C'λ'a'i''a      -- λ a i. a
  | C'λ'a'i'j''a    -- λ a i j. a

{-
  coeIsEquiv : (A : I → U) (r r' : I) → isEquiv (λ x. coe r r' A x)
  coeIsEquiv A r r' =

    ffill i x      := coe r i A x
    gfill i x      := coe i r A x
    linvfill i x j := hcom r i (A r) [j=0 k. x; j=1 k. coe k r A (coe r k A x)] x
    rinvfill i x j := hcom i r (A i) [j=0 k. coe k i A (coe i k A x); j=1 k. x] x

    g    := λ x^0. gfill r' x
    linv := λ x^0 j^1. linvfill r' x j
    rinv := λ x^0 j^1. rinvfill r' x j
    coh  := λ x^0 l^1 k^2. com r r' A [k=0 i. ffill i (linvfill i x l)
                                      ;k=1 i. ffill i x
                                      ;l=0 i. ffill i x
                                      ;l=1 i. rinvfill i (ffill i x) k]
                                      x
-}

  | CCoeAlong (BindI Val) I I -- λ x. coe a r r' x
  | CCoeLinv0 (BindI Val) I I -- a r r'
  | CCoeRinv0 (BindI Val) I I -- a r r'
  | CCoeCoh0 (BindI Val)  I I -- a r r'

-- isEquiv : (A → B) → U
-- isEquiv A B f :=
--     (g^1    : B → A)
--   × (linv^2 : (x^4 : A) → Path A x (g (f x)))
--   × (rinv^3 : (x^5 : B) → Path B (f (g x)) x)
--   × (coh    : (x^6 : A) →
--             Path (i^7) (Path B (f (linv x {x}{g (f x)} i)) (f x))
--                   (refl B (f x))
--                   (rinv (f x)))

  | CIsEquiv1 Val Val Val         -- A B f
  | CIsEquiv2 Val Val Val Val     -- A B f g
  | CIsEquiv3 Val Val Val Val Val -- A B f g linv
  | CIsEquiv4 Val Val Val         -- A f g
  | CIsEquiv5 Val Val Val         -- B f g
  | CIsEquiv6 Val Val Val Val Val -- B f g linv rinv


  -- [A, B]  equiv A B = (f* : A -> B) × isEquiv A B f
  | CEquiv Val Val

  -- [A]  (B* : U) × equiv B A
  | CEquivInto Val

  deriving Show

-- | Defunctionalized closures for ivar abstraction
data IClosure
  = ICEval Sub Env Recurse Tm
  | ICCoePath I I (BindI NamedIClosure) (BindI Val) (BindI Val) Val
  | ICHComPath I I NamedIClosure Val Val NeSysHCom Val
  | ICConst Val
  | ICIsEquiv7 Val Val Val Val Val
  | ICHComLine I I NamedIClosure NeSysHCom Val
  | ICCoeLine I I (BindI NamedIClosure) Val

  | ICCoeLinv1 (BindI Val) I I Val -- a r r' x
  | ICCoeRinv1 (BindI Val) I I Val -- a r r' x

{-
  coeIsEquiv : (A : I → U) (r r' : I) → isEquiv (λ x. coe r r' A x)
  coeIsEquiv A r r' =

    ffill i x      := coe r i A x
    gfill i x      := coe i r A x
    linvfill i x j := hcom r i (A r) [j=0 k. x; j=1 k. coe k r A (coe r k A x)] x
    rinvfill i x j := hcom i r (A i) [j=0 k. coe k i A (coe i k A x); j=1 k. x] x

    g    := λ x^0. gfill r' x
    linv := λ x^0 j^1. linvfill r' x j
    rinv := λ x^0 j^1. rinvfill r' x j
    coh  := λ x^0 l^1 k^2. com r r' A [k=0 i. ffill i (linvfill i x l)
                                      ;k=1 i. ffill i x
                                      ;l=0 i. ffill i x
                                      ;l=1 i. rinvfill i (ffill i x) k]
                                      x
-}

  | ICCoeCoh1 (BindI Val) I I Val    -- a r r' x
  | ICCoeCoh2 (BindI Val) I I Val I  -- a r r' x l
  | ICCoeCoh0Rhs (BindI Val) I I Val -- a r r' x

  | ICSym Val ~Val ~Val Val
  | ICTrans Val ~Val ~Val ~Val Val Val
  | ICAp Val ~Val ~Val Val

  | ICBindI (BindI Val)
  deriving Show

--------------------------------------------------------------------------------

rebind :: BindI a -> b -> BindI b
rebind (BindI x i _) b = BindI x i b
{-# inline rebind #-}

-- Substitution
----------------------------------------------------------------------------------------------------

instance SubAction NeCof where
  sub = \case
    NCEq i j    -> NCEq (sub i) (sub j)
    NCAnd c1 c2 -> NCAnd (sub c1) (sub c2)

instance SubAction a => SubAction (BindCofLazy a) where
  sub (BindCofLazy cof a) = BindCofLazy (sub cof) (sub a); {-# inline sub #-}

instance SubAction a => SubAction (BindCof a) where
  sub (BindCof cof a) = BindCof (sub cof) (sub a); {-# inline sub #-}

instance SubAction Val where
  sub = \case
    VSub v s' -> VSub v (sub s')
    v         -> VSub v ?sub
  {-# inline sub #-}

instance SubAction Ne where
  sub = \case
    NSub n s' -> NSub n (sub s')
    n         -> NSub n ?sub
  {-# inline sub #-}

instance SubAction NeSys where
  sub = \case
    NSEmpty      -> NSEmpty
    NSCons t sys -> NSCons (sub t) (sub sys)

instance SubAction NeSysHCom where
  sub = \case
    NSHEmpty      -> NSHEmpty
    NSHCons t sys -> NSHCons (sub t) (sub sys)

instance SubAction Env where
  sub e = case e of
    ENil     -> ENil
    EDef e v -> EDef (sub e) (sub v)

instance SubAction a => SubAction (BindI a) where
  sub (BindI x i a) =
    let fresh = dom ?sub in
    let ?sub  = setDomCod (fresh + 1) i ?sub `ext` IVar fresh in
    seq ?sub (BindI x fresh (sub a))
  {-# inline sub #-}

instance SubAction a => SubAction (BindILazy a) where
  sub (BindILazy x i a) =
    let fresh = dom ?sub in
    let ?sub  = setDomCod (fresh + 1) i ?sub `ext` IVar fresh in
    seq ?sub (BindILazy x fresh (sub a))
  {-# inline sub #-}

instance SubAction NamedClosure where
  sub (NCl x cl) = NCl x (sub cl)
  {-# inline sub #-}

instance SubAction NamedIClosure where
  sub (NICl x cl) = NICl x (sub cl)
  {-# inline sub #-}

instance SubAction (EvalClosure a) where
  sub (EC s' env rc t) = EC (sub s') (sub env) rc t
  {-# inline sub #-}

instance SubAction Closure where
  sub cl = case cl of
    CEval     ecl     -> CEval (sub ecl)
    CSplit  b tag ecl -> CSplit (sub b) tag (sub ecl)
    CHSplit b tag ecl -> CHSplit (sub b) tag (sub ecl)

    -- note: recursive closure sub below! This is probably
    -- fine, because recursive depth is bounded by Pi type nesting.
    CCoePi r r' a b t ->
      CCoePi (sub r) (sub r') (sub a) (sub b) (sub t)

    CHComPi r r' a b sys base ->
      CHComPi (sub r) (sub r') (sub a) (sub b) (sub sys) (sub base)

    CConst t                  -> CConst (sub t)
    CIsEquiv1 a b f           -> CIsEquiv1 (sub a) (sub b) (sub f)
    CIsEquiv2 a b f g         -> CIsEquiv2 (sub a) (sub b) (sub f) (sub g)
    CIsEquiv3 a b f g linv    -> CIsEquiv3 (sub a) (sub b) (sub f) (sub g) (sub linv)
    CIsEquiv4 a f g           -> CIsEquiv4 (sub a) (sub f) (sub g)
    CIsEquiv5 b f g           -> CIsEquiv5 (sub b) (sub f) (sub g)
    CIsEquiv6 b f g linv rinv -> CIsEquiv6 (sub b) (sub f) (sub g) (sub linv) (sub rinv)
    CEquiv a b                -> CEquiv (sub a) (sub b)
    CEquivInto a              -> CEquivInto (sub a)
    C'λ'a''a                  -> C'λ'a''a
    C'λ'a'i''a                -> C'λ'a'i''a
    C'λ'a'i'j''a              -> C'λ'a'i'j''a
    CCoeAlong a r r'          -> CCoeAlong (sub a) (sub r) (sub r')
    CCoeLinv0 a r r'          -> CCoeLinv0 (sub a) (sub r) (sub r')
    CCoeRinv0 a r r'          -> CCoeRinv0 (sub a) (sub r) (sub r')
    CCoeCoh0 a r r'           -> CCoeCoh0 (sub a) (sub r) (sub r')

instance SubAction IClosure where
  sub cl = case cl of
    ICEval s' env rc t ->
      ICEval (sub s') (sub env) rc t

    -- recursive sub here as well!
    ICCoePath r r' a lh rh p ->
      ICCoePath (sub r) (sub r') (sub a) (sub lh) (sub rh) (sub p)

    ICHComPath r r' a lhs rhs sys base ->
      ICHComPath (sub r) (sub r') (sub a) (sub lhs) (sub rhs) (sub sys) (sub base)

    ICConst t               -> ICConst (sub t)
    ICIsEquiv7 b f g linv x -> ICIsEquiv7 (sub b) (sub f) (sub g) (sub linv) (sub x)
    ICHComLine r r' a t b   -> ICHComLine (sub r) (sub r') (sub a) (sub t) (sub b)
    ICCoeLine r r' a t      -> ICCoeLine (sub r) (sub r') (sub a) (sub t)
    ICCoeLinv1 a x r r'     -> ICCoeLinv1 (sub a) (sub x) (sub r) (sub r')
    ICCoeRinv1 a x r r'     -> ICCoeRinv1 (sub a) (sub x) (sub r) (sub r')
    ICSym a x y p           -> ICSym (sub a) (sub x) (sub y) (sub p)
    ICTrans a x y z p q     -> ICTrans (sub a) (sub x) (sub y) (sub z) (sub p) (sub q)
    ICAp f x y p            -> ICAp (sub f) (sub x) (sub y) (sub p)
    ICCoeCoh1 a r r' x      -> ICCoeCoh1 (sub a) (sub r) (sub r') (sub x)
    ICCoeCoh2 a r r' x l    -> ICCoeCoh2 (sub a) (sub r) (sub r') (sub x) (sub l)
    ICCoeCoh0Rhs a r r' x   -> ICCoeCoh0Rhs (sub a) (sub r) (sub r') (sub x)
    ICBindI a               -> ICBindI (sub a)

instance SubAction VDSpine where
  sub = \case
    VDNil       -> VDNil
    VDCons v vs -> VDCons (sub v) (sub vs)

instance SubAction a => SubAction (WithIS a) where
  sub (WIS a is) = WIS (sub a) (sub is)
  {-# inline sub #-}

--------------------------------------------------------------------------------

makeFields ''BindI
makeFields ''BindILazy
makeFields ''BindCof
makeFields ''BindCofLazy
makeFields ''NamedClosure
makeFields ''NamedIClosure
makeFields ''NeCof'
makeFields ''DefInfo
makeFields ''DConInfo
makeFields ''TyConInfo
makeFields ''RecInfo
makeFields ''HTyConInfo
makeFields ''HDConInfo
makeFields ''WithIS
