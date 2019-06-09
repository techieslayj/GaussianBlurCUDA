//AJ Iglesias//
//Blur Blur Blur//
//Shared mem//

#include <stdio.h>
#include <stdlib.h>
#include <iostream>
#include "Jpegfile.h"

#define block 32
using namespace std;

//use device for image blur here ints index and r are indexing for pixels by thread and the radius respectively
__global__ void blur(BYTE * devdataBuf, BYTE * devprocessBuf, int width, int height){


	int i = threadIdx.x;
	int j = threadIdx.y;
	int I = blockIdx.x * block + i;
	int J = blockIdx.y * block + j;



	int weights[5][5] = { {1, 4, 6, 4, 1}, {4, 16, 24, 16, 4}, {6, 24, 36, 24, 6}, {4, 16, 24, 16, 4}, {1, 4, 6, 4, 1 }};
	__shared__  BYTE pixels[block+4][block+4][3];


	if(I < width && J < height){
		//this is what we manipulate i's and J's when doing bottom, top, left, right stuff
		pixels[j+2][i+2][0] = devdataBuf[(J * width + I)*3];
		pixels[j+2][i+2][1] = devdataBuf[(J * width + I)*3+ 1];
		pixels[j+2][i+2][2] = devdataBuf[(J * width + I)*3+ 2];
		int left = blockIdx.x * block -2;
		int right = blockIdx.x * block + block-1 + 2;
		int bottom = blockIdx.y* block -2;
		int top = blockIdx.y * block + block-1 +2;

		if(i < 2) {
			if(left > 0){
				pixels[j+2][i][0] = devdataBuf[(J * width + left + i)*3];
				pixels[j+2][i][1] = devdataBuf[(J * width + left + i)*3 + 1];
				pixels[j+2][i][2] = devdataBuf[(J * width + left + i)*3 + 2];

				if( j < 2) {
					if (bottom > 0) {
						pixels[j][i][0] = devdataBuf[((bottom+j)*width+left+i)*3];
						pixels[j][i][1] = devdataBuf[((bottom+j)*width+left+i)*3+ 1];
						pixels[j][i][2] = devdataBuf[((bottom+j)*width+left+i)*3+ 2];
					}
				}
				if(j >= block-2){
					int jj = j - (block-2);
					if(top < height) {
						pixels[block+3-jj][i][0] = devdataBuf[((top-jj)*width+left+i)*3];
						pixels[block+3-jj][i][1] = devdataBuf[((top-jj)*width+left+i)*3+ 1];
						pixels[block+3-jj][i][2] = devdataBuf[((top-jj)*width+left+i)*3+ 2];
					}
			}
		}

	}
		if(i >= block-2){
			//update right ghost
			int ii = i - (block-2);
			if(right < width){
				pixels[j+2][block+3-ii][0] = devdataBuf[(J * width + right - ii)*3];
				pixels[j+2][block+3-ii][1] = devdataBuf[(J * width + right - ii)*3 + 1];
				pixels[j+2][block+3-ii][2] = devdataBuf[(J * width + right - ii)*3 + 2];
				//pixels[j+2][block+3-ii][2] = devdataBuf[(J * width + right - ii)*3 + 2];

				//update right bottom ghosts
				if(j < 2){
					if(bottom > 0){
						pixels[j][block-ii+3][0] = devdataBuf[((bottom+j) * width + right - ii)*3];
						pixels[j][block-ii+3][1] = devdataBuf[((bottom+j) * width + right- ii)*3 + 1];
						pixels[j][block-ii+3][2] = devdataBuf[((bottom+j) * width + right - ii)*3 + 2];
						//pixels[j][i+2][2] = devdataBuf[(J * width + top + block - 2 + i)*3 + 2];
					}

				}


				//update right top ghosts
				if( j >= block-2){
					int jj = j - (block-2);
					if ( top < height){
						pixels[block+3-jj][block-ii+3][0] = devdataBuf[((top-1+jj)* width +right - ii)*3];
						pixels[block+3-jj][block-ii+3][1] = devdataBuf[((top-1+jj)* width +right - ii)*3 + 1];
						pixels[block+3-jj][block-ii+3][2] = devdataBuf[((top-1+jj)* width +right - ii)*3 + 2];

					}
			}
		}
}


		if(j < 2){
			//update bottom ghost
			if(bottom > 0){
				pixels[j][i+2][0] = devdataBuf[((bottom+j) * width + I)*3];
				pixels[j][i+2][1] = devdataBuf[((bottom+j) * width + I)*3 + 1];
				pixels[j][i+2][2] = devdataBuf[((bottom+j) * width + I)*3 - 2];

			}

		}
		if(j >= block-2){
			//update top ghost
			int jj = j - (block-2);
			if(top < height){
				pixels[block+3-jj][i+2][0] = devdataBuf[((top-jj) * width + I)*3];
				pixels[block+3-jj][i+2][1] = devdataBuf[((top-jj) * width + I)*3 + 1];
				pixels[block+3-jj][i+2][2] = devdataBuf[((top-jj) * width + I)*3 + 2];


			}
}
}

	__syncthreads();


	if(I < width && J < height) {
		int r = 0, g = 0, b = 0;
		int totw = 0;

		for(int row = -2; row <= 2; row++){
			for(int col = -2; col <= 2; col++){
				int w = weights[row+2][col+2];
				r += pixels[j+row+2][i+col+2][0] * w;
				g += pixels[j+row+2][i+col+2][1] * w;
				b += pixels[j+row+2][i+col+2][2] * w;
				totw += w;
				//pRed = pixels[nrow * width * 3 + ncol * 3];
				//pGrn = pixels[nrow * width * 3 + ncol * 3 + 1];
				//pBlu = pixels[nrow * width * 3 + ncol * 3 + 2];

				//avgRed += (double)(*pRed);
				//avgGrn += (double)(*pGrn);
				//avgBlu += (double)(*pBlu);
				//pixCount++;
			}
		}

		devprocessBuf[(J*width+I)*3] = (BYTE)(r / totw);
		devprocessBuf[(J*width+I)*3+1] = (BYTE)(g / totw);
		devprocessBuf[(J*width+I)*3+2] = (BYTE)(b / totw);

}
}


int main(int argc, char* argv[]){


	// set up BYTE arrays
	BYTE *dataBuf, *ddataBuf;
	BYTE *processBuf, *dprocessBuf;

	UINT height, width;
	//read the file to dataBuf with RGB format
	//host reads in image i.e. host code

	dataBuf = JpegFile::JpegFileToRGB("MBAPPE.jpg", &width, &height);

	int size = 3 * width * height * sizeof(BYTE);

	cudaEvent_t start,stop;

	float cudaElapsed = 0;

	//allocate memory on device buffers

	cudaMalloc((void **)&ddataBuf, size * 3);
	cudaMalloc((void **)&dprocessBuf, size * 3);


	processBuf = (BYTE*) calloc(height * width * 3, sizeof(BYTE));

	cudaElapsed = 0;

		//copy dataBuf to device
	cudaMemcpy(ddataBuf, dataBuf, size, cudaMemcpyHostToDevice);

	//establish threads
	dim3 dimgrid((width+block-1)/block,(height+block-1)/block, 1);

	dim3 dimblock(block, block, 1);

	cudaEventCreate(&start);
	cudaEventCreate(&stop);
	cudaEventRecord(start,0);

	//Run device blur function
	blur<<<dimgrid,dimblock>>>(ddataBuf, dprocessBuf, width, height);



	cudaEventRecord(stop,0);
	cudaEventSynchronize(stop);
	cudaEventElapsedTime(&cudaElapsed, start, stop);
	cudaEventDestroy(start);
	cudaEventDestroy(stop);
	cudaMemcpy(processBuf, dprocessBuf, size, cudaMemcpyDeviceToHost);

	//Print out corresponding threads processing time
	cout << "Processing Time: " << cudaElapsed << endl;


JpegFile::RGBToJpegFile("MBAPPEblur.jpg", processBuf, width, height, true, 75);
cudaFree(dprocessBuf);
cudaFree(ddataBuf);

return 0;

}
