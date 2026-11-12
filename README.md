# Desempleo juvenil, tejido empresarial y Formación Profesional en los municipios de Andalucía

Análisis estadístico con **R** de las diferencias municipales en el desempleo juvenil registrado en Andalucía (757 municipios, 2025). Integra cinco fuentes oficiales en una base de datos de elaboración propia y aplica **regresión lineal múltiple** con diagnóstico completo del modelo e inferencia robusta.

> **Autor:** Álvaro Espinosa López

---

## Preguntas de investigación

1. ¿En qué medida las características demográficas, empresariales y la oferta local de Formación Profesional (FP) están asociadas con las diferencias municipales en el desempleo juvenil registrado?
2. ¿Qué municipios presentan valores considerablemente superiores o inferiores a los estimados a partir de sus características?

## Resultados principales

- **El tamaño municipal es la variable más relevante** y su relación con el indicador es **no lineal, en forma de U**: el desempleo juvenil estimado disminuye al aumentar la población hasta un mínimo próximo a los 20.000 habitantes y aumenta a partir de ahí (mínimo matemático, no un "tamaño óptimo").
- **La oferta local de FP** presenta una asociación **positiva** (≈ +1,98 pp; IC 95 % robusto [1,39; 2,56]) una vez controladas las demás variables, en contraste con la comparación descriptiva inicial (donde los municipios con FP tenían menor desempleo). Esto ilustra la importancia de controlar por tamaño municipal. **No es un efecto causal.**
- **La densidad empresarial** muestra un coeficiente negativo, pero no significativo al 5 % en el modelo final (sí lo es al excluir observaciones influyentes).
- **Diferencias provinciales** ajustadas: Cádiz, Granada y Sevilla por encima de Almería; Jaén por debajo.
- El modelo final (M2) alcanza un **R² ajustado ≈ 0,40**. Una parte importante de la variabilidad municipal queda sin explicar.
- Se identifican los municipios con mayores desviaciones respecto al modelo (p. ej. Gobernador, Senés y Benizalón por arriba; Almócita, Villarrodrigo y Salares por abajo), la mayoría de ellos municipios muy pequeños donde el indicador es muy volátil.

## Metodología

| Etapa | Contenido |
|:---|:---|
| **Construcción de datos** | Integración de 5 fuentes por código municipal, limpieza y creación de indicadores (785 municipios iniciales → 757 tras excluir los incompletos). |
| **Análisis exploratorio** | Estadísticos descriptivos, histogramas, correlaciones de Pearson, comparación por presencia de FP y por provincia. |
| **Modelización** | Regresión lineal múltiple por MCO; especificación inicial lineal frente a especificación con término cuadrático de log(población). |
| **Diagnóstico** | VIF/GVIF (multicolinealidad), residuos vs. ajustados, Q-Q plot, residuos parciales (`crPlots`), contraste de Breusch-Pagan. |
| **Inferencia robusta** | Errores estándar robustos **HC3** ante heterocedasticidad. |
| **Observaciones influyentes** | Residuos studentizados, apalancamiento y distancia de Cook, con análisis de sensibilidad. |
| **Selección de modelo** | Comparación por R² ajustado, AIC y BIC, y eliminación hacia atrás (`step()`). |

**Variable respuesta:** promedio mensual de menores de 25 años en paro registrado durante 2025 por cada 100 residentes de 16 a 24 años. *No equivale a la tasa oficial de paro juvenil* (cuyo denominador es la población activa).

**Variables explicativas:** log(población total), empresas por 1.000 habitantes, log(renta neta media por persona), presencia de FP local (grado medio o superior) y provincia.

## Fuentes de datos

| Fuente | Contenido | Periodo |
|:---|:---|:---|
| INE | Población municipal total y de 16 a 24 años | 2025 |
| SEPE | Paro registrado de menores de 25 años (mensual) | 2025 |
| INE (DIRCE) | Empresas por municipio | 2025 |
| INE (Atlas de Distribución de Renta de los Hogares) | Renta neta media por persona | 2023 |
| Junta de Andalucía | Oferta municipal de FP de grado medio y superior | Curso 2024-2025 |

## Estructura del repositorio

```
.
├── ANALISIS_DESEMPLEO_JUVENIL_ANDALUCIA_2025.Rmd   # Informe reproducible (R Markdown → PDF)
├── construir_dataset.R                              # Script de integración y limpieza de datos
├── dataset_final.csv                                # Base analítica final (757 municipios × 20 variables)
├── Datos crudos/                                    # Datos de origen (ver nota más abajo)
└── README.md
```

## Cómo reproducirlo

### Requisitos

- R (≥ 4.1, por el uso de `|>`) y una distribución LaTeX para generar el PDF (por ejemplo, TinyTeX).
- Paquetes de R:

```r
install.packages(c(
  "tidyverse", "readxl", "knitr", "rmarkdown",
  "car", "lmtest", "sandwich"
))
```

### Pasos

1. **(Opcional) Reconstruir el dataset.** Coloca la carpeta `Datos crudos/` en el directorio de trabajo y ejecuta:

   ```r
   source("construir_dataset.R")
   ```

   Esto genera `dataset_final.csv`. El script incluye comprobaciones (`stopifnot`) sobre el número de municipios y de unidades de FP, además de un diagnóstico de los municipios excluidos.

2. **Generar el informe.** Con `dataset_final.csv` en el mismo directorio que el `.Rmd`:

   ```r
   rmarkdown::render("ANALISIS_DESEMPLEO_JUVENIL_ANDALUCIA_2025.Rmd")
   ```

   Como `dataset_final.csv` ya está incluido, se puede ejecutar el paso 2 directamente sin los datos crudos.

### Datos crudos esperados en `Datos crudos/`

- `poblacion_2025.csv`
- `sepe_2025_anual.csv`
- `dirce_2025.csv`
- `unidades_centros.csv`
- `*_renta.csv` (una por provincia, excepto Sevilla) y `sevilla_renta.xlsx`

## Limitaciones

- Estudio **observacional y transversal**: los resultados son asociaciones estadísticas, **no efectos causales**.
- El indicador utilizado es de paro *registrado* sobre población de 16 a 24 años, distinto de la tasa oficial de paro juvenil.
- Los valores censurados del SEPE (`<5`) se aproximan por 2,5 y no todos los municipios tienen los doce meses válidos, lo que añade incertidumbre en los municipios pequeños.
- `tiene_FP` solo indica la existencia de oferta local de FP: no mide plazas, matrícula ni acceso a centros de otros municipios.
- Las fuentes tienen periodos de referencia distintos (renta de 2023 frente al resto de 2025).
- Posible dependencia espacial entre municipios no modelada; posibles variables omitidas.
- Algunas estimaciones (FP, densidad empresarial) son sensibles a las observaciones influyentes.

## Posibles mejoras

- Incorporar la estructura sectorial de cada municipio.
- Analizar la autocorrelación espacial (modelos espaciales).
- Ampliar el análisis a varios años (datos de panel).

## Tecnologías

`R` · `R Markdown` · `tidyverse` · `ggplot2` · `car` · `lmtest` · `sandwich` · `LaTeX`

## Referencias

- Faraway, J. J. (2004). *Linear Models with R*. Chapman & Hall/CRC.
- García-Portugués, E. (2025). *Notes for Predictive Modeling*.
- Zeileis, A. (2004). Econometric Computing with HC and HAC Covariance Matrix Estimators. *Journal of Statistical Software*, 11(10), 1-17.
- Fuentes de datos: INE, SEPE y Junta de Andalucía (detalle en el informe).

## Contacto

**Álvaro Espinosa López**
alvaresp11@gmail.com
