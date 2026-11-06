# Equipo 6: La suite TeraSort

Ejemplo de Hadoop que pone a prueba un clúster en tres pasos: **TeraGen** genera datos, **TeraSort** los ordena y **TeraValidate** comprueba que quedaron bien ordenados.

Este repositorio permite reproducir la prueba usando el contenedor de Hadoop 3.3.6 de la práctica *Hadoop Standalone en contenedor Debian*.

## ¿Para qué sirve?

TeraSort se usa como prueba de referencia para conocer el rendimiento de un clúster. Por ejemplo, cuando se instala un clúster nuevo, se corre esta prueba para saber si rinde como se esperaba. Si después se cambia una configuración, se repite la prueba para comparar tiempos.

## Requisitos

- Contenedor `hadoop` en funcionamiento (Debian + Java 17 + Hadoop 3.3.6).
- Git y Docker instalados en tu computadora.

## Estructura del repositorio

```
bda-equipo-6-terasort/
├── README.md
├── scripts/
│   └── ejecutar.sh       ← comandos en orden
├── resultados/           ← salida de la prueba
├── ejercicio/
│   ├── ejercicio.md
│   └── solucion.md
└── presentacion.pdf
```

## Cómo funciona

Cada paso lee lo que produjo el anterior:

1. **TeraGen** crea 100 000 filas de datos de prueba (unos 10 MB) en `/tmp/terasort/entrada`.
2. **TeraSort** reparte las filas entre varios procesos, cada uno ordena su parte, y el resultado queda en `/tmp/terasort/salida`.
3. **TeraValidate** lee la salida ordenada y verifica que no haya errores de orden. Su reporte queda en `/tmp/terasort/reporte`.

Los comandos se escriben en dos lugares, así que cada bloque está marcado:

- 💻 se ejecuta en **tu computadora**.
- 🐳 se ejecuta **dentro del contenedor** `hadoop`.

## Paso a paso

### 1. Entrar al contenedor 🐳

Desde tu computadora, abre una terminal y ejecuta:

💻
```bash
docker exec -it hadoop bash
```

Si el prompt cambia a `root@...`, estás dentro del contenedor.

### 2. Verificar la instalación 🐳

```bash
hadoop version
```

Debe aparecer `Hadoop 3.3.6`.

### 3. Definir la ruta del jar de ejemplos 🐳

```bash
export JAR=$HADOOP_HOME/share/hadoop/mapreduce/hadoop-mapreduce-examples-3.3.6.jar
```

### 4. Ejecutar TeraGen 🐳

```bash
time hadoop jar $JAR teragen 100000 /tmp/terasort/entrada
```

Verifica que se crearon los archivos:

```bash
hadoop fs -ls /tmp/terasort/entrada
```

Tiempo obtenido: **[ ] segundos**

### 5. Ejecutar TeraSort 🐳

```bash
time hadoop jar $JAR terasort /tmp/terasort/entrada /tmp/terasort/salida
```

Verifica el resultado. Debe existir un archivo `_SUCCESS`:

```bash
hadoop fs -ls /tmp/terasort/salida
```

Tiempo obtenido: **[ ] segundos**

### 6. Ejecutar TeraValidate 🐳

```bash
time hadoop jar $JAR teravalidate /tmp/terasort/salida /tmp/terasort/reporte
```

Revisa el reporte:

```bash
hadoop fs -cat /tmp/terasort/reporte/part-r-00000
```

No debe aparecer ningún error de orden.

Tiempo obtenido: **[ ] segundos**

### 7. Salir del contenedor 🐳

```bash
exit
```

### 8. Copiar los resultados a tu computadora 💻

Desde la carpeta del repositorio en tu computadora:

```bash
sudo docker cp hadoop:/tmp/terasort/reporte ./resultados
```

Si no tienes permiso para usar Docker sin `sudo`, agrega tu usuario al grupo `docker`:

```bash
sudo usermod -aG docker $USER
```

Luego cierra sesión y vuelve a entrar.

## Tiempos obtenidos

| Paso | Filas | Tiempo |
|------|-------|--------|
| TeraGen | 100 000 | [ ] |
| TeraSort | 100 000 | [ ] |
| TeraValidate | 100 000 | [ ] |

## Resultado esperado

- `_SUCCESS` en la salida de TeraSort, que confirma que el trabajo terminó bien.
- `part-r-00000` en el reporte de TeraValidate, con el checksum y sin errores de orden.

Las capturas de pantalla o los archivos de salida están en la carpeta `resultados/`.

## Solución de problemas

- **`hadoop: command not found`**: revisa que `HADOOP_HOME` esté definido en `~/.bashrc` y ejecuta `source ~/.bashrc`.
- **TeraSort falla porque no encuentra la entrada**: vuelve a ejecutar el paso 4. Si `/tmp/terasort/entrada` no existe, TeraSort no puede correr.
- **`Output directory ... already exists`**: borra la carpeta anterior antes de volver a ejecutar, con `hadoop fs -rm -r /tmp/terasort/salida`.
- **`permission denied` al usar `docker`**: usa `sudo` o agrega tu usuario al grupo `docker`, como se indica en el paso 8.

## Autores

Equipo 6 — [agrega los nombres de los integrantes]
