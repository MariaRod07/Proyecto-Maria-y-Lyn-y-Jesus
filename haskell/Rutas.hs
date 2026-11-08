module Rutas
  ( rutasValidas
  , disponibleEn
  , conexionValida
  , escalas
  ) where

import Grafo (vuelosDesde)
import Tipos

disponibleEn :: Dia -> Vuelo -> Bool
disponibleEn dia v = dia `elem` frecuencia v

conexionValida :: Minutos -> Vuelo -> Vuelo -> Bool
conexionValida tmc anterior siguiente =
  salida siguiente >= llegada anterior + tmc

escalas :: Ruta -> Int
escalas ruta = length ruta - 1

rutasValidas
  :: Minutos
  -> Maybe Int
  -> Dia
  -> Grafo
  -> Ciudad
  -> Ciudad
  -> [Ruta]
rutasValidas tmc limite dia grafo desde hasta
  | desde == hasta = []
  | otherwise      = dfs desde [desde] Nothing []
  where
    dfs :: Ciudad -> [Ciudad] -> Maybe Vuelo -> [Vuelo] -> [Ruta]
    dfs actual visitados anterior tomados
      | actual == hasta = [reverse tomados]
      | otherwise =
          [ ruta
          | v <- vuelosDesde grafo actual
          , disponibleEn dia v
          , destino v `notElem` visitados
          , maybe True (\p -> conexionValida tmc p v) anterior
          , dentroDelLimite (length tomados)
          , ruta <- dfs (destino v) (destino v : visitados) (Just v) (v : tomados)
          ]
