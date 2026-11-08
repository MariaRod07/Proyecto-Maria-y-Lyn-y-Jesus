{-|
Module      : Tipos
Description : Modelado de datos del motor LogiExpress (paradigma funcional).

Todos los tipos de este módulo son inmutables: el grafo se construye una sola
vez a partir de @vuelos.txt@ y nunca se modifica. Cada consulta produce listas
nuevas en lugar de alterar estructuras existentes (persistencia estructural).
-}
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

-- | Nombre de una ciudad tal como aparece en el archivo (ej. @"Pto Ordaz"@).
type Ciudad = String

-- | Instante del día expresado en minutos desde las 00:00 (07:30 -> 450).
--   Trabajar con enteros permite aritmética pura de tiempo (sumas, restas y
--   comparaciones) sin manipular cadenas "HH:MM".
type Minutos = Int

-- | Días de la semana. Las instancias derivadas automáticamente aportan:
--
--   * 'Eq'            : comparar días (compatibilidad de frecuencia).
--   * 'Ord'           : ordenar días.
--   * 'Enum','Bounded': enumerar todos los días con @[minBound .. maxBound]@.
--   * 'Show'          : imprimirlos en consola.
data Dia
  = Lunes | Martes | Miercoles | Jueves | Viernes | Sabado | Domingo
  deriving (Eq, Ord, Show, Enum, Bounded)

-- | Lista completa de días, equivalente a la frecuencia @"Diario"@.
todosLosDias :: [Dia]
todosLosDias = [minBound .. maxBound]

-- | Abreviaturas usadas en el campo frecuencia de @vuelos.txt@
--   (@"L-M-Mi-J-V"@). Tabla de asociación consultada con 'lookup' en ambos
--   sentidos: parseo (abreviatura -> día) e impresión (día -> abreviatura).
abreviaturas :: [(String, Dia)]
abreviaturas =
  [ ("L", Lunes), ("M", Martes), ("Mi", Miercoles), ("J", Jueves)
  , ("V", Viernes), ("S", Sabado), ("D", Domingo) ]

-- | Un vuelo es una arista dirigida y ponderada del grafo: une el nodo
--   'origen' con el nodo 'destino' y lleva dos pesos (costo y tiempos).
data Vuelo = Vuelo
  { codigo     :: String   -- ^ identificador del vuelo, ej. @"Vlo#1"@
  , origen     :: Ciudad   -- ^ ciudad de partida (nodo origen de la arista)
  , destino    :: Ciudad   -- ^ ciudad de llegada (nodo destino de la arista)
  , salida     :: Minutos  -- ^ hora de salida en minutos desde las 00:00
  , llegada    :: Minutos  -- ^ hora de llegada en minutos desde las 00:00
  , costo      :: Int      -- ^ precio del boleto
  , frecuencia :: [Dia]    -- ^ días de la semana en los que opera
  } deriving (Eq, Show)

-- | Una ruta es una secuencia de vuelos consecutivos. Una ruta directa es una
--   lista de un solo elemento; una ruta con K escalas tiene K+1 vuelos.
type Ruta = [Vuelo]

-- | Grafo dirigido ponderado representado como lista de adyacencia: cada
--   ciudad se asocia con la lista de vuelos (aristas) que parten de ella.
--   Es una estructura puramente funcional: nunca se muta, solo se consulta.
type Grafo = [(Ciudad, [Vuelo])]
