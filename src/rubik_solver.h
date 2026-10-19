#ifndef RUBIK_SOLVER_H
#define RUBIK_SOLVER_H

#include <godot_cpp/classes/ref_counted.hpp>
#include <godot_cpp/variant/string.hpp>

namespace godot{
    // Estructura ligera para representar una pieza
    struct CubeCorner{
        uint8_t piece; //ID de la pieza (del 0 al 7)
        uint8_t orientation; // Rotación de la pieza (del 0 al 2)
    };

    class RubikSolver : public RefCounted{
        GDCLASS(RubikSolver, RefCounted)

    private:
        CubeCorner state[8]; // El estado completo del cubo son las 8 esquinas

        // Identifica la pieza según sus colores
        uint8_t identify_piece(char c1, char c2, char c3);
    
    protected:
        static void _bind_methods();

    public:
        RubikSolver();
        ~RubikSolver();

        // Reinicia el cubo a su estado resuelto
        void reset_to_solved();

        // Devuelve el estado como texto para poder verlo en Godot
        String get_state_string();

        // Recibe la matriz de colores desde Godot
        void load_from_colors(Array faces);
    };
}

#endif