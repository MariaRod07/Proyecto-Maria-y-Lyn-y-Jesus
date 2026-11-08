module Tiempo
  ( horaAMinutos
  , minutosAHora
  , formatoDuracion
  ) where

import Data.Char (isDigit)

import Tipos (Minutos)

-- Convierte "HH:MM" a minutos desde las 00:00
horaAMinutos :: String -> Maybe Minutos
horaAMinutos cadena =
  case break (== ':') cadena of
    (hh, ':' : mm)
      | esNumero hh, esNumero mm
      , h <- read hh, m <- read mm
      , h >= 0, h < 24, m >= 0, m < 60
      -> Just (h * 60 + m)
    _ -> Nothing
  where
    esNumero s = not (null s) && all isDigit s

-- Convierte de minutos al formato "HH:MM"
minutosAHora :: Minutos -> String
minutosAHora t = dosDigitos (t `div` 60) ++ ":" ++ dosDigitos (t `mod` 60)

-- Formato para mostrar la duracion del viaje
formatoDuracion :: Minutos -> String
formatoDuracion t =
  show t ++ " min (" ++ show (t `div` 60) ++ "h " ++ dosDigitos (t `mod` 60) ++ "min)"

dosDigitos :: Int -> String
dosDigitos n
  | n < 10    = '0' : show n
  | otherwise = show n
