#Script de R que construye dataset_final.csv (una fila por municipio andaluz)

#Antes de ejecutar las librerías, poner en consola respectivamente
#si no las tenemos instaladas:
#install.packages("tidyverse")
#install.packages("readxl")
library(tidyverse)
library(readxl) #Para leer archivos Excel

#Ahor vamos a guardar en la variable raw la carpeta de dataset originales que e llama Datos crudos

raw <- "Datos crudos" #Importante tener en el mismo directorio la carpeta datos crudos que contenga todos los dataset

#Ahora creamos la funcion leer, para no tener que llamara  la carpeta cada vez
#que queramos leer un dataset.
#Con file.path(raw, f) lo que conseguimos .es contruir rutas de archivos uniendo el nombre de la carpeta que es la variable raw
#con el nombre del archivo ( la variable f).
#Con col_types = cols(cod_municipio = "c") obligamos a leer la columna cod_municipio como tecto ("c) en lugar de número.
#Ya que observamos que hay codigos que empiezan por 0 entonces R los eliminaría si los lee como un número integer
#Con show_col_types = FALSE simplemente silenciamo los errores que saltan al leer un csv

leer <- function(f) read_csv(file.path(raw, f), col_types = cols(cod_municipio = "c"),
                             show_col_types = FALSE)

#Poblacion (base: contiene los 785 municipios)
#Guardamos en la variable población el dataset de la población de cada minicipio de 2025
#además de que estamos renombrando las columnas/variables poblacion_total por pob_total y poblacion_joven por pob_16_24 (de 16 a 24 años)
#Lo cambio uno para hacerlo mas corto y otro para que no haya mabigüedad a la hroa de la definicion de poblacion joven, para que se sepa que es es rango de edad
#Una observación es que a lo largo del script voy a utilizar el metodo de la tubería |> para no tener que anda rponiendo funciones anidadad o llamar la variable varias veces
poblacion <- leer("poblacion_2025.csv") |>
  rename(pob_total = poblacion_total, pob_16_24 = poblacion_joven)

#Paro registrado de menores de 25 (media 2025 de meses validos)
#Aquí la misma lógica que antes leo y guardo en la variable paro el dataset del desempeo de jóvenes
#y además le cambio el nombre a la columna de paro_joven_medio por el de paro_menor25 para que no haya ambigüedades
#que contiene la media de paro registrada durante el año 2025 que se hace sumando la cifra de desempleados juveniles
#de todos los meses y dividiendola por el numero de mees validos que son los meses que se ha registrado paro o que hay información.
paro <- leer("sepe_2025_anual.csv") |>
  rename(paro_menor25 = paro_joven_medio)

#Empresas (DIRCE 2025)
#Aquí leemos y guardamos el dataset del DIRCE 2025 en la variable empresas y además
#hacemos una selección de columnas con la función select(), que nos quedamos con la columna del código municipal (para luego unir dataset)
#también con la columna de empresas total y con la de densidad_empresarial que además la renombro como empresas_1000hab
#para que se sepa que esa densidad se ha calculado por cada 1000 habitantes
empresas <- leer("dirce_2025.csv") |>
  select(cod_municipio, empresas_total, empresas_1000hab = densidad_empresarial)

#Renta neta media por persona 2023 (Atlas INE) Es de 2023 porque no hay datos más recientes
#Primero vamos con los archivos que son CSV, que son todas las provincias andaluzas menos Sevilla (que no dejaba descargarla en CSV y ha tocado en Excel)

#Lo que hacemso primero es que con list.files R busca dentro de la carpeta "Datos crudos" que hemos llamado raw
#y busca todos los archivos cuyo nombre termine por _renta.csv (es una forma mucho más cómoda que hacerlo 1 por 1)
#y así capturamos de golpe todoas las provincias excepto Sevilla
#Luego lo que hacemos con map_dfr es un bucle iterativo.Coge lso 7 archivos, los lee cada uno usando el ;, interpreta los caracteres especiales con 
#codificación "UTF-8", obliga a que todas las columnas se lean como texto con el .default = "c" y luego apila los 7 dataset en una tabla final gigante
#La virguilla es para indicarle de forma rápida que aquí empieza una función rápida ( me ahorra tener que escribir function(x) {})
#El .x representa entonces el archivo que toca leer en ese turno exacto. El map_dflr es como si se tratase de un bucle for
#Con la función filter lo qu evamos a ahcer es: primero con el is.na(Distritos) y is.na(Secciones) es quiatr esas filas dodne el distrito o la seccion no es vacía (porque ya tenemos la información del municipio que nos interesa)
#con el is.na() que devuelve True si es vacía y False si no, con el filter nos quedamos con la que es vacío (porque las filas con esas dos columnas vacías on las que son el municipio en general que es el que nos interesa)
#Segundo nos quedamos con las filas en las que la columna Indicadores de renta media y mediana nos da la renta media por persona y en el año 2023 que es la que nos interesa 
#(porque también viene de otros años y de renta media por hogar...)
#Por último la funcion transmute() es una función que hace lo mismo que mutate() que crea o modficia columnas y que
#la función select() que se queda solo con las columnas nombradas y el resto las desecha. Entonces lo que hace es lo siguiente:
#la columna Municipios de este dataset se mezcla el código del municipio y el nombre del municipio, entonces
#con la función str_sub() le indicamos que de ese string coja del caracter 1 al 5 y así nos quedamos con el código INE del municipio y lo renombramos como cod_municipio.
#por último de la columna Total hay que elimina rprimero el punto que se utiliza en los miles (porque R lo interpreta como un decimal) 
#y eso lo hacemos con str_remove_all() con el \\. que con eso le indicamos que le queremos quitar el punto y con as.numeric() lo convertimos a número real y lo renombrmos como renta.

csv_renta <- list.files(raw, pattern = "_renta\\.csv$", full.names = TRUE) |>
  map_dfr(~ read_delim(.x, delim = ";", col_types = cols(.default = "c"),
                       locale = locale(encoding = "UTF-8"), show_col_types = FALSE)) |>
  filter(is.na(Distritos), is.na(Secciones),
         `Indicadores de renta media y mediana` == "Renta neta media por persona",
         Periodo == "2023") |>
  transmute(cod_municipio = str_sub(Municipios, 1, 5),
            renta = as.numeric(str_remove_all(Total, "\\.")))

#Ahora vamos con el dataset de la provincia de Sevilla. Lo leemos y lo guardamos en una variable llaamda xl_renta para diferenciar de las otras 7 provincias que vienen en CSV
#Primero utilizamos el file.path() para unir el directorio raw que es la carpeta dodne está el dataset con el archivo.
#luego usamos col_names = FALSE para indicar a R que el archivo no trae nombres válidos, ya que las primeras filas del dataset son titulos estéticos.
#R nombra estas columnas por defecto con números.Con range = cell_cols(1:2) le decimos que lea solo la columna 1 (donde estan los municipios) y la 2 (donde está la renta de 2023)
#Con col_types = "text" obligamos a que todo se interprete como caracteres, al igual que hicimos con el dataset de poblacion, para que no borre los ceros del principio del codigo municipal
#Después con set_names(c("a", "b")) renombramos las dos unicas columnas que nos hemso qudado con "a" y "b"
#Con str_detect(a, "^\\d{5} ") revisamos cada celda de la columna a y devuelve True si encuentra el siguiente patrón:
#con ^ le decimos que busque esto al principio del texto, con \\d le decimos: cualquier digito del 0 al 9 y con {5} le indicamos que 5 veces seguidas y el espacio en blanco es para exigir que exista justo despúes de los 5 dígitos
#con el filter() nos quedamos con la que devuelve true porque se debe a una fila de municipio ya que hay muchas filas basura que contiene otras cosas o filas de dsitrito o de sección censal
#Luego el transmute() sigue la misma lógica que antes, con convertir la columna b que es la de la renta en 2023 a número pues lo habíamos convertido en string antes.
#nos ahorramos el \\. de antes porque aquí el INe si metió las cifras sin el punto de los miles.

xl_renta <- read_excel(file.path(raw, "sevilla_renta.xlsx"), col_names = FALSE,
                       range = cell_cols(1:2), col_types = "text") |>
  set_names(c("a", "b")) |>
  filter(str_detect(a, "^\\d{5} ")) |>
  transmute(cod_municipio = str_sub(a, 1, 5), renta = as.numeric(b))

#Ahora pegamos las dos tablas una encima de otra con la funcion bind_rows() que añade las filas de xl_renta que son las de Sevilla
#y las pone justo debajo de las filas de las otras 7 provincias que están en csv_renta y guardamos este dataset en la variable renta

renta <- bind_rows(csv_renta, xl_renta)

#FP (Junta de Andalucia, unidades por centro, curso 2024-25)

#Con read_delim() lo que hacemos es cargar el dataset de unidades_centros donde está la información del número de aulas de FP que hay
#Con locale = locale(decimal_mark = ",", encoding = "UTF-8") especificamos que la marca decimal es una coma ya que si no nos daría problemas porque en R el decimal se pone con punto
#y también con UTF-8 aseguramos que las tildes y ñ de los pueblos se leen sin problema. Luego también indicamos que el codigo se lea como texto ("c") para evitar que se elimine el 0

u <- read_delim(file.path(raw, "unidades_centros.csv"), delim = ";",
                locale = locale(decimal_mark = ",", encoding = "UTF-8"),
                col_types = cols(codigo = "c", cod_municipio = "c"),
                show_col_types = FALSE)

#Aquí en estas variables guardamos las columnas que forman parte de cada FP en vectores, si es grado medio o superior (la FP básica no la contamos como FP en el estudio)

gm <- c("pub_fpgm_ord", "priv_c_fpgm_ord", "priv_noc_fpgm_ord", "pub_fpgm_adul")
gs <- c("pub_fpgs_ord", "priv_c_fpgs_ord", "priv_noc_fpgs_ord", "pub_fpgs_adul")

#Ahora creamos el dataset final con ayuda de lafuncion mutate(). COn across(all_of()) le decimos a R que seleccione soo las columnas de la lista gm o gs respectivamente.
#luego con rowSums()sumo las filas horizontalmente fila por fila y el resultado se guarda en una nueva columna/variable
#despues sumamos los de grado superior y grado medio para tener el calculo total de aulas FP por instituto
#Luego con el filter() nos quedamso solo con aquellos centros que tienen algún aula de FP.
#Con group_by() agrupamos por municipio a través del código todos los centros en un mismo municipio porque el estudio va por municipios
#Finalmente con summarise() creamos una única fila para cada municipio después de agruparlas. En centros_fp guardamos el número de centros FP que tiene el municipio
#luego también creamos otras columnas para el numero de aulas de grado medio, superior y ambas hay en el municipio y con .groups = "drop" simplemente nos aseguramos de que devuelva una tabla plana y normal

fp_muni <- u |>
  mutate(unid_gm = rowSums(across(all_of(gm))),
         unid_gs = rowSums(across(all_of(gs))),
         unid_fp = unid_gm + unid_gs) |>
  filter(unid_fp > 0) |>
  group_by(cod_municipio) |>
  summarise(centros_fp = n(), unid_gm = sum(unid_gm),
            unid_gs = sum(unid_gs), unid_fp = sum(unid_fp), .groups = "drop")

#Union
#Aquí ya sería el cúlmen del dataset final, donde vamos aunir todos los dataset en uno que llamamos dataset a través de la función left_join 
#y gracias al código municipal que hay en cada uno de los dataset anteriores que hemos creado, que es el que nos va a hacer de pegamento.
#Cogemos como base la base de datos de población, y con left_join vamos pegando las variables de los demás dataset
#Los municipios que no tengan centros FP los rellenará con UN NA en esas variables así que con mutate(across(...,~ replace_na(.x, 0))) le estamos diciendo a R
#que revise esas columnas y cambie el NA por un 0, pues con los NA no podreos hacer ni medias ni regresiones mas adelante en el estudio
#Además en el mutate también creo nuevas variables que nos sevirán para el estudio:tiene_FP metemos un codigo binario con 1 si el municipio tiene centros FP y 0 si no tiene con ayuda de pasar a entero el booleano
#En FP_1000, tasa_paro_joven, peso_joven realtivizamos los dtos, ya que no es lo mismo tener 10 aulas en un pueblo de 50000 habitantes que en una capital. Al dividir por la población joven creo indicadores comparables entre municipios de cualquier tamaño
#Como las poblaciones y las rentas suelen tener distribuciones muy asimétricas, en log_pob_total, log_renta calculamos el logaritmo para intentar suavizar eso
dataset <- poblacion |>
  left_join(paro,     by = "cod_municipio") |>
  left_join(empresas, by = "cod_municipio") |>
  left_join(fp_muni,  by = "cod_municipio") |>
  left_join(renta,    by = "cod_municipio") |>
  mutate(across(c(centros_fp, unid_gm, unid_gs, unid_fp), ~ replace_na(.x, 0)),
         tiene_FP        = as.integer(unid_fp > 0),
         FP_1000         = unid_fp / pob_16_24 * 1000,
         tasa_paro_joven = paro_menor25 / pob_16_24 * 100,
         peso_joven      = pob_16_24 / pob_total,
         log_pob_total   = log(pob_total),
         log_renta       = log(renta))

#Comprobaciones (opcional pero nos queda mas profesional)

#Aquí estamos indicando a R que pare el Script con stopifnot() y le paso una serie de coprobaciones que tiene que hacer
#para ver que nuestro dataset coincide con los datos reales de Andalucía y que no se ha duplicado ningún municipio
stopifnot(nrow(dataset) == 785, !anyDuplicated(dataset$cod_municipio))
stopifnot(sum(dataset$unid_fp) == 7747, sum(dataset$unid_gm) == 3592,
          sum(dataset$unid_gs) == 4155, sum(dataset$tiene_FP) == 241)
cat("Municipios:", nrow(dataset), "\n") #Aquí pintamos por consola el número de observaciones/mujicpios de nuestro dataset
print(colSums(is.na(dataset))) #Aquí comprobamos que no hay ningún valor NA en el dataset que nos pued afastidiar el estudio

#Observamos que no todos los valores están a 0, esoe s que quedan algunos datos en NA, debe de ser porque en algún dataset
#habrán municipios que serán muy pequeños y quedarán sin registrar. Entonces tenemso que eliminar esas filas que contengan algún NA para no fastidiar el estudio
#Lo haré con la función drop_na que mira fila por fila si tiene alguna variabke con NA y si es asií la elimina del dataset


# DIAGNÓSTICO DE LOS MUNICIPIOS EXCLUIDOS

# Identificamos los municipios que tienen algún valor ausente
excluidos <- dataset |>
  filter(if_any(everything(), is.na))

# Número de municipios que se eliminarán
cat("Municipios excluidos:", nrow(excluidos), "\n")

# Número de valores ausentes por variable
cat("\nValores ausentes por variable:\n")
print(colSums(is.na(dataset)))

# Comprobamos qué fuentes explican las exclusiones
resumen_exclusiones <- dataset |>
  summarise(
    Sin_SEPE = sum(is.na(paro_menor25)),
    Sin_DIRCE = sum(is.na(empresas_total)),
    Sin_renta = sum(is.na(renta)),
    Sin_SEPE_y_DIRCE = sum(
      is.na(paro_menor25) & is.na(empresas_total)
    )
  )

print(resumen_exclusiones)

# Mostramos los municipios afectados
excluidos |>
  select(
    cod_municipio,
    paro_menor25,
    empresas_total,
    renta
  ) |>
  print(n = Inf)


dataset <- dataset |> drop_na()
cat("Municipios finales listos para el modelo:", nrow(dataset), "\n")
print(colSums(is.na(dataset)))
#Ahora sí vemos que está todo listo y hemos pasado de 785 municipios a 757


#Por último proceemos a guardar nuestro dataset en nuestro directorio de trabajo

write_csv(dataset, "dataset_final.csv")