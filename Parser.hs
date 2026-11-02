{-|
Module      : Parser
Description : Parseo puro del archivo @vuelos.txt@ (Módulo 1).

Este módulo no realiza I/O: recibe el contenido del archivo como un 'String'
y produce valores de tipo 'Vuelo'. La lectura impura del disco queda aislada
en "Main". Separar ambas capas permite probar el parseo con cadenas literales
en GHCi sin tocar el sistema de archivos.

Formato de cada línea (campos separados por @|@):

> Origen|Destino|HH:MM|HH:MM|Costo|Vuelo|Frecuencia
-}
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

-- | Divide una cadena por un separador (equivalente a @splitOn@ de paquetes
--   externos, implementado sobre listas con 'break' y recursión).
--
-- >>> dividir '|' "a|b||c"
-- ["a","b","","c"]
dividir :: Char -> String -> [String]
dividir sep cadena =
  case break (== sep) cadena of
    (campo, [])         -> [campo]
    (campo, _ : resto)  -> campo : dividir sep resto

-- | Elimina espacios en blanco (incluido @\\r@ de archivos Windows) en ambos
--   extremos. Composición de funciones: la misma operación aplicada dos veces
--   sobre la cadena invertida recorta ambos lados.
recortar :: String -> String
recortar = quitarInicio . reverse . quitarInicio . reverse
  where quitarInicio = dropWhile isSpace

-- | Lee un entero no negativo escrito solo con dígitos.
leerEntero :: String -> Maybe Int
leerEntero s
  | not (null s), all isDigit s = Just (read s)
  | otherwise                   = Nothing

-- | @"Diario"@ -> todos los días; @"L-M-Mi-J-V"@ -> lista de días.
--   'mapM' sobre 'Maybe' falla (Nothing) si cualquier token es desconocido.
parsearFrecuencia :: String -> Maybe [Dia]
parsearFrecuencia "Diario" = Just todosLosDias
parsearFrecuencia texto    = mapM (`lookup` abreviaturas) (dividir '-' texto)

-- | Parsea una línea completa. 'Either' permite devolver un mensaje de error
--   descriptivo en lugar de abortar el programa.
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

-- | Parsea el contenido íntegro del archivo. Devuelve por separado los
--   errores (líneas rechazadas) y los vuelos válidos. Las líneas en blanco se
--   ignoran mediante el filtro de la list comprehension.
parsearVuelos :: String -> ([String], [Vuelo])
parsearVuelos contenido =
  partitionEithers [ parsearLinea l | l <- lines contenido, not (all isSpace l) ]
