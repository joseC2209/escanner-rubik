# Escáner de cubo de Rubik 2×2×2

Aplicación desarrollada como Trabajo de Fin de Grado en Ingeniería del Software
en la Universidad de Málaga. Permite escanear las seis caras de un cubo con la
cámara, revisar los colores detectados y seguir la solución en un visor 3D.

La aplicación utiliza Godot 4.7.2 con el renderizador Compatibility.
El análisis de color con OpenCV y el solucionador están implementados en C++
y se integran mediante GDExtension. La aplicación se ha probado en Windows
y en un Redmi 10C con Android.

## Estructura del repositorio

- [`project/`](project/) contiene el proyecto Godot, sus escenas y las pruebas.
- [`src/`](src/) contiene el código C++ de la extensión.
- [`godot-cpp/`](godot-cpp/) es el submódulo con los enlaces de C++ para Godot.
- [`CMakeLists.txt`](CMakeLists.txt) configura la compilación de la extensión.

## Compilación y pruebas en Windows

Se necesita Godot 4.7.2 y una instalación de MSYS2 UCRT64 con
GCC, binutils, Make, CMake, Python y OpenCV.

Desde PowerShell, en la raíz del repositorio, inicializa el submódulo
y añade al `PATH` las herramientas de UCRT64 para esa sesión.

```powershell
git submodule update --init --recursive
$ucrt64 = 'C:/msys64/ucrt64'
$env:Path = "$ucrt64/bin;$env:Path"
```

Si MSYS2 está instalado en otro directorio, ajusta `$ucrt64`.
Configura y compila la extensión con CMake.

```powershell
cmake -S . -B build -G "MinGW Makefiles" `
  "-DCMAKE_BUILD_TYPE=Debug" `
  "-DGODOTCPP_TARGET=template_debug" `
  "-DUCRT64_ROOT=$ucrt64"

cmake --build build --target rubik_scanner
```

La compilación genera la DLL de la extensión en `project/bin/windows/`.
El paso posterior a la compilación copia allí las dependencias detectadas.

Para abrir la aplicación, importa `project/project.godot` en Godot 4.7.2
y ejecuta la escena principal. Para ejecutar las pruebas desde PowerShell,
ajusta `$godot` a la ruta de tu ejecutable de consola de Godot.

```powershell
$godot = 'C:\ruta\a\Godot_v4.7.2-stable_win64_console.exe'

& $godot --headless --path ".\project" `
  --script "res://tests/test_rubik_solver.gd"

$LASTEXITCODE
```

Si todas las comprobaciones pasan, el código de salida es `0`.

### Medición del rendimiento

Con la extensión compilada y `$godot` configurado, ejecuta desde la raíz
del repositorio.

```powershell
& $godot --headless --path ".\project" `
  --script "res://tests/benchmark_rubik_solver.gd"
```

El script ejecuta cuatro casos y muestra la longitud de la solución
devuelta y los tiempos mínimo, mediano y máximo de 21 mediciones por caso.

## Integración continua

El flujo [Continuous Integration](.github/workflows/ci.yml) se ejecuta
al publicar cambios en `main`. Prepara MSYS2 UCRT64 y OpenCV en Windows,
compila la extensión con CMake y ejecuta las pruebas del solucionador
con Godot 4.7.2 en modo `headless`.

Los resultados se pueden consultar en la pestaña **Actions** de GitHub.
El flujo comprueba la compilación y las pruebas del solucionador en
Windows. La exportación y la comprobación de la APK se realizan por separado.

## Proyecto de partida

La estructura inicial de la extensión se basó en la plantilla
[godot-cpp-template](https://github.com/enetheru/godot-cpp-template).
La configuración de compilación y el flujo de integración continua
se adaptaron al escáner y a sus pruebas.