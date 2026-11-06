# Equipo 6: La suite TeraSort

En esta práctica ejecutamos tres programas de Hadoop: **TeraGen** genera datos, **TeraSort** los ordena y **TeraValidate** comprueba el resultado. Procesamos 100 000 filas (aproximadamente 10 MB).

## Integrantes

- Yatzury Yazmin Garciduenas Gonzalez
- Cesar Manuel Rangel Cardenas

## Descripción y caso de uso

TeraSort es una prueba de referencia para observar cuánto tarda un entorno Hadoop en generar, ordenar y validar datos. En un clúster real, se puede repetir la prueba para comparar configuraciones o revisar cambios de rendimiento. Esta ejecución pequeña es didáctica; no certifica el rendimiento general de una computadora.

## Requisitos

- Contenedor `hadoop` de la práctica, en funcionamiento.
- Hadoop 3.3.6 instalado dentro del contenedor.
- `HADOOP_HOME` configurado y disponible el JAR de ejemplos de Hadoop.
- Terminal abierta dentro del contenedor, donde funcionen `hadoop`, `date` y `awk`.

No se necesita clonar el repositorio para ejecutar la prueba. Se pegan los siguientes bloques **en orden y en la misma terminal del contenedor**. También se encuentran en [`ejercicio/ejercicio.md`](./ejercicio/ejercicio.md).

## Paso a paso

### Etapa 1: generar datos con TeraGen

Verificamos la versión, preparamos las carpetas temporales y generamos 100 000 filas. Si ya había resultados anteriores, el bloque elimina solo las carpetas de entrada, salida y reporte de esta prueba.

```bash
echo "Verificamos la versión de Hadoop:"
hadoop version
export JAR="$HADOOP_HOME/share/hadoop/mapreduce/hadoop-mapreduce-examples-3.3.6.jar"
export RESULTADOS=/tmp/terasort/resultados
mkdir -p "$RESULTADOS"

for ruta in /tmp/terasort/entrada /tmp/terasort/salida /tmp/terasort/reporte; do
    if hadoop fs -test -e "$ruta"; then
        hadoop fs -rm -r "$ruta"
    fi
done

printf '# Tiempos de TeraSort\n\nDatos generados: 100 000 filas\n\n| Prueba | Duración | Resultado |\n|---|---:|---|\n' > "$RESULTADOS/time.md"

INICIO=$(date +%s%N)
if hadoop jar "$JAR" teragen 100000 /tmp/terasort/entrada; then
    ESTADO="Correcto"
else
    ESTADO="Error"
fi
FIN=$(date +%s%N)
DURACION=$(awk -v ns="$((FIN - INICIO))" 'BEGIN { printf "%.3f s", ns / 1000000000 }')
printf '| TeraGen | %s | %s |\n' "$DURACION" "$ESTADO" | tee -a "$RESULTADOS/time.md"
```

Confirmamos que TeraGen indique `Correcto`. Si muestra `Error`, nos detenemos y revisamos el mensaje antes de continuar.

### Etapa 2: ordenar con TeraSort

Solo si TeraGen terminó correctamente, ejecutamos este bloque para ordenar los datos. Después verificamos que exista `_SUCCESS`.

```bash
INICIO=$(date +%s%N)
if hadoop jar "$JAR" terasort /tmp/terasort/entrada /tmp/terasort/salida; then
    ESTADO="Correcto"
else
    ESTADO="Error"
fi
FIN=$(date +%s%N)
DURACION=$(awk -v ns="$((FIN - INICIO))" 'BEGIN { printf "%.3f s", ns / 1000000000 }')
printf '| TeraSort | %s | %s |\n' "$DURACION" "$ESTADO" | tee -a "$RESULTADOS/time.md"

if [ "$ESTADO" = "Correcto" ]; then
    hadoop fs -ls /tmp/terasort/salida
fi
```

Confirmamos que aparezca `_SUCCESS` y que el estado diga `Correcto`. Si no, no avanzamos.

### Etapa 3: validar con TeraValidate

Solo si TeraSort terminó correctamente, validamos el orden y guardamos el reporte de Hadoop dentro del contenedor.

```bash
INICIO=$(date +%s%N)
if hadoop jar "$JAR" teravalidate /tmp/terasort/salida /tmp/terasort/reporte; then
    ESTADO="Correcto"
else
    ESTADO="Error"
fi
FIN=$(date +%s%N)
DURACION=$(awk -v ns="$((FIN - INICIO))" 'BEGIN { printf "%.3f s", ns / 1000000000 }')
printf '| TeraValidate | %s | %s |\n' "$DURACION" "$ESTADO" | tee -a "$RESULTADOS/time.md"

if [ "$ESTADO" = "Correcto" ]; then
    echo "Verificamos el reporte:"
    hadoop fs -cat /tmp/terasort/reporte/part-r-00000
    hadoop fs -get -f /tmp/terasort/reporte/part-r-00000 "$RESULTADOS/part-r-00000"
    hadoop fs -get -f /tmp/terasort/reporte/_SUCCESS "$RESULTADOS/_SUCCESS"
    echo "Confirmamos que se generaron los archivos:"
    ls -l "$RESULTADOS"
else
    echo "TeraValidate falló. Revisamos el mensaje y no consideramos válida la prueba."
fi
```

Un checksum en `part-r-00000` es una huella calculada por TeraValidate; no es una medición de tiempo.

### Mostrar tiempos y clasificación

Pegamos este bloque. Suma el tiempo de las tres etapas y lo compara con una escala orientativa:

- Hasta 4 segundos: **Tienes una PC master race** (tiempo muy corto).
- Más de 4 y hasta 10 segundos: **Tienes una PC buena** (tiempo normal).
- Más de 10 segundos: **Tienes una PC de rendimiento básico** (tiempo extenso).

```bash
awk -F'|' '
$2 ~ /TeraGen|TeraSort|TeraValidate/ {
    duracion = $3
    gsub(/[^0-9.]/, "", duracion)
    total += duracion
}
END {
    if (total <= 4) {
        clasificacion = "Tienes una PC master race (tiempo muy corto)"
    } else if (total <= 10) {
        clasificacion = "Tienes una PC buena (tiempo normal)"
    } else {
        clasificacion = "Tienes una PC de rendimiento básico (tiempo extenso)"
    }
    printf "\nTiempo total: %.3f s\nClasificación: %s\n", total, clasificacion
}' "$RESULTADOS/time.md" | tee -a "$RESULTADOS/time.md"
```

Finalmente mostramos el resultado:

```bash
cat /tmp/terasort/resultados/time.md
```

La escala es didáctica y solo sirve para comparar esta prueba con la misma cantidad de filas. El resultado también depende de Docker, Hadoop, el almacenamiento y la carga del equipo.

## Resultado esperado y entrega

Esperamos que las tres fases tengan estado `Correcto`, que TeraSort cree `_SUCCESS` y que TeraValidate genere `part-r-00000`. La tabla de `time.md` presenta la duración de cada fase, el total y la categoría.

El único entregable del mini ejercicio es una captura de pantalla de la terminal del contenedor mostrando la tabla completa de tiempos y la clasificación. No hace falta entregar `time.md` ni los archivos de salida por separado. Las instrucciones del ejercicio están en [`ejercicio/ejercicio.md`](./ejercicio/ejercicio.md).

## Errores comunes

Durante nuestra ejecución no registramos errores. Si alguna etapa muestra `Error`, no continuamos a la siguiente: revisamos el mensaje de Hadoop y volvemos a ejecutar desde la Etapa 1.
