module Optimizacion
  ( costoTotal
  , tiempoTotal
  , esperas
  , quicksortPor
  , mergesortPor
  , ordenarPorCosto
  , ordenarPorTiempo
  , minimoPor
  , rutaMasBarata
  , rutaMasRapida
  ) where

import Tipos

-- Suma el costo de todos los vuelos de una ruta
costoTotal :: Ruta -> Int
costoTotal = foldr (\v acc -> costo v + acc) 0

-- Calcula el tiempo total (desde que sale el primero hasta que llega el ultimo)
tiempoTotal :: Ruta -> Minutos
tiempoTotal []                 = 0
tiempoTotal ruta@(primero : _) = llegada (last ruta) - salida primero

esperas :: Ruta -> [Minutos]
esperas ruta = zipWith (\a b -> salida b - llegada a) ruta (drop 1 ruta)

-- Algoritmo quicksort
quicksortPor :: Ord k => (a -> k) -> [a] -> [a]
quicksortPor _ [] = []
quicksortPor clave (pivote : resto) =
  quicksortPor clave menores ++ [pivote] ++ quicksortPor clave mayores
  where
    menores = [ x | x <- resto, clave x <  clave pivote ]
    mayores = [ x | x <- resto, clave x >= clave pivote ]

-- Algoritmo mergesort
mergesortPor :: Ord k => (a -> k) -> [a] -> [a]
mergesortPor _ []  = []
mergesortPor _ [x] = [x]
mergesortPor clave xs =
  fusionar (mergesortPor clave izquierda) (mergesortPor clave derecha)
  where
    (izquierda, derecha) = splitAt (length xs `div` 2) xs

    fusionar [] ys = ys
    fusionar ys [] = ys
    fusionar (a : as) (b : bs)
      | clave a <= clave b = a : fusionar as (b : bs)
      | otherwise          = b : fusionar (a : as) bs

-- Ordena por costo (desempata por tiempo)
ordenarPorCosto :: [Ruta] -> [Ruta]
ordenarPorCosto = quicksortPor (\r -> (costoTotal r, tiempoTotal r))

-- Ordena por tiempo (desempata por costo)
ordenarPorTiempo :: [Ruta] -> [Ruta]
ordenarPorTiempo = mergesortPor (\r -> (tiempoTotal r, costoTotal r))

minimoPor :: Ord k => (a -> k) -> [a] -> Maybe a
minimoPor _ [] = Nothing
minimoPor clave (x : xs) =
  Just (foldl (\mejor y -> if clave y < clave mejor then y else mejor) x xs)

rutaMasBarata :: [Ruta] -> Maybe Ruta
rutaMasBarata = minimoPor (\r -> (costoTotal r, tiempoTotal r))

rutaMasRapida :: [Ruta] -> Maybe Ruta
rutaMasRapida = minimoPor (\r -> (tiempoTotal r, costoTotal r))
