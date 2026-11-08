module Tipos
  ( Ciudad
  , Minutos
  , Dia (..)
  , todosLosDias
  , abreviaturas
  , Vuelo (..)
  , Ruta
  , Grafo
  ) where

type Ciudad = String
type Minutos = Int

data Dia
  = Lunes | Martes | Miercoles | Jueves | Viernes | Sabado | Domingo
  deriving (Eq, Ord, Show, Enum, Bounded)

todosLosDias :: [Dia]
todosLosDias = [minBound .. maxBound]

abreviaturas :: [(String, Dia)]
abreviaturas =
  [ ("L", Lunes), ("M", Martes), ("Mi", Miercoles), ("J", Jueves)
  , ("V", Viernes), ("S", Sabado), ("D", Domingo) ]

data Vuelo = Vuelo
  { codigo     :: String
  , origen     :: Ciudad
  , destino    :: Ciudad
  , salida     :: Minutos
  , llegada    :: Minutos
  , costo      :: Int
  , frecuencia :: [Dia]
  } deriving (Eq, Show)

type Ruta = [Vuelo]

type Grafo = [(Ciudad, [Vuelo])]
