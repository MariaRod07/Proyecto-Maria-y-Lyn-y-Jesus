{-|
Module      : Consultas
Description : Consultas básicas de partidas y llegadas (Módulo 1).

Las tres funciones de este módulo ilustran formas equivalentes de filtrar
listas en Haskell: búsqueda por clave en la lista de adyacencia, list
comprehension con varios generadores y la función de alto orden 'filter'.
-}
module Consultas
  ( salidasDesde
  , llegadasA
  , vuelosDelDia
  ) where

import Data.List (sortOn)

import Grafo (vuelosDesde)
import Tipos

-- | Vuelos que salen de una ciudad, ordenados por hora de salida.
--   Aprovecha la lista de adyacencia: una sola búsqueda por clave.
salidasDesde :: Grafo -> Ciudad -> [Vuelo]
salidasDesde grafo c = sortOn salida (vuelosDesde grafo c)

-- | Vuelos que llegan a una ciudad, ordenados por hora de llegada.
--   No existe índice por destino, así que se recorre todo el grafo con una
--   list comprehension de dos generadores (@(_, vs) <- grafo@, @v <- vs@) y
--   un filtro (@destino v == c@).
llegadasA :: Grafo -> Ciudad -> [Vuelo]
llegadasA grafo c =
  sortOn llegada [ v | (_, vs) <- grafo, v <- vs, destino v == c ]

-- | Vuelos que operan en un día dado. Misma idea con 'filter' y una sección
--   de operador (@(dia `elem`) . frecuencia@) en lugar de comprehension.
vuelosDelDia :: Dia -> [Vuelo] -> [Vuelo]
vuelosDelDia dia = sortOn salida . filter ((dia `elem`) . frecuencia)
