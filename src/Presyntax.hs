
module Presyntax where

import Common

type Ty = Tm

data LamAnnot
  = LANone
  | LAAnn Ty
  | LADesugared Ty
  deriving Show

data Tm
  = Ident Name
  | LocalLvl Lvl                  -- @n
  | TopLvl Lvl (Maybe Lvl)        -- @@n   or   @@n.m    (the latter identifies a data constructor)
  | Pos (DontShow SourcePos) Tm
  | I
  | ILvl IVar
  | I0
  | I1
  | Let Name (Maybe Ty) Tm Tm
  | Pi Name Ty Ty
  | App Tm Tm
  | PApp Tm Tm Tm Tm        -- explicit endpoints: t {l}{r} u
  | Lam Name LamAnnot Tm
  | PLam Tm Tm Name Tm      -- explicit endpoints: λ {l}{r} x. t

  | Sg Name Ty Ty
  | Pair Tm Tm
  | Proj1 Tm
  | Proj2 Tm
  | ProjField Tm Name

  | Wrap Name Ty
  | Hole (Maybe Name) (DontShow SourcePos)

  | Case Tm (Maybe (Name, Ty)) [CaseItem]
  | Split [CaseItem]

  | U
  | Path Tm Tm                                -- x = y
  | DepPath BindMaybe Tm Tm                   -- x ={i.A} y | x ={p} y

  | Coe Tm Tm BindMaybe Tm                    -- coe r r' i A t
  | HCom Tm Tm (Maybe Ty) SysHCom Tm          -- hcom r r' {A} [α x. t] u
  | Com Tm Tm BindMaybe SysHCom Tm            -- com r r' i A [α x. t] u

  | GlueTy Ty Sys                             -- Glue A [α. B]
  | GlueTm Tm (Maybe Sys) Sys                 -- glue a {<equivsys>} <fibersys>
  | Unglue Tm

  | Refl          -- checkable refl
  | Sym Tm
  | Trans Tm Tm
  | Ap Tm Tm
  deriving Show

data CofEq = CofEq Tm Tm
  deriving Show

data Cof = CTrue | CAnd {-# unpack #-} CofEq Cof
  deriving Show

data Sys = SEmpty | SCons Cof Tm Sys
  deriving Show

data BindMaybe = Bind Name Tm | DontBind Tm
  deriving Show

data SysHCom = SHEmpty | SHCons Cof BindMaybe SysHCom
  deriving Show

type Constructor = (DontShow SourcePos, Name, [(Name, Ty)])
type HConstructor = (DontShow SourcePos, Name, [(Name, Ty)], Maybe Sys)
type CaseItem = (DontShow SourcePos, Name, [Name], Tm)

data Top
  = TDef    (DontShow SourcePos) Name (Maybe Ty) Tm Top
  | TData   (DontShow SourcePos) Name [(Name, Ty)] [Constructor] Top
  | THData  (DontShow SourcePos) Name [(Name, Ty)] [HConstructor] Top
  | TImport (DontShow SourcePos) Name Top
  | TEmpty
  deriving Show

unPos :: Tm -> Tm
unPos (Pos _ a) = a
unPos a         = a
{-# inline unPos #-}
