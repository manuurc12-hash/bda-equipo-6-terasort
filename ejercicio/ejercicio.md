# Ejercicio

## Objetivo

Vamos a ejecutar una prueba simple de Hadoop. La idea es entender el flujo básico de trabajo:

1. generar datos,
2. ordenarlos,
3. verificar que quedaron bien ordenados.

Esto se hace con tres pasos principales:

- `TeraGen`: genera datos de prueba.
- `TeraSort`: ordena esos datos.
- `TeraValidate`: verifica que el orden sea correcto.

## Qué vamos a hacer?

Vamos a entrar al contenedor de Hadoop, ejecutar los comandos necesarios y comprobar que los archivos se creen correctamente.

## Requisitos

- Tener Docker instalado.
- Tener el contenedor `hadoop` corriendo.
- Tener acceso a la terminal.

## Paso a paso

### Paso 1: Abrimos la terminal del contenedor Hadoop

Usamos la terminal donde ya estamos dentro del contenedor y donde funciona el comando `hadoop`. No necesitamos clonar ni descargar este repositorio, ni copiar archivos desde la computadora.

### Paso 2: Preparamos y ejecutamos la etapa 1 — generar datos

Pegamos este primer bloque en la terminal del contenedor. Verificamos Hadoop, preparamos las carpetas y ejecutamos TeraGen para crear 100 000 filas.

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

`Correcto` confirma que se generaron los datos. Si aparece `Error`, nos detenemos y revisamos los mensajes antes de continuar.

### Paso 3: Etapa 2 — ordenar los datos

Solo si TeraGen terminó correctamente, pegamos este segundo bloque en la misma terminal. TeraSort lee la entrada y crea los datos ordenados.

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

`Confirmamos` que aparezca `_SUCCESS` en la lista. Si TeraSort muestra `Error` o no aparece `_SUCCESS`, no avanzamos a la siguiente etapa.

### Paso 4: Etapa 3 — validar y guardar el reporte

Solo si TeraSort terminó correctamente, pegamos este tercer bloque en la misma terminal. TeraValidate revisa el orden y después guardamos su reporte y los tiempos.

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

Si TeraValidate muestra `Error`, nos detenemos y revisamos el mensaje. Si termina correctamente, los resultados quedan dentro del contenedor, en `/tmp/terasort/resultados/`.

### Paso 5: Calculamos la clasificación y mostramos los tiempos

En la misma terminal del contenedor pegamos este bloque. Suma el tiempo de las tres etapas y lo compara con una escala orientativa para esta prueba de 100 000 filas (aproximadamente 10 MB):

- Hasta 4 segundos: **Tienes una PC master race** (tiempo muy corto).
- Más de 4 y hasta 10 segundos: **Tienes una PC buena** (tiempo normal).
- Más de 10 segundos: **Tienes una PC de rendimiento básico** (tiempo extenso).

La clasificación solo compara esta ejecución pequeña; no es una medición definitiva de la capacidad de la computadora. También influyen Docker, Hadoop y la carga del equipo.

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

Ahora mostramos la tabla y la clasificación para tomar la captura:

```bash
cat /tmp/terasort/resultados/time.md
```

`Confirmamos` que aparezcan las tres etapas con su duración y estado `Correcto`, el tiempo total y la clasificación. Tomamos una captura de pantalla donde se vea toda esa información.

## Resultado esperado

Al final verificamos que `/tmp/terasort/resultados/` contenga:

- `time.md`: duración y estado de TeraGen, TeraSort y TeraValidate.
- tiempo total de las tres etapas y su clasificación orientativa.
- `part-r-00000`: checksum del reporte de validación.
- `_SUCCESS`: confirma que TeraValidate terminó correctamente.

## Entregable

El único entregable es una **captura de pantalla** de la terminal del contenedor mostrando el contenido de `/tmp/terasort/resultados/time.md`. Debe incluir las duraciones de TeraGen, TeraSort y TeraValidate, el tiempo total, la clasificación y el estado `Correcto` de las tres etapas.

No es necesario editar ni entregar el `README.md`.

## Nota final

Ejecutamos las tres etapas en orden y en la misma terminal del contenedor: primero TeraGen, después TeraSort y al final TeraValidate. Así `time.md` acumula el tiempo de cada etapa.
