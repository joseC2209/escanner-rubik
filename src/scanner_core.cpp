#include "scanner_core.h"
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/utility_functions.hpp>

namespace godot{

    void ScannerCore::_bind_methods(){
        // Exponemos la función a GDScript
        ClassDB::bind_method(D_METHOD("test_connection"), &ScannerCore::test_connection);
    }

    ScannerCore::ScannerCore(){}
    ScannerCore::~ScannerCore(){}

    void ScannerCore::test_connection(){
        UtilityFunctions::print("¡Hola desde C++! El puente GDExtension funciona.");
    }

}