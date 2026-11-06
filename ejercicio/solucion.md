# Solución del ejercicio

## Ejecución

No es necesario clonar el repositorio ni copiar un script. Abrimos una terminal dentro del contenedor Hadoop y pegamos los tres bloques de comandos de `ejercicio.md`, en orden y en la misma terminal.

Las etapas son:

1. **TeraGen:** prepara el entorno, genera 100 000 filas y registra su duración.
2. **TeraSort:** ordena las filas y agrega su duración a `time.md`.
3. **TeraValidate:** comprueba el orden, agrega su duración y guarda el reporte.

Avanzamos a la siguiente etapa solo cuando la anterior termine con el estado `Correcto`.

La clasificación orientativa usa el tiempo total de las tres etapas: hasta 4 segundos corresponde a “PC master race”, más de 4 y hasta 10 a “PC buena”, y más de 10 a “PC de rendimiento básico”. Una ejecución de 7 segundos queda en la categoría intermedia.

## Mostrar los tiempos y preparar el entregable

En la terminal del contenedor ejecutamos:

```bash
cat /tmp/terasort/resultados/time.md
```

La tabla muestra la duración y el estado de cada prueba. El entregable es una captura de pantalla donde se vea el comando y la tabla completa, con estado `Correcto` en las tres etapas. No hace falta descargar `time.md` ni entregar los archivos generados dentro del contenedor.

El reporte `part-r-00000` contiene el checksum calculado por TeraValidate; este checksum es una huella de los datos revisados, no una medición de tiempo.
