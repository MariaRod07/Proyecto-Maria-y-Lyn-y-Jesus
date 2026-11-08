{-|
Module      : Tiempo
Description : Procesamiento de tiempo (Módulo 1).

Conversión entre el formato militar @"HH:MM"@ del archivo y minutos enteros
desde el inicio del día. Toda la aritmética de ventanas de conexión (TMC) y
de tiempo total de viaje se hace sobre enteros, nunca sobre cadenas.
-}
module Tiempo
  ( horaAMinutos
  , minutosAHora
  , formatoDuracion
  ) where

import Data.Char (isDigit)

import Tipos (Minutos)

-- | Convierte @"HH:MM"@ (24 h) a minutos desde las 00:00.
--   Devuelve 'Nothing' si la cadena no tiene el formato esperado o la hora
--   está fuera de rango; así el parseo del archivo puede rechazar líneas
--   inválidas sin lanzar excepciones.
--
-- >>> horaAMinutos "07:30"
-- Just 450
-- >>> horaAMinutos "25:00"
-- Nothing
horaAMinutos :: String -> Maybe Minutos
horaAMinutos cadena =
  case break (== ':') cadena of
    (hh, ':' : mm)
      | esNumero hh, esNumero mm
      , h <- read hh, m <- read mm           -- pattern guards
      , h >= 0, h < 24, m >= 0, m < 60
      -> Just (h * 60 + m)
    _ -> Nothing
  where
    esNumero s = not (null s) && all isDigit s

-- | Operación inversa: minutos -> @"HH:MM"@ con relleno de ceros.
--
-- >>> minutosAHora 450
-- "07:30"
minutosAHora :: Minutos -> String
minutosAHora t = dosDigitos (t `div` 60) ++ ":" ++ dosDigitos (t `mod` 60)

-- | Duración legible: @180 -> "180 min (3h 00min)"@.
formatoDuracion :: Minutos -> String
formatoDuracion t =
  show t ++ " min (" ++ show (t `div` 60) ++ "h " ++ dosDigitos (t `mod` 60) ++ "min)"

dosDigitos :: Int -> String
dosDigitos n
  | n < 10    = '0' : show n
  | otherwise = show n
