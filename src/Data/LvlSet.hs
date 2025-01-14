
-- | Level sets (limited to 64 entries).

module Data.LvlSet where

import Data.Foldable
import Common

newtype LvlSet = LvlSet Word deriving (Eq, Bits) via Word

instance Semigroup LvlSet where
  (<>) = (.|.)
  {-# inline (<>) #-}

instance Monoid LvlSet where
  mempty = LvlSet 0
  {-# inline mempty #-}

singleton :: Lvl -> LvlSet
singleton x = insert x mempty
{-# inline singleton #-}

insert :: Lvl -> LvlSet -> LvlSet
insert (Lvl x) (LvlSet s) = LvlSet (unsafeShiftL 1 (w2i x) .|. s)
{-# inline insert #-}

null :: LvlSet -> Bool
null (LvlSet 0) = True
null _          = False
{-# inline null #-}

delete :: Lvl -> LvlSet -> LvlSet
delete (Lvl x) (LvlSet s) = LvlSet (complement (unsafeShiftL 1 (w2i x)) .&. s)
{-# inline delete #-}

member :: Lvl -> LvlSet -> Bool
member (Lvl x) (LvlSet s) = (unsafeShiftL 1 (w2i x) .&. s) /= 0
{-# inline member #-}

toList :: LvlSet -> [Lvl]
toList = Data.LvlSet.foldr (:) []

fromList :: [Lvl] -> LvlSet
fromList = foldl' (flip insert) mempty

popSmallest :: LvlSet -> (LvlSet -> Lvl -> a) -> a -> a
popSmallest (LvlSet s) success ~fail = case s of
  0 -> fail
  s -> let i = Lvl (ctz s) in success (delete i (LvlSet s)) i
{-# inline popSmallest #-}

instance Show LvlSet where
  show = show . Data.LvlSet.toList

foldl :: forall b. (b -> Lvl -> b) -> b -> LvlSet -> b
foldl f b s = go s b where
  go :: LvlSet -> b -> b
  go s b = popSmallest s (\s i -> go s (f b i)) b
{-# inline foldl #-}

foldr :: forall b. (Lvl -> b -> b) -> b -> LvlSet -> b
foldr f b s = go s where
  go :: LvlSet -> b
  go s = popSmallest s (\s i -> f i $! go s) b
{-# inline foldr #-}

foldrAccum :: forall acc r. (Lvl -> (acc -> r) -> acc -> r) -> acc -> r -> LvlSet -> r
foldrAccum f acc r s = go s acc where
  go :: LvlSet -> acc -> r
  go s acc = popSmallest s (\s i -> f i (go s) acc) r
{-# inline foldrAccum #-}
