module Consultas
  ( salidasDesde
  , llegadasA
  , vuelosDelDia
  ) where

import Data.List (sortOn)

import Grafo (vuelosDesde)
import Tipos

salidasDesde :: Grafo -> Ciudad -> [Vuelo]
salidasDesde grafo c = sortOn salida (vuelosDesde grafo c)

llegadasA :: Grafo -> Ciudad -> [Vuelo]
llegadasA grafo c =
  sortOn llegada [ v | (_, vs) <- grafo, v <- vs, destino v == c ]

vuelosDelDia :: Dia -> [Vuelo] -> [Vuelo]
vuelosDelDia dia = sortOn salida . filter ((dia `elem`) . frecuencia)
