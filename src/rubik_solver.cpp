#include "rubik_solver.h"
#include <godot_cpp/core/class_db.hpp>

namespace godot{

void RubikSolver::_bind_methods(){
    ClassDB::bind_method(D_METHOD("reset_to_solved"), &RubikSolver::reset_to_solved);
    ClassDB::bind_method(D_METHOD("get_state_string"), &RubikSolver::get_state_string);
    ClassDB::bind_method(D_METHOD("load_from_colors", "faces"), &RubikSolver::load_from_colors);
}

RubikSolver::RubikSolver(){
    reset_to_solved();
}

RubikSolver::~RubikSolver(){}

void RubikSolver::reset_to_solved(){
    // Se inicializan las 8 esquinas, la pieza 'i' va en la posición 'i' con orientación 0
    for(uint8_t i = 0; i < 8; ++i){
        state[i].piece = i;
        state[i].orientation = 0;
    }
}

String RubikSolver::get_state_string(){
    String result = "[ ";
    for(int i = 0; i < 8; ++i){
        result += "P" + String::num_int64(state[i].piece) + 
                  "O" + String::num_int64(state[i].orientation) + " ";
    }
    result += "]";
    return result;
}

uint8_t RubikSolver::identify_piece(char c1, char c2, char c3){

    // Buscamos qué colores tiene
    bool hasW = (c1 == 'W' || c2 == 'W' || c3 == 'W');
    bool hasY = (c1 == 'Y' || c2 == 'Y' || c3 == 'Y');
    bool hasG = (c1 == 'G' || c2 == 'G' || c3 == 'G');
    bool hasB = (c1 == 'B' || c2 == 'B' || c3 == 'B');
    bool hasR = (c1 == 'R' || c2 == 'R' || c3 == 'R');
    bool hasO = (c1 == 'O' || c2 == 'O' || c3 == 'O');

    // Mapeo fijo de las 8 piezas
    if(hasW && hasB && hasO) return 0; // UBL = Arriba-Atrás-Izquierda
    if(hasW && hasB && hasR) return 1; // UBR = Arriba-Atrás-Derecha
    if(hasW && hasG && hasO) return 2; // UFL = Arriba-Frente-Izquierda
    if(hasW && hasG && hasR) return 3; // UFR = Arriba-Frente-Derecha
    if(hasY && hasB && hasO) return 4; // DBL = Abajo-Atrás-Izquierda
    if(hasY && hasB && hasR) return 5; // DBR = Abajo-Atrás-Derecha
    if(hasY && hasG && hasO) return 6; // DFL = Abajo-Frente-Izquierda
    if(hasY && hasG && hasR) return 7; // DFR = Abajo-Frente-Derecha

    return 0;
}

void RubikSolver::load_from_colors(Array faces){
    String color_string = "";

    // Se recorren las 6 caras
    for(int i = 0; i < faces.size(); i++){
        Array face = faces[i];

        // Se recorren los 4 colores de la cara
        for(int j = 0; j < face.size(); j++){
            color_string += face[j].operator String();
        }
    }

    // Matriz de índices topológicos: [Pieza][Color U/D, Color Sentido Horario 1, Color Sentido Horario 2]
    // Basado en el orden de escaneo: U(0-3), F(4-7), R(8-11), B(12-15), L(16-19), D(20-23)
    int corners_idx[8][3] = {
        {0, 13, 16},  // 0 = UBL (U-TL, B-TR, L-TL)
        {1, 9, 12},   // 1 = UBR (U-TR, B-TL, R-TR)
        {2, 17, 4},   // 2 = UFL (U-BL, F-TL, L-TR)
        {3, 5, 8},    // 3 = UFR (U-BR, F-TR, R-TL)
        {22, 15, 18}, // 4 = DBL (D-BL, B-BR, L-BL)
        {23, 11, 14}, // 5 = DBR (D-BR, B-BL, B-BR)
        {20, 19, 6},  // 6 = DFL (D-TL, L-BR, F-BL)
        {21, 7, 10}   // 7 = DFR (D-TR, F-BR, R-BL)
    };

    for(int i = 0; i < 8; i++){
        char c1 = color_string[corners_idx[i][0]];
        char c2 = color_string[corners_idx[i][1]];
        char c3 = color_string[corners_idx[i][2]];

        uint8_t piece_id = identify_piece(c1, c2, c3);
        uint8_t orientation = 0;

        // Si el color primario (blanco o amarillo) está en c2, ha rotado en sentido horario
        if(c2 == 'W' || c2 == 'Y'){
            orientation == 1;
        } // Si está en c3, ha rotado en sentido antihorario
        else if(c3 == 'W' || c3 == 'Y'){
            orientation = 2;
        }

        state[i].piece = piece_id;
        state[i].orientation = orientation;
    }

    UtilityFunctions::print("Cubo mapeado matemáticamente: ", get_state_string());
}

}