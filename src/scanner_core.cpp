#include "scanner_core.h"
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/utility_functions.hpp>

namespace godot{

    void ScannerCore::_bind_methods(){
        ClassDB::bind_method(D_METHOD("test_connection"), &ScannerCore::test_connection);
        ClassDB::bind_method(D_METHOD("open_camera"), &ScannerCore::open_camera);
        ClassDB::bind_method(D_METHOD("get_frame"), &ScannerCore::get_frame);
        ClassDB::bind_method(D_METHOD("analyze_colors", "grid_rects"), &ScannerCore::analyze_colors);
        ClassDB::bind_method(D_METHOD("analyze_colors_from_image", "image", "grid_rects"), &ScannerCore::analyze_colors_from_image);
    }

    ScannerCore::ScannerCore(){}
    ScannerCore::~ScannerCore(){
        if(cap.isOpened()) cap.release();
    }

    void ScannerCore::test_connection(){
        UtilityFunctions::print("¡Hola desde C++! El puente GDExtension funciona.");
    }

    bool ScannerCore::open_camera(){
        for(int camera_index = 0; camera_index < 3 && !cap.isOpened(); ++camera_index){
            // Se intenta con la API genérica por defecto
            cap.open(camera_index, cv::CAP_ANY);

            // Si falla, se fuerza la API nativa de Android
            if(!cap.isOpened()) cap.open(camera_index, cv::CAP_ANDROID);

            // Si también falla, se intenta con las de Windows
            if(!cap.isOpened()) cap.open(camera_index, cv::CAP_MSMF);
            if(!cap.isOpened()) cap.open(camera_index, cv::CAP_DSHOW);

            if(cap.isOpened()){
                // En móviles, el sensor tarda en inicializarse. 
                // Leemos unos cuantos frames "basura" al vacío para darle tiempo a calentar
                // y NO cerramos la cámara si salen negros.
                cv::Mat dummy;
                for(int i = 0; i < 5; i++){
                    cap.read(dummy);
                }
                // Si hemos llegado hasta aquí, la damos por válida y salimos del bucle
                break;
            }
        }
        return cap.isOpened();
    }

    Ref<Image> ScannerCore::get_frame(){
        if(!cap.isOpened()) return Ref<Image>();

        cap >> current_frame;
        if(current_frame.empty()) return Ref<Image>();

        cv::Mat frame = current_frame;

        cv::Mat frame_rgb;
        cv::cvtColor(frame, frame_rgb, cv::COLOR_BGR2RGB);
        if(!frame_rgb.isContinuous()) frame_rgb = frame_rgb.clone();

        PackedByteArray data;
        data.resize(frame_rgb.total() * frame_rgb.channels());
        memcpy(data.ptrw(), frame_rgb.data, data.size());
        return Image::create_from_data(frame_rgb.cols, frame_rgb.rows, false, Image::FORMAT_RGB8, data);
    }

    Array ScannerCore::analyze_colors(Array grid_rects){
        Array result_colors;

        if(current_frame.empty()){
            return result_colors;
        }
        cv::Mat frame = current_frame;

        // Se procesan las regiones
        for(int i = 0; i < grid_rects.size(); i++){
            Rect2 godot_rect = grid_rects[i];

            // Se convierte Rect2 de Godot a cv::Rect de OpenCV
            cv::Rect cv_rect(godot_rect.position.x, godot_rect.position.y, godot_rect.size.width, godot_rect.size.height);

            // Se asegura que el recorte no se salga de los límites de la cámara
            cv_rect &= cv::Rect(0, 0, frame.cols, frame.rows);

            if(cv_rect.area() > 0){
                // Se recorta el cuadradito
                cv::Mat roi = frame(cv_rect);

                cv::Scalar avg_bgr = cv::mean(roi);

                // Se convierte el color promedio a HSV
                cv::Mat3b bgr_pixel(cv::Vec3b(avg_bgr[0], avg_bgr[1], avg_bgr[2]));
                cv::Mat3b hsv_pixel;
                cv::cvtColor(bgr_pixel, hsv_pixel, cv::COLOR_BGR2HSV);

                int h = hsv_pixel(0,0)[0]; // Matiz (0 a 179 en OpenCV)
                int s = hsv_pixel(0,0)[1]; // Saturación (0 a 255)
                int v = hsv_pixel(0,0)[2]; // Brillo (0 a 255)

                // Se clasifica el color usando umbrales
                String color_name = "?";

                if(s < 70 && v > 100){ 
                    color_name = "W"; // Si la saturación es muy baja y hay luz suficiente, es blanco
                }else{
                    if(h < 5 || h > 165){
                        color_name = "R"; // El rojo está cerca del 0 y del 179
                    }else if(h >= 5 && h < 16){
                        color_name = "O"; // Naranja
                    }else if(h >= 16 && h < 38){
                        color_name = "Y"; // Amarillo
                    }else if(h >= 38 && h < 85){
                        color_name = "G"; // Verde
                    }else if(h >= 85 && h < 130){
                        color_name = "B"; // Azul
                    }else{
                        color_name = "R"; // Suele ser rojo mal iluminado
                    }
                }

                result_colors.push_back(color_name);
            }
        }

        return result_colors;
    }

    Array ScannerCore::analyze_colors_from_image(Ref<Image> image, Array grid_rects){
        Array result_colors;

        if(image.is_null() || image->is_empty()){
            return result_colors;
        }

        // Godot envía la imagen, aseguramos que sea RGB
        if(image->get_format() != Image::FORMAT_RGB8){
            image->convert(Image::FORMAT_RGB8);
        }

        int width = image->get_width();
        int height = image->get_height();
        PackedByteArray data = image->get_data();

        // Se crea el cv::Mat usando los bytes de Godot (RGB)
        cv::Mat frame(height, width, CV_8UC3, data.ptrw());

        for(int i = 0; i < grid_rects.size(); i++){
            Rect2 godot_rect = grid_rects[i];
            cv::Rect cv_rect(godot_rect.position.x, godot_rect.position.y, godot_rect.size.width, godot_rect.size.height);
            cv_rect &= cv::Rect(0, 0, frame.cols, frame.rows);

            if(cv_rect.area() > 0){
                cv::Mat roi = frame(cv_rect);

                // El promedio calculado aquí es RGB ya que Godot pasa a RGB
                cv::Scalar avg_rgb = cv::mean(roi);

                // Se convierte RGB a HSV
                cv::Mat3b rgb_pixel(cv::Vec3b(avg_rgb[0], avg_rgb[1], avg_rgb[2]));
                cv::Mat3b hsv_pixel;
                cv::cvtColor(rgb_pixel, hsv_pixel, cv::COLOR_RGB2HSV);

                int h = hsv_pixel(0,0)[0];
                int s = hsv_pixel(0,0)[1];
                int v = hsv_pixel(0,0)[2];

                String color_name = "?";
                if(s < 70 && v > 100){
                    color_name = "W";
                }else{
                    if(h < 5 || h > 165) color_name = "R";
                    else if(h >= 5 && h < 16) color_name = "O";
                    else if(h >= 16 && h < 38) color_name = "Y";
                    else if(h >= 38 && h < 85) color_name = "G";
                    else if(h >= 85 && h < 130) color_name = "B";
                    else color_name = "R";
                }
                result_colors.push_back(color_name);
            }
        }
        return result_colors;
    }

}