if(NOT EXISTS "${MSYS2_BIN_DIR}")
    return()
endif()

file(MAKE_DIRECTORY "${DEST_DIR}")
file(GLOB RUNTIME_DLLS "${MSYS2_BIN_DIR}/*.dll")

# Godot carga las dependencias nativas desde la carpeta de la extensión
foreach(RUNTIME_DLL IN LISTS RUNTIME_DLLS)
    file(COPY "${RUNTIME_DLL}" DESTINATION "${DEST_DIR}")
endforeach()