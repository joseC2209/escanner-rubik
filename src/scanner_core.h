#ifndef SCANNER_CORE_H
#define SCANNER_CORE_H

#include <godot_cpp/classes/node.hpp>
#include <godot_cpp/classes/image.hpp>

#include <godot_cpp/variant/array.hpp>
#include <godot_cpp/variant/color.hpp>
#include <godot_cpp/variant/rect2.hpp>

#include <opencv2/opencv.hpp>

namespace godot{

    class ScannerCore : public Node{
        GDCLASS(ScannerCore, Node);


    private:
        cv::VideoCapture cap; // Objeto de cámara de OpenCV
        cv::Mat current_frame; // Guardar el frame actual

    protected:
        static void _bind_methods();
    
    public:
        ScannerCore();
        ~ScannerCore();

        void test_connection();
        bool open_camera();
        Ref<Image> get_frame(); // Devuelve la imagen a Godot

        Array analyze_colors(Array grid_rects);
};

}

#endif

