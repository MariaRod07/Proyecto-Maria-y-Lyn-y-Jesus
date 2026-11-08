{-|
Module      : Rutas
Description : Motor de búsqueda de rutas válidas (Módulo 2).

Búsqueda en profundidad (DFS) recursiva sobre el grafo inmutable. La
exploración se expresa como una list comprehension: cada generador y cada
guarda corresponde a una de las restricciones del enunciado, y la recursión
@ruta <- dfs ...@ es la llamada en profundidad.

Gracias a la evaluación perezosa, la lista de rutas se produce bajo demanda:
@take 1 (rutasValidas ...)@ detiene la exploración en la primera ruta hallada
sin construir el resto del espacio de búsqueda.
-}
module Rutas
  ( rutasValidas
  , disponibleEn
  , conexionValida
  , escalas
  ) where

import Grafo (vuelosDesde)
import Tipos

-- | Restricción 1 (compatibilidad de frecuencia): el vuelo opera ese día.
disponibleEn :: Dia -> Vuelo -> Bool
disponibleEn dia v = dia `elem` frecuencia v

-- | Restricción 2 (validación de escala): el segundo vuelo sale como mínimo
--   TMC minutos después de la llegada del primero.
conexionValida :: Minutos -> Vuelo -> Vuelo -> Bool
conexionValida tmc anterior siguiente =
  salida siguiente >= llegada anterior + tmc

-- | Número de escalas de una ruta (vuelos - 1). Una ruta directa tiene 0.
escalas :: Ruta -> Int
escalas ruta = length ruta - 1

-- | Genera todas las rutas válidas entre dos ciudades para un día dado.
--
--   * @tmc@     : tiempo mínimo de conexión en minutos.
--   * @limite@  : máximo de escalas permitido (@Nothing@ = sin límite).
--
--   La función interna @dfs@ lleva como acumuladores la lista de ciudades
--   visitadas (restricción 3, control de ciclos), el último vuelo tomado
--   (para validar la escala) y los vuelos acumulados en orden inverso, que se
--   invierten con 'reverse' al alcanzar el destino.
rutasValidas
  :: Minutos     -- ^ TMC
  -> Maybe Int   -- ^ límite K de escalas
  -> Dia         -- ^ día de la semana consultado
  -> Grafo
  -> Ciudad      -- ^ origen
  -> Ciudad      -- ^ destino
  -> [Ruta]
rutasValidas tmc limite dia grafo desde hasta
  | desde == hasta = []                 -- un itinerario sin vuelos no es una ruta
  | otherwise      = dfs desde [desde] Nothing []
  where
    dfs :: Ciudad -> [Ciudad] -> Maybe Vuelo -> [Vuelo] -> [Ruta]
    dfs actual visitados anterior tomados
      | actual == hasta = [reverse tomados]          -- caso base: ruta completa
      | otherwise =
          [ ruta
          | v <- vuelosDesde grafo actual                -- aristas salientes
          , disponibleEn dia v                           -- (1) frecuencia
          , destino v `notElem` visitados                -- (3) sin ciclos
          , maybe True (\p -> conexionValida tmc p v) anterior  -- (2) escala >= TMC
          , dentroDelLimite (length tomados)             -- (4) límite K
          , ruta <- dfs (destino v) (destino v : visitados) (Just v) (v : tomados)
          ]

    -- Al tomar un vuelo más, la ruta pasa a tener @n@ escalas, donde @n@ es
    -- el número de vuelos ya acumulados; debe cumplirse @n <= K@.
    dentroDelLimite :: Int -> Bool
    dentroDelLimite n = maybe True (n <=) limite
