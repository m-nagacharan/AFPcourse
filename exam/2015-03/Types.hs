{-# LANGUAGE RankNTypes #-}
module Types where
import Control.Monad

-- Problem 3a:

eqLa :: EqT a -> EqT [a]
eqLa _eqa []      []      = True
eqLa  eqa (x:xs)  (y:ys)  = eqa x y && eqLa eqa xs ys
eqLa _eqa _       _       = False

-- Variants:

-- Almost correct:
eqLa' :: EqT a -> EqT [a]
eqLa' eq = \xs ys -> length xs == length ys && and (zipWith eq xs ys)
-- fails to terminate on eqLa' (==) [1,2..] [1,1..]

-- Errors:
-- eqLa eqa = and . map (uncurry eqa) . zip
--  type error, wrong number of arguments and zip cuts longer list
-- Closer, but still wrong due to "zip cuts longer list"
eqLa'' :: EqT a -> EqT [a]
eqLa'' eqa = \xs ys -> and . map (uncurry eqa) $ zip xs ys

eqLa3 :: EqT a -> EqT [a]
eqLa3 eqa xs ys = and $ liftM2 eqa xs ys

-- Problem 3b:

retStateT  :: RetT m -> RetT (StateT s m)
retStateT retm  = \a -> StateT $ \s -> retm (a, s)

bindStateT :: BindT m -> BindT (StateT s m)
bindStateT bindm  = \(StateT s2mas) f ->
                      StateT $ \s ->  s2mas s `bindm` \(a, s') ->
                                      let StateT s2bs  = f a
                                      in s2bs s'

-- Variants:

bindStateT' :: BindT m -> BindT (StateT s m)
bindStateT' bindm = \g f -> StateT $ \s ->  runStateT g s `bindm` \(a, s') ->
                                            runStateT (f a) s'

bindStateT'' :: BindT m -> BindT (StateT s m)
bindStateT'' bindm = \g f -> StateT $ \s ->  runStateT g s `bindm` uncurry (runStateT . f)

-- Errors:
-- retStateT' m = \a -> StateT $ \s -> liftM (\x -> (x,s)) m
--   No Monad instance, type error of m

-- ================================================================

-- Exam question code:
type EqT a = a -> a -> Bool
data EqDict  a = EqDict   { eq      :: EqT a }

data Foo = Foo String (Maybe String)  -- Personal identification number + optional comment

-- instance Eq Foo

eqFoo :: EqT Foo
eqFoo (Foo pa _ca) (Foo pb _cb) = pa == pb

eqFooD :: EqDict Foo
eqFooD = EqDict eqFoo

-- instance Eq a => Eq [a]
eqListD :: EqDict a -> EqDict [a]
eqListD (EqDict eqa) = EqDict (eqLa eqa)


----------------

type RetT   m = forall a.    a -> m a
type BindT  m = forall a b.  m a -> (a -> m b) -> m b
-- Monad dictionary
data MonadDict m = MonadDict  { ret   :: RetT m
                              , bind  :: BindT m
                              }
-- instance Monad Maybe
monadMaybeD :: MonadDict Maybe
monadMaybeD = MonadDict returnM bindM

returnM :: RetT Maybe
returnM = Just

bindM :: BindT Maybe
bindM mx f = maybe Nothing f mx

newtype StateT s m a = StateT {runStateT :: s -> m (a, s)}

-- instance Monad m => Monad (StateT s m)
monadStateT :: MonadDict m -> MonadDict (StateT s m)
monadStateT (MonadDict retm bindm) = MonadDict (retStateT retm) (bindStateT bindm)
