{-|
Module      : Grafo
Description : Construcción y consulta del grafo inmutable (Módulo 1).

El grafo es una lista de adyacencia @[(Ciudad, [Vuelo])]@ construida una sola
vez con funciones de "Data.List". Como es inmutable, puede compartirse entre
todas las consultas sin riesgo de que una búsqueda altere los datos de otra.
-}
module Grafo
  ( construirGrafo
  , vuelosDesde
  , ciudades
  , buscarCiudad
  ) where

import Data.Char (toLower)
import Data.Function (on)
import Data.List (groupBy, nub, sort, sortOn)
import Data.Maybe (fromMaybe)

import Tipos

-- | Agrupa los vuelos por ciudad de origen. Se ordena primero con 'sortOn'
--   para que 'groupBy' (que solo agrupa elementos adyacentes) reúna todos los
--   vuelos de una misma ciudad. El patrón @grupo@(v : _)@ garantiza que cada
--   grupo es no vacío sin usar funciones parciales como 'head'.
construirGrafo :: [Vuelo] -> Grafo
construirGrafo vs =
  [ (origen v, grupo)
  | grupo@(v : _) <- groupBy ((==) `on` origen) (sortOn origen vs) ]

-- | Aristas salientes de una ciudad. Si la ciudad no tiene vuelos de salida
--   (o no existe) devuelve la lista vacía, lo que detiene la búsqueda DFS de
--   forma natural.
vuelosDesde :: Grafo -> Ciudad -> [Vuelo]
vuelosDesde grafo c = fromMaybe [] (lookup c grafo)

-- | Todas las ciudades del grafo (orígenes y destinos), sin repetidos y en
--   orden alfabético.
ciudades :: Grafo -> [Ciudad]
ciudades grafo =
  sort (nub [ c | (_, vs) <- grafo, v <- vs, c <- [origen v, destino v] ])

-- | Busca una ciudad ignorando mayúsculas y espacios sobrantes, de modo que
--   el usuario pueda escribir @"pto ordaz"@ en el menú. 'words' / 'unwords'
--   normalizan los espacios internos.
buscarCiudad :: Grafo -> String -> Maybe Ciudad
buscarCiudad grafo texto =
  case [ c | c <- ciudades grafo, normalizar c == normalizar texto ] of
    (c : _) -> Just c
    []      -> Nothing
  where
    normalizar = map toLower . unwords . words
