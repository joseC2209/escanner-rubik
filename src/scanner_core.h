#ifndef SCANNER_CORE_H
#define SCANNER_CORE_H

#include <godot_cpp/classes/node.hpp>

namespace godot{

    class ScannerCore : public Node{
        GDCLASS(ScannerCore, Node)

    protected:
        static void _bind_methods();
    
    public:
        ScannerCore();
        ~ScannerCore();

        void test_connection();
};

}

#endif

