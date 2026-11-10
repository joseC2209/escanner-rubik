if(NOT EXISTS "${MSYS2_BIN_DIR}")
    return()
endif()

file(MAKE_DIRECTORY "${DEST_DIR}")
# Se comprueba que existe la biblioteca que se acaba de compilar
if(NOT EXISTS "${EXTENSION_FILE}")
    message(FATAL_ERROR "No se encuentra la biblioteca: ${EXTENSION_FILE}")
endif()

# Se utiliza la herramienta de MSYS2 para analizar las dependencias
set(CMAKE_GET_RUNTIME_DEPENDENCIES_PLATFORM "windows+pe")
set(CMAKE_GET_RUNTIME_DEPENDENCIES_TOOL "objdump")
set(CMAKE_GET_RUNTIME_DEPENDENCIES_COMMAND "${MSYS2_BIN_DIR}/objdump.exe")

# Se obtienen las dependencias y las dependencias de estas
file(GET_RUNTIME_DEPENDENCIES
    LIBRARIES "${EXTENSION_FILE}"
    DIRECTORIES "${MSYS2_BIN_DIR}"
    RESOLVED_DEPENDENCIES_VAR RUNTIME_DLLS
    UNRESOLVED_DEPENDENCIES_VAR MISSING_DLLS
    PRE_EXCLUDE_REGEXES
        "^api-ms-"
        "^ext-ms-"
    POST_EXCLUDE_REGEXES
        ".*[/\\\\][Ss][Yy][Ss][Tt][Ee][Mm]32[/\\\\].*"
)

# Se detiene la copia si falta alguna dependencia
if(MISSING_DLLS)
    message(FATAL_ERROR "No se encuentran estas dependencias: ${MISSING_DLLS}")
endif()

# Godot carga las dependencias nativas desde la carpeta de la extensión
foreach(RUNTIME_DLL IN LISTS RUNTIME_DLLS)
    file(COPY "${RUNTIME_DLL}" DESTINATION "${DEST_DIR}")
endforeach()