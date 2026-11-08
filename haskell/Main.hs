{-|
Module      : Main
Description : Menú interactivo en consola (CLI) del motor LogiExpress.

Este es el único módulo con I/O impuro: lectura del archivo, entrada del
usuario y escritura en consola. Toda la lógica (parseo, grafo, búsqueda,
optimización) vive en módulos puros que se invocan desde aquí.

El estado de la sesión ('Estado') es un valor inmutable que se pasa como
argumento al bucle del menú; cada operación que "cambia" algo (cargar un
archivo, configurar el TMC) devuelve un 'Estado' nuevo.

Ejecución:

> ghc -O1 -o logiexpress Main.hs && ./logiexpress
> runghc Main.hs
> ghci Main.hs   -- luego  ghci> main
-}
module Main (main) where

import Control.Monad (filterM, forM_, unless)
import Data.Char (toLower)
import Data.List (intercalate)
import System.Directory (doesFileExist)
import System.IO
import System.Info (os)

import Consultas
import Grafo
import Optimizacion
import Parser (leerEntero, parsearVuelos, recortar)
import Rutas
import Tiempo
import Tipos

-- ---------------------------------------------------------------------------
-- Estado de la sesión
-- ---------------------------------------------------------------------------

data Estado = Estado
  { estTMC     :: Minutos   -- ^ Tiempo Mínimo de Conexión configurado
  , estVuelos  :: [Vuelo]   -- ^ vuelos cargados (en el orden del archivo)
  , estGrafo   :: Grafo     -- ^ lista de adyacencia derivada de estVuelos
  , estArchivo :: FilePath  -- ^ archivo cargado ("" si no hay ninguno)
  }

tmcPorDefecto :: Minutos
tmcPorDefecto = 45

-- | Ubicaciones donde se busca el archivo al iniciar: la carpeta actual y la
--   raíz del repositorio (cuando se ejecuta desde @/haskell@).
archivosCandidatos :: [FilePath]
archivosCandidatos = ["vuelos.txt", "../vuelos.txt"]

-- ---------------------------------------------------------------------------
-- Punto de entrada y bucle principal
-- ---------------------------------------------------------------------------

main :: IO ()
main = do
  configurarConsola
  putStrLn "LogiExpress - Motor analítico de rutas aéreas (paradigma funcional)"
  estado <- cargarInicial (Estado tmcPorDefecto [] [] "")
  bucle estado

configurarConsola :: IO ()
configurarConsola = do
  hSetBuffering stdout NoBuffering
  -- En Windows la consola usa su propia página de códigos y GHC la respeta;
  -- en Linux/macOS forzamos UTF-8 para que los acentos se impriman bien
  -- aunque la variable LANG no esté definida.
  unless (os == "mingw32") $ do
    hSetEncoding stdout utf8
    hSetEncoding stdin utf8

bucle :: Estado -> IO ()
bucle estado = do
  mostrarMenu estado
  opcion <- leerLinea "0" "Seleccione una opción: "
  case opcion of
    "1" -> cargarArchivo estado   >>= bucle
    "2" -> configurarTMC estado   >>= bucle
    "3" -> consultarSalidas estado >> bucle estado
    "4" -> consultarLlegadas estado >> bucle estado
    "5" -> consultarPorDia estado >> bucle estado
    "6" -> buscarRutas estado     >> bucle estado
    "7" -> optimizar estado       >> bucle estado
    "8" -> reporteOrdenado estado >> bucle estado
    "9" -> listarCiudades estado  >> bucle estado
    "0" -> putStrLn "Hasta luego."
    ""  -> bucle estado
    _   -> putStrLn ("Opción inválida: " ++ opcion) >> bucle estado

mostrarMenu :: Estado -> IO ()
mostrarMenu estado = putStr $ unlines
  [ ""
  , "================= LogiExpress (Haskell) ================="
  , "Archivo: " ++ nombreArchivo ++ " | Vuelos: " ++ show (length (estVuelos estado))
      ++ " | TMC: " ++ show (estTMC estado) ++ " min"
  , "---------------------------------------------------------"
  , "1. Cargar archivo de vuelos"
  , "2. Configurar TMC (tiempo mínimo de conexión)"
  , "3. Vuelos que salen de una ciudad"
  , "4. Vuelos que llegan a una ciudad"
  , "5. Vuelos que operan un día de la semana"
  , "6. Buscar rutas válidas (origen, destino, día, K opcional)"
  , "7. Ruta de costo mínimo y ruta de menor tiempo"
  , "8. Reporte de rutas ordenadas por costo o por tiempo"
  , "9. Listar ciudades"
  , "0. Salir"
  ]
  where
    nombreArchivo = if null (estArchivo estado) then "(ninguno)" else estArchivo estado

-- ---------------------------------------------------------------------------
-- Entrada de datos
-- ---------------------------------------------------------------------------

-- | Imprime el prompt y lee una línea recortada. Si la entrada se acabó
--   (EOF, por ejemplo al redirigir un archivo) devuelve el valor por defecto.
leerLinea :: String -> String -> IO String
leerLinea porDefecto prompt = do
  putStr prompt
  hFlush stdout
  fin <- isEOF
  if fin then putStrLn "" >> return porDefecto else fmap recortar getLine

pedir :: String -> IO String
pedir = leerLinea ""

-- | Interpreta el día escrito por el usuario: nombre completo (con o sin
--   acento, cualquier capitalización) o abreviatura del archivo (L, M, Mi...).
leerDia :: String -> Maybe Dia
leerDia texto = lookup (normalizar texto) tabla
  where
    tabla = [ (map toLower (show d), d) | d <- todosLosDias ]
         ++ [ (map toLower ab, d) | (ab, d) <- abreviaturas ]
    normalizar = map (sinAcento . toLower) . concat . words
    sinAcento c = case c of
      'á' -> 'a'; 'é' -> 'e'; 'í' -> 'i'; 'ó' -> 'o'; 'ú' -> 'u'; _ -> c

-- | Límite de escalas: vacío = sin límite; entero no negativo = K.
leerLimite :: String -> Either String (Maybe Int)
leerLimite ""    = Right Nothing
leerLimite texto = maybe (Left ("valor inválido para K: " ++ texto)) (Right . Just) (leerEntero texto)

-- | Pide una ciudad; devuelve 'Nothing' (tras informar) si no existe.
pedirCiudad :: Estado -> String -> IO (Maybe Ciudad)
pedirCiudad estado prompt = do
  texto <- pedir prompt
  case buscarCiudad (estGrafo estado) texto of
    Just c  -> return (Just c)
    Nothing -> rechazar ("ciudad desconocida: '" ++ texto ++ "' (la opción 9 lista las ciudades)")

pedirDia :: IO (Maybe Dia)
pedirDia = do
  texto <- pedir "Día de la semana (Lunes..Domingo o L,M,Mi,J,V,S,D): "
  maybe (rechazar ("día inválido: " ++ texto)) (return . Just) (leerDia texto)

pedirLimite :: IO (Maybe (Maybe Int))
pedirLimite = do
  texto <- pedir "Máximo de escalas K (Enter = sin límite): "
  either rechazar (return . Just) (leerLimite texto)

rechazar :: String -> IO (Maybe a)
rechazar motivo = putStrLn ("Operación cancelada: " ++ motivo) >> return Nothing

-- | Encadena dos pasos de entrada: si el primero falla ('Nothing') el segundo
--   no se ejecuta. Es la composición monádica de @IO (Maybe a)@ escrita a
--   mano (equivale a @>>=@ de @MaybeT IO@).
luego :: IO (Maybe a) -> (a -> IO (Maybe b)) -> IO (Maybe b)
luego accion continuacion = accion >>= maybe (return Nothing) continuacion

-- | Pide una ciudad y ejecuta la acción solo si existe en el grafo.
conCiudad :: Estado -> String -> (Ciudad -> IO ()) -> IO ()
conCiudad estado prompt accion = pedirCiudad estado prompt >>= mapM_ accion

-- | Parámetros comunes a las búsquedas de rutas: origen, destino, día y K.
--   Se cancela en el primer dato inválido.
pedirBusqueda :: Estado -> IO (Maybe (Ciudad, Ciudad, Dia, Maybe Int))
pedirBusqueda estado =
  pedirCiudad estado "Ciudad origen: "  `luego` \o ->
  pedirCiudad estado "Ciudad destino: " `luego` \d ->
  if o == d then rechazar "origen y destino deben ser distintos" else
  pedirDia                              `luego` \dia ->
  pedirLimite                           `luego` \k ->
  return (Just (o, d, dia, k))

-- ---------------------------------------------------------------------------
-- Opción 1 y 2: carga del archivo y configuración del TMC
-- ---------------------------------------------------------------------------

cargarInicial :: Estado -> IO Estado
cargarInicial estado = do
  existentes <- filterM doesFileExist archivosCandidatos
  case existentes of
    (ruta : _) -> cargarDesde ruta estado
    []         -> do
      putStrLn "No se encontró vuelos.txt; use la opción 1 para cargarlo."
      return estado

cargarArchivo :: Estado -> IO Estado
cargarArchivo estado = do
  texto <- pedir "Ruta del archivo [vuelos.txt]: "
  cargarDesde (if null texto then "vuelos.txt" else texto) estado

-- | Lectura impura del archivo seguida del parseo puro. El resultado del
--   parseo se evalúa antes de devolver el estado para que los errores se
--   reporten en este punto y no durante una consulta posterior.
cargarDesde :: FilePath -> Estado -> IO Estado
cargarDesde ruta estado = do
  existe <- doesFileExist ruta
  if not existe
    then putStrLn ("No existe el archivo: " ++ ruta) >> return estado
    else do
      contenido <- leerArchivoUtf8 ruta
      let (errores, vs) = parsearVuelos contenido
      mapM_ (putStrLn . ("  Advertencia, línea ignorada: " ++)) errores
      putStrLn ("Cargados " ++ show (length vs) ++ " vuelos desde " ++ ruta)
      return estado { estVuelos = vs, estGrafo = construirGrafo vs, estArchivo = ruta }

-- | 'hGetContents' es perezoso: devuelve la cadena antes de leer el archivo.
--   Forzar @length contenido@ con 'seq' obliga a leerlo completo antes de
--   cerrar el handle; sin esto, 'hClose' cerraría un archivo aún no leído.
leerArchivoUtf8 :: FilePath -> IO String
leerArchivoUtf8 ruta = do
  h <- openFile ruta ReadMode
  hSetEncoding h utf8
  contenido <- hGetContents h
  length contenido `seq` hClose h
  return contenido

configurarTMC :: Estado -> IO Estado
configurarTMC estado = do
  texto <- pedir ("Nuevo TMC en minutos [" ++ show (estTMC estado) ++ "]: ")
  case leerEntero texto of
    Just n  -> putStrLn ("TMC configurado en " ++ show n ++ " min") >> return estado { estTMC = n }
    Nothing -> putStrLn "Valor inválido; se mantiene el TMC actual." >> return estado

-- ---------------------------------------------------------------------------
-- Opciones 3, 4, 5 y 9: consultas básicas
-- ---------------------------------------------------------------------------

consultarSalidas :: Estado -> IO ()
consultarSalidas estado = conCiudad estado "Ciudad de salida: " $ \c ->
  listarVuelos ("Vuelos que salen de " ++ c) (salidasDesde (estGrafo estado) c)

consultarLlegadas :: Estado -> IO ()
consultarLlegadas estado = conCiudad estado "Ciudad de llegada: " $ \c ->
  listarVuelos ("Vuelos que llegan a " ++ c) (llegadasA (estGrafo estado) c)

consultarPorDia :: Estado -> IO ()
consultarPorDia estado = do
  texto <- pedir "Día de la semana: "
  case leerDia texto of
    Just dia -> listarVuelos ("Vuelos que operan el día " ++ show dia) (vuelosDelDia dia (estVuelos estado))
    Nothing  -> putStrLn ("Día inválido: " ++ texto)

listarCiudades :: Estado -> IO ()
listarCiudades estado = do
  let cs = ciudades (estGrafo estado)
  putStrLn ("Ciudades (" ++ show (length cs) ++ "): " ++ intercalate ", " cs)

listarVuelos :: String -> [Vuelo] -> IO ()
listarVuelos titulo [] = putStrLn (titulo ++ ": ninguno.")
listarVuelos titulo vs = do
  putStrLn (titulo ++ " (" ++ show (length vs) ++ "):")
  mapM_ (putStrLn . ("  " ++) . mostrarVuelo) vs

-- ---------------------------------------------------------------------------
-- Opciones 6, 7 y 8: búsqueda de rutas y optimización
-- ---------------------------------------------------------------------------

buscarRutas :: Estado -> IO ()
buscarRutas estado = do
  parametros <- pedirBusqueda estado
  forM_ parametros $ \(o, d, dia, k) -> do
    let rutas = rutasValidas (estTMC estado) k dia (estGrafo estado) o d
    putStrLn (encabezadoBusqueda o d dia k (estTMC estado) ++ show (length rutas) ++ " ruta(s) válida(s)")
    mapM_ putStr (zipWith mostrarRuta [1 ..] rutas)

optimizar :: Estado -> IO ()
optimizar estado = do
  parametros <- pedirBusqueda estado
  forM_ parametros $ \(o, d, dia, k) -> do
    let rutas = rutasValidas (estTMC estado) k dia (estGrafo estado) o d
    putStrLn (encabezadoBusqueda o d dia k (estTMC estado) ++ show (length rutas) ++ " ruta(s) evaluada(s)")
    if null rutas
      then putStrLn "No existen rutas válidas."
      else do
        putStrLn "-- Ruta de costo económico mínimo --"
        forM_ (rutaMasBarata rutas) (putStr . mostrarRuta 1)
        putStrLn "-- Ruta de menor tiempo total de viaje --"
        forM_ (rutaMasRapida rutas) (putStr . mostrarRuta 1)

reporteOrdenado :: Estado -> IO ()
reporteOrdenado estado = do
  parametros <- pedirBusqueda estado
  forM_ parametros $ \(o, d, dia, k) -> do
    criterio <- pedir "Ordenar por (c)osto o (t)iempo [c]: "
    let rutas = rutasValidas (estTMC estado) k dia (estGrafo estado) o d
        (titulo, ordenadas) = case map toLower criterio of
          't' : _ -> ("tiempo total de viaje (mergesort)", ordenarPorTiempo rutas)
          _       -> ("costo (quicksort)", ordenarPorCosto rutas)
    putStrLn (encabezadoBusqueda o d dia k (estTMC estado) ++ "reporte ordenado por " ++ titulo)
    if null ordenadas
      then putStrLn "No existen rutas válidas."
      else mapM_ putStr (zipWith mostrarRuta [1 ..] ordenadas)

encabezadoBusqueda :: Ciudad -> Ciudad -> Dia -> Maybe Int -> Minutos -> String
encabezadoBusqueda o d dia k tmc =
  o ++ " -> " ++ d ++ " | " ++ show dia ++ " | TMC " ++ show tmc ++ " min | K = "
    ++ maybe "sin límite" show k ++ " | "

-- ---------------------------------------------------------------------------
-- Presentación
-- ---------------------------------------------------------------------------

mostrarVuelo :: Vuelo -> String
mostrarVuelo v = intercalate "  "
  [ rellenar 7 (codigo v)
  , rellenar 27 (origen v ++ " -> " ++ destino v)
  , minutosAHora (salida v) ++ "-" ++ minutosAHora (llegada v)
  , rellenar 8 ("Bs " ++ show (costo v))
  , "[" ++ mostrarFrecuencia (frecuencia v) ++ "]"
  ]

mostrarFrecuencia :: [Dia] -> String
mostrarFrecuencia dias
  | dias == todosLosDias = "Diario"
  | otherwise            = intercalate "-" [ ab | d <- dias, (ab, d') <- abreviaturas, d == d' ]

mostrarRuta :: Int -> Ruta -> String
mostrarRuta n ruta = unlines $
  [ "Ruta " ++ show n ++ ": " ++ show (escalas ruta) ++ " escala(s) | Costo total Bs "
      ++ show (costoTotal ruta) ++ " | Tiempo total " ++ formatoDuracion (tiempoTotal ruta) ]
  ++ [ "    " ++ mostrarVuelo v | v <- ruta ]
  ++ [ "    Esperas en escalas: " ++ intercalate ", " (map formatoDuracion (esperas ruta))
     | not (null (esperas ruta)) ]

rellenar :: Int -> String -> String
rellenar ancho s = s ++ replicate (ancho - length s) ' '
