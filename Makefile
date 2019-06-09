all:
	/usr/local/cuda/bin/nvcc blur.cu -o blur_cuda Jpegfile.cpp JpegLib/libjpeg.a -std=c++11
