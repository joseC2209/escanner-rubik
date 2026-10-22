#include "rubik_solver.h"
#include <godot_cpp/core/class_db.hpp>

namespace godot{

void RubikSolver::_bind_methods(){
    ClassDB::bind_method(D_METHOD("reset_to_solved"), &RubikSolver::reset_to_solved);
    ClassDB::bind_method(D_METHOD("get_state_string"), &RubikSolver::get_state_string);
    ClassDB::bind_method(D_METHOD("load_from_colors", "faces"), &RubikSolver::load_from_colors);

    ClassDB::bind_method(D_METHOD("rotate_U"), &RubikSolver::rotate_U);
    ClassDB::bind_method(D_METHOD("rotate_R"), &RubikSolver::rotate_R);
    ClassDB::bind_method(D_METHOD("rotate_F"), &RubikSolver::rotate_F);

    ClassDB::bind_method(D_METHOD("solve"), &RubikSolver::solve);
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

void RubikSolver::rotate_U(){
    // Rotar la capa superior (Up) afecta a 0(UBL), 1 (UBR), 2 (UFL) y 3 (UFR)
    // No cambia las orientaciones
    CubeCorner tmp = state[2];
    state[2] = state[3]; // UFL recibe a UFR
    state[3] = state[1]; // UFR recibe a UBR
    state[1] = state[0]; // UBR recibe a UBL
    state[0] = tmp;      // UBL recibe a UFL
}

void RubikSolver::rotate_R(){
    // Rotar la capa derecha (Right) afecta a 1 (UBR), 3 (UFR), 5 (DBR) y 7 (DFR)
    CubeCorner tmp = state[7];
    state[7] = state[5]; // DFR recibe a DBR
    state[5] = state[1]; // DBR recibe a UBR
    state[1] = state[3]; // UBR recibe a UFR
    state[3] = tmp;      // UFR recibe a DFR

    // Al rotar R se cambian las orientaciones alternando +1 y +2
    state[1].orientation = (state[1].orientation + 1) % 3;
    state[5].orientation = (state[5].orientation + 2) % 3;
    state[7].orientation = (state[7].orientation + 1) % 3;
    state[3].orientation = (state[3].orientation + 2) % 3;
}

void RubikSolver::rotate_F(){
    // Rotar la capa frontal (Front) afecta a 2 (UFL), 3 (UFR), 6(DFL) y 7 (DFR)
    CubeCorner tmp = state[6];
    state[6] = state[7]; // DFL recibe a DFR
    state[7] = state[3]; // DFR recibe a UFR
    state[3] = state[2]; // UFR recibe a UFL
    state[2] = tmp;      // UFL recibe a DFL

    // Al rotar F se cambian las orientaciones alternando +1 y +2
    state[3].orientation = (state[3].orientation + 1) % 3;
    state[7].orientation = (state[7].orientation + 2) % 3;
    state[6].orientation = (state[6].orientation + 1) % 3;
    state[2].orientation = (state[2].orientation + 2) % 3;
}

uint64_t RubikSolver::encode_state() const{
    uint64_t hash = 0;
    for(int i = 0; i < 8; i++){
        // Se desplazan 5 bits por cada pieza,
        // se guarda la pieza (3 bits) y luego la orientación (2 bits)
        uint64_t p = state[i].piece;
        uint64_t o = state[i].orientation;

        hash |= (p << (i*5));
        hash |= (o << (i*5 + 3));
    }

    return hash;
}

String RubikSolver::solve(){
    uint64_t start_hash = encode_state();
    
    // Se guarda el estado inicial en un backup y se obtiene el hash del cubo resuelto
    CubeCorner initial_backup[8];
    for(int i = 0; i < 8; i++){
        initial_backup[i] = state[i];
    }

    reset_to_solved();
    uint64_t target_hash = encode_state();

    // Se restaura el estado antes de empezar a buscar
    for(int i = 0; i < 8; i++){
        state[i] = initial_backup[i];
    }

    // Caso base
    if(start_hash == target_hash){
        return "Cubo ya resuelto";
    }

    // Estructura interna para los nodos del BFS
    struct BFSNode{
        CubeCorner corners[8];
        std::string path;
    };

    std::queue<BFSNode> q;
    std::unordered_map<uint64_t, bool> visited;

    // Se inicializa el nodo raíz
    BFSNode start_node;
    for(int i = 0; i < 8; i++){
        start_node.corners[i] = state[i];
    }
    start_node.path = "";

    q.push(start_node);
    visited[start_hash] = true;

    // Bucle principal del BFS
    while(!q.empty()){
        BFSNode current = q.front();
        q.pop();

        // Se exploran las 3 caras ortogonales (U, R, F)
        for(int face = 0; face < 3; face++){
            // Se exploran los 3 tipos de giro (1 = 90º, 2 = 180º, 3 = 270º)
            for(int turns = 1; turns <= 3; turns++){
                
                // Se carga el estado del nodo en el solver para simular la física
                for(int i = 0; i < 8; i++){
                    state[i] = current.corners[i];
                }

                // Se aplica el movimiento simulado
                std::string move_name = "";
                if(face == 0){
                    for(int t = 0; t < turns; t++){
                        rotate_U();
                    }
                    move_name = (turns == 1) ? "U " : (turns == 2) ? "U2 " : "U' ";
                }else if(face == 1){
                    for(int t = 0; t < turns; t++){
                        rotate_R();
                    }
                    move_name = (turns == 1) ? "R " : (turns == 2) ? "R2 " : "R' ";
                }else{
                    for(int t = 0; t < turns; t++){
                        rotate_F();
                    }
                    move_name = (turns == 1) ? "F " : (turns == 2) ? "F2 " : "F' ";
                }

                // Se extrae el hash del nuevo estado
                uint64_t new_hash = encode_state();

                // Caso de solución encontrada
                if(new_hash == target_hash){
                    // Se restaura el cubo a su estado físico real
                    for(int i = 0; i < 8; i++){
                        state[i] = initial_backup[i];
                    }
                    std::string final_path = current.path + move_name;
                    return String(final_path.c_str());
                }

                // Si es un estado nuevo, se añade al mapa y a la cola de trabajo
                if(visited.find(new_hash) == visited.end()){
                    visited[new_hash] = true;

                    BFSNode next_node;
                    for(int i = 0; i < 8; i++){
                        next_node.corners[i] = state[i];
                    }
                    next_node.path = current.path + move_name;
                    q.push(next_node);
                }
            }
        }
    }

    // Si el árbol se agota sin solución, el usuario debió escanear mal una pegatina
    for(int i = 0; i < 8; i++){
        state[i] = initial_backup[i];
    }
    
    return "Error: Cubo irresoluble. Revisa el escaneo.";
}

}