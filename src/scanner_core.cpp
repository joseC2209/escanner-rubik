#include "scanner_core.h"
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/utility_functions.hpp>

namespace godot{

    void ScannerCore::_bind_methods(){
        // Exponemos la función a GDScript
        ClassDB::bind_method(D_METHOD("test_connection"), &ScannerCore::test_connection);
        ClassDB::bind_method(D_METHOD("open_camera"), &ScannerCore::open_camera);
        ClassDB::bind_method(D_METHOD("get_frame"), &ScannerCore::get_frame);
        ClassDB::bind_method(D_METHOD("analyze_colors", "grid_rects"), &ScannerCore::analyze_colors);
    }

    ScannerCore::ScannerCore(){}
    ScannerCore::~ScannerCore(){
        // Si la cámara está abierta, se apaga tras cerrar Godot
        if(cap.isOpened()){
            cap.release();
        }
    }

    void ScannerCore::test_connection(){
        UtilityFunctions::print("¡Hola desde C++! El puente GDExtension funciona.");
    }

    bool ScannerCore::open_camera(){
        // Probamos varias entradas porque el índice 0 puede ser una cámara normal o virtual
        for(int camera_index = 0; camera_index < 3 && !cap.isOpened(); ++camera_index){
            // Media Foundation suele funcionar mejor con webcams modernas de Windows
            cap.open(camera_index, cv::CAP_MSMF);
            // DirectShow es la alternativa para los dispositivos que no soportan MSMF
            if(!cap.isOpened()) cap.open(camera_index, cv::CAP_DSHOW);

            cv::Mat test_frame;
            // Descartamos cámaras que abren pero no entregan ningún frame
            if(cap.isOpened() && (!cap.read(test_frame) || test_frame.empty())) cap.release();
            if(cap.isOpened()){
                cv::Scalar mean;
                cv::Scalar standard_deviation;
                cv::meanStdDev(test_frame, mean, standard_deviation);
                // Un frame completamente uniforme suele indicar un sensor infrarrojo o una entrada vacía
                if(standard_deviation[0] < 2.0 && standard_deviation[1] < 2.0 && standard_deviation[2] < 2.0) cap.release();
            }
        }
        return cap.isOpened();
    }

    Ref<Image> ScannerCore::get_frame(){
        if(!cap.isOpened()) return Ref<Image>();

        // Se guarda el frame para que analyze_colors pueda acceder a él
        cap >> current_frame;

        if(current_frame.empty()) return Ref<Image>();

        cv::Mat frame;
        cap >> frame; // Se extrae el fotograma actual de la webcam

        if(frame.empty()) return Ref<Image>();

        // OpenCV usa BGR, Godot lo quiere en orden RGB
        cv::Mat frame_rgb;
        cv::cvtColor(frame, frame_rgb, cv::COLOR_BGR2RGB);
        // La copia evita problemas si OpenCV devuelve filas con padding en memoria
        if(!frame_rgb.isContinuous()) frame_rgb = frame_rgb.clone();

        // Copiamos los píxeles al formato de array que entiende la API de Godot
        PackedByteArray byte_array;
        byte_array.resize(frame_rgb.total() * frame_rgb.channels());
        memcpy(byte_array.ptrw(), frame_rgb.data, byte_array.size());

        // Creamos la imagen con las dimensiones y el formato RGB del frame
        Ref<Image> img = Image::create_from_data(frame_rgb.cols, frame_rgb.rows, false, Image::FORMAT_RGB8, byte_array);
        return img;
    }

    Array ScannerCore::analyze_colors(Array grid_rects){
        Array result_colors;

        if(current_frame.empty()){
            return result_colors;
        }

        for(int i = 0; i < grid_rects.size(); i++){
            Rect2 godot_rect = grid_rects[i];

            // Se convierte Rect2 de Godot a cv::Rect de OpenCV
            cv::Rect cv_rect(godot_rect.position.x, godot_rect.position.y, godot_rect.size.width, godot_rect.size.height);

            // Se asegura que el recorte no se salga de los límites de la cámara
            cv_rect &= cv::Rect(0, 0, current_frame.cols, current_frame.rows);

            if(cv_rect.area() > 0){
                // Se recorta el cuadradito
                cv::Mat roi = current_frame(cv_rect);

                // Se calcula el color promedio (BGR ya que es lo que usa OpenCV por defecto)
                cv::Scalar avg_color = cv::mean(roi);

                // Se convierte BGR a RGB para que Godot lo comprenda
                Color godot_color(avg_color[2] / 255.0, avg_color[1] / 255.0, avg_color[0] / 255.0);
                result_colors.push_back(godot_color);
            }
        }

        return result_colors;
    }

}