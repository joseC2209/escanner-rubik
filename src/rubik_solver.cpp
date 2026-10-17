#include "rubik_solver.h"
#include <godot_cpp/core/class_db.hpp>

namespace godot{

void RubikSolver::_bind_methods(){
    ClassDB::bind_method(D_METHOD("reset_to_solved"), &RubikSolver::reset_to_solved);
    ClassDB::bind_method(D_METHOD("get_state_string"), &RubikSolver::get_state_string);
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

}