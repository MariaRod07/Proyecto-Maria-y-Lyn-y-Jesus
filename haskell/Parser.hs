module Parser
  ( dividir
  , recortar
  , leerEntero
  , parsearFrecuencia
  , parsearLinea
  , parsearVuelos
  ) where

import Data.Char (isDigit, isSpace)
import Data.Either (partitionEithers)

import Tiempo (horaAMinutos)
import Tipos

dividir :: Char -> String -> [String]
dividir sep cadena =
  case break (== sep) cadena of
    (campo, [])        -> [campo]
    (campo, _ : resto) -> campo : dividir sep resto

recortar :: String -> String
recortar = quitarInicio . reverse . quitarInicio . reverse
  where quitarInicio = dropWhile isSpace

leerEntero :: String -> Maybe Int
leerEntero s
  | not (null s), all isDigit s = Just (read s)
  | otherwise                   = Nothing

parsearFrecuencia :: String -> Maybe [Dia]
parsearFrecuencia "Diario" = Just todosLosDias
parsearFrecuencia texto    = mapM (`lookup` abreviaturas) (dividir '-' texto)

parsearLinea :: String -> Either String Vuelo
parsearLinea linea =
  case map recortar (dividir '|' linea) of
    [o, d, hs, hl, c, v, f] ->
      case (horaAMinutos hs, horaAMinutos hl, leerEntero c, parsearFrecuencia f) of
        (Just s, Just l, Just precio, Just dias) ->
          Right Vuelo
            { codigo = v, origen = o, destino = d
            , salida = s, llegada = l, costo = precio, frecuencia = dias }
        _ -> Left ("campos inválidos en: " ++ linea)
    campos -> Left ("se esperaban 7 campos y hay " ++ show (length campos) ++ ": " ++ linea)

parsearVuelos :: String -> ([String], [Vuelo])
parsearVuelos contenido =
  partitionEithers [ parsearLinea l | l <- lines contenido, not (all isSpace l) ]
