#ifndef SCANNER_CORE_H
#define SCANNER_CORE_H

#include <godot_cpp/classes/node.hpp>
#include <godot_cpp/classes/image.hpp>
#include <opencv2/opencv.hpp>

namespace godot{

    class ScannerCore : public Node{
        GDCLASS(ScannerCore, Node);


    private:
        cv::VideoCapture cap; // Objeto de cámara de OpenCV
    protected:
        static void _bind_methods();
    
    public:
        ScannerCore();
        ~ScannerCore();

        void test_connection();
        bool open_camera();
        Ref<Image> get_frame(); // Devuelve la imagen a Godot
};

}

#endif

