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

construirGrafo :: [Vuelo] -> Grafo
construirGrafo vs =
  [ (origen v, grupo)
  | grupo@(v : _) <- groupBy ((==) `on` origen) (sortOn origen vs) ]

vuelosDesde :: Grafo -> Ciudad -> [Vuelo]
vuelosDesde grafo c = fromMaybe [] (lookup c grafo)

ciudades :: Grafo -> [Ciudad]
ciudades grafo =
  sort (nub [ c | (_, vs) <- grafo, v <- vs, c <- [origen v, destino v] ])

buscarCiudad :: Grafo -> String -> Maybe Ciudad
buscarCiudad grafo texto =
  case [ c | c <- ciudades grafo, normalizar c == normalizar texto ] of
    (c : _) -> Just c
    []      -> Nothing
  where
    normalizar = map toLower . unwords . words
