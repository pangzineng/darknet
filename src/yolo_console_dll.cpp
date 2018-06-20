#include <iostream>
#include <iomanip> 
#include <string>
#include <vector>
#include <queue>
#include <fstream>
#include <thread>
#include <atomic>
#include <mutex>              // std::mutex, std::unique_lock
#include <condition_variable> // std::condition_variable
#include <ctime>
#include <map>
#include <stdlib.h> /* atoi */

#define OPENCV

// To use tracking - uncomment the following line. Tracking is supported only by OpenCV 3.x
//#define TRACK_OPTFLOW

//#include "C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v9.1\include\cuda_runtime.h"
//#pragma comment(lib, "C:/Program Files/NVIDIA GPU Computing Toolkit/CUDA/v9.1/lib/x64/cudart.lib")
//static std::shared_ptr<image_t> device_ptr(NULL, [](void *img) { cudaDeviceReset(); });

#include "yolo_v2_class.hpp"	// imported functions from DLL

#include <opencv2/opencv.hpp>			// C++
#include "opencv2/core/version.hpp"
#include "opencv2/videoio/videoio.hpp"
#define OPENCV_VERSION CVAUX_STR(CV_VERSION_MAJOR)"" CVAUX_STR(CV_VERSION_MINOR)"" CVAUX_STR(CV_VERSION_REVISION)
#pragma comment(lib, "opencv_world" OPENCV_VERSION ".lib")


float weight_func(float prob) {
	if (prob >= 0.5) return 1.0;
	if (prob < 0.25) return prob;
	return 0.5;
}

std::string time_convert(double ts) {
	char date[15];
	time_t epoch = ts;
	strftime(date, sizeof(date), "%Y%m%d%H%M%S", std::gmtime(&epoch));
	std::string str(date);
	return str;
}

std::vector<std::string> objects_names_from_file(std::string const filename) {
	std::ifstream file(filename);
	std::vector<std::string> file_lines;
	if (!file.is_open()) return file_lines;
	for(std::string line; getline(file, line);) file_lines.push_back(line);
	return file_lines;
}

// format: tsv
// column: timestamp, expose_head_count, expose_time_volume, hc_list(comma-separated + trailing), tv_list(comma-separated + trailing)
void post_chunks(std::map<int, float> chunk, std::string cur_ts, int const video_fps) {
	std::vector<int> ks;
	std::vector<float> vs;
	for (auto const& element : chunk) {
		ks.push_back(element.first);
	}
	float etv = 0;
	for (auto const& element : chunk) {
		etv += element.second/video_fps;
		vs.push_back(element.second/video_fps);
	}
	std::cout << cur_ts << "\t" << chunk.size() << "\t" << std::setprecision(3) << etv << "\t";
	for (const auto& i: ks) {
		std::cout << i << ',';
	}
	std::cout << "\t";
	for (const auto& i: vs) {
		std::cout << i << ',';
	}
	std::cout  << std::endl;
}


int main(int argc, char *argv[])
{
	std::string names_file = argv[1];
	std::string cfg_file = argv[2];
	std::string weights_file = argv[3];
	std::string data_file = argv[4];
	double const start_time = std::stoi( argv[5] );
	float const thresh = (argc > 6) ? std::stof(argv[6]) : 0.20;
	std::string accepted_label = "person";

	Detector detector(cfg_file, weights_file);

	auto obj_names = objects_names_from_file(names_file);

	while (true) 
	{		
		if(data_file.size() == 0) std::cin >> data_file;
		if (data_file.size() == 0) break;
		
		try {
			float cur_time_extrapolate = 0, old_time_extrapolate = 0;
			std::string const file_ext = data_file.substr(data_file.find_last_of(".") + 1);
			std::string const protocol = data_file.substr(0, 7);
			if (file_ext == "avi" || file_ext == "mp4" || file_ext == "mjpg" || file_ext == "mov" || 	// video file
				protocol == "rtmp://" || protocol == "rtsp://" || protocol == "http://" || protocol == "https:/")	// video network stream
			{
				cv::Mat cap_frame, cur_frame;
				std::shared_ptr<image_t> det_image;
				std::vector<bbox_t> result_vec, thread_result_vec;
				detector.nms = 0.02;	// comment it - if track_id is not required
				std::atomic<bool> consumed;
				bool exit_flag = false;
				consumed = true;
				std::atomic<int> fps_det_counter, fps_cap_counter;
				fps_det_counter = 0;
				fps_cap_counter = 0;
				int current_det_fps = 0, current_cap_fps = 0;
				std::thread t_detect, t_cap;
				std::mutex mtx;
				std::condition_variable cv_detected, cv_pre_tracked;
				std::chrono::steady_clock::time_point steady_start, steady_end;
				cv::VideoCapture cap(data_file); cap >> cur_frame;
				int const video_fps = cap.get(CV_CAP_PROP_FPS);
				cv::Size const frame_size = cur_frame.size();

				std::map<int, float> chunk;
				std::string cur_ts = time_convert(start_time);
				std::string old_ts = time_convert(start_time);

				while (!cur_frame.empty()) 
				{
					// always sync
					if (t_cap.joinable()) {
						t_cap.join();
						++fps_cap_counter;
						cur_frame = cap_frame.clone();
					}
					t_cap = std::thread([&]() { cap >> cap_frame; });
					++cur_time_extrapolate;

					// swap result bouned-boxes and input-frame
					if(consumed)
					{
						std::unique_lock<std::mutex> lock(mtx);
						det_image = detector.mat_to_image_resize(cur_frame);
						auto old_result_vec = detector.tracking_id(result_vec);
						auto detected_result_vec = thread_result_vec;
						result_vec = detected_result_vec;
						result_vec = detector.tracking_id(result_vec);	// comment it - if track_id is not required					
						// add old tracked objects
						for (auto &i : old_result_vec) {
							auto it = std::find_if(result_vec.begin(), result_vec.end(),
								[&i](bbox_t const& b) { return b.track_id == i.track_id && b.obj_id == i.obj_id; });
							bool track_id_absent = (it == result_vec.end());
							if (track_id_absent) {
								if (i.frames_counter-- > 1)
									result_vec.push_back(i);
							}
							else {
								it->frames_counter = std::max((unsigned)1, i.frames_counter + 1);
							}
						}
						consumed = false;
						cv_pre_tracked.notify_all();
					}
					// launch thread once - Detection
					if (!t_detect.joinable()) {
						t_detect = std::thread([&]() {
							auto current_image = det_image;
							consumed = true;
							while (current_image.use_count() > 0 && !exit_flag) {
								auto result = detector.detect_resized(*current_image, frame_size.width, frame_size.height, 
									thresh, false);	// true
								++fps_det_counter;
								std::unique_lock<std::mutex> lock(mtx);
								thread_result_vec = result;
								consumed = true;
								cv_detected.notify_all();
								if (detector.wait_stream) {
									while (consumed && !exit_flag) cv_pre_tracked.wait(lock);
								}
								current_image = det_image;
							}
						});
					}
					//while (!consumed);	// sync detection

					if (!cur_frame.empty()) {
						steady_end = std::chrono::steady_clock::now();
						if (std::chrono::duration<double>(steady_end - steady_start).count() >= 1) {
							current_det_fps = fps_det_counter;
							current_cap_fps = fps_cap_counter;
							steady_start = steady_end;
							fps_det_counter = 0;
							fps_cap_counter = 0;
						}

						for (auto &i : result_vec) {
							if (accepted_label.compare(obj_names[i.obj_id]) != 0) continue;
							float weight = weight_func(i.prob);
							chunk[i.track_id] += weight;
						}
					}

					// wait detection result for video-file only (not for net-cam)
					if (protocol != "rtsp://" && protocol != "http://" && protocol != "https:/") {
						std::unique_lock<std::mutex> lock(mtx);
						while (!consumed) cv_detected.wait(lock);
					}

					cur_ts = time_convert(start_time + cur_time_extrapolate/video_fps);
					if (cur_ts.compare(old_ts) > 0) {
						post_chunks(chunk, cur_ts, video_fps);
						old_ts = cur_ts;
						chunk.clear();
					}
				}
				exit_flag = true;
				if (t_cap.joinable()) t_cap.join();
				if (t_detect.joinable()) t_detect.join();
				post_chunks(chunk, cur_ts, video_fps);
				break;
			}
		}
		catch (std::exception &e) { std::cerr << "exception: " << e.what() << "\n"; getchar(); }
		catch (...) { std::cerr << "unknown exception \n"; getchar(); }
		data_file.clear();
	}

	return 0;
}