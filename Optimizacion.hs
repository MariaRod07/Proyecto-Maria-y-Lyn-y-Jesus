{-|
Module      : Optimizacion
Description : Optimización por doble criterio y ordenamiento (Módulo 3).

Métricas de una ruta (costo total, tiempo total, esperas), dos algoritmos de
ordenamiento implementados sobre listas (quicksort y mergesort) parametrizados
por una función clave, y la selección de la ruta mínima con un plegado.
-}
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

-- | Sumatoria del precio de los boletos, expresada como un plegado a la
--   derecha sobre la lista de vuelos.
costoTotal :: Ruta -> Int
costoTotal = foldr (\v acumulado -> costo v + acumulado) 0

-- | Tiempo total de viaje: diferencia entre la llegada al destino final y la
--   salida del primer vuelo. Al medirse entre extremos, incluye de forma
--   implícita los tiempos de espera en cada escala.
tiempoTotal :: Ruta -> Minutos
tiempoTotal []                 = 0
tiempoTotal ruta@(primero : _) = llegada (last ruta) - salida primero

-- | Tiempos de espera en cada escala: 'zipWith' empareja cada vuelo con el
--   siguiente (@drop 1 ruta@) y resta llegada y salida.
esperas :: Ruta -> [Minutos]
esperas ruta = zipWith (\a b -> salida b - llegada a) ruta (drop 1 ruta)

-- | Quicksort sobre listas parametrizado por una función clave. Las dos
--   particiones se expresan con list comprehensions; la concatenación con
--   @++@ reconstruye la lista ordenada. Por la evaluación perezosa,
--   @take 1 (quicksortPor f xs)@ solo evalúa la rama necesaria para obtener
--   el mínimo.
quicksortPor :: Ord k => (a -> k) -> [a] -> [a]
quicksortPor _ [] = []
quicksortPor clave (pivote : resto) =
  quicksortPor clave menores ++ [pivote] ++ quicksortPor clave mayores
  where
    menores = [ x | x <- resto, clave x <  clave pivote ]
    mayores = [ x | x <- resto, clave x >= clave pivote ]

-- | Mergesort sobre listas: divide con 'splitAt' y fusiona dos sublistas ya
--   ordenadas. Es estable: ante claves iguales conserva el orden original.
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

-- | Reporte ordenado por costo (quicksort). Ante empate de costo, desempata
--   por tiempo usando una tupla como clave ('Ord' de tuplas es lexicográfico).
ordenarPorCosto :: [Ruta] -> [Ruta]
ordenarPorCosto = quicksortPor (\r -> (costoTotal r, tiempoTotal r))

-- | Reporte ordenado por tiempo total (mergesort), desempatando por costo.
ordenarPorTiempo :: [Ruta] -> [Ruta]
ordenarPorTiempo = mergesortPor (\r -> (tiempoTotal r, costoTotal r))

-- | Elemento de clave mínima mediante un plegado a la izquierda que conserva
--   el mejor candidato visto hasta el momento (acumulador).
minimoPor :: Ord k => (a -> k) -> [a] -> Maybe a
minimoPor _ [] = Nothing
minimoPor clave (x : xs) =
  Just (foldl (\mejor y -> if clave y < clave mejor then y else mejor) x xs)

-- | Ruta de costo económico mínimo.
rutaMasBarata :: [Ruta] -> Maybe Ruta
rutaMasBarata = minimoPor (\r -> (costoTotal r, tiempoTotal r))

-- | Ruta de menor tiempo total de viaje.
rutaMasRapida :: [Ruta] -> Maybe Ruta
rutaMasRapida = minimoPor (\r -> (tiempoTotal r, costoTotal r))
