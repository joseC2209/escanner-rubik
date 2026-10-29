#ifndef SCANNER_CORE_H
#define SCANNER_CORE_H

#include <godot_cpp/classes/node.hpp>
#include <godot_cpp/classes/image.hpp>
#include <godot_cpp/variant/array.hpp>
#include <godot_cpp/variant/rect2.hpp>
#include <opencv2/opencv.hpp>

namespace godot{

    class ScannerCore : public Node{
        GDCLASS(ScannerCore, Node);

    private:
        cv::VideoCapture cap;

    protected:
        static void _bind_methods();
    
    public:
        ScannerCore();
        ~ScannerCore();

        void test_connection();
        bool open_camera();
        Ref<Image> get_frame();

        // Para windows
        Array analyze_colors(Array grid_rects);

        // Para Android (recibe la imagen de Godot)
        Array analyze_colors_from_image(Ref<Image> image, Array grid_rects);

    private:
        cv::Mat current_frame;
};

}

#endif

