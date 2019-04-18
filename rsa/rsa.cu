#include <iostream>
#include <stdio.h>


__device__ long long int mod(int base, int exponent, int den)
{
	unsigned int a = (  base % den   ) * ( base % den);
	// unsigned int a = base * base;
	unsigned long long int ret = 1;
	float size = (float) exponent / 2;
	if (  exponent == 0 ) {
		return base % den;
	}
	else
	{
		while (1)
		{
			if ( size > 0.5  )
			{
				ret = ( ret * a  ) % den; size = size - 1.0;
			}
			else if (  size == 0.5  )
			{
				ret = (  ret * (  base % den  )   ) % den;
				// ret = ( ret  * base   ) % den;
				break;
			}
			else
			{
				break;

			}
		}
		return ret;
	}
}

__global__ void parallel_reduction(int *array, int *output, int mod)
{
	extern __shared__ int sdata[];
	int tid = threadIdx.x;
	int i = blockIdx.x * (blockDim.x) + tid;
	sdata[tid] = array[i] ;
	__syncthreads();
	
	
	//SINGLE BLOCK SLOW
	///*
	for ( unsigned int s = 1; s < blockDim.x; s *= 2 ){
		if ( tid % ( 2 * s  ) == 0  ){
			if (tid + s < blockDim.x){
				sdata[tid] = ( (sdata[tid]  % mod  ) * (sdata[ tid + s ] % mod ) )% mod;
			}
		}
		__syncthreads();
	}
	//*/
	
	//SINGLE BLOCK MEDIUM
	/*
	for (int s = 1; s < blockDim.x ; s *= 2){
		int index = 2 * s * tid;
		if ( index  + s< blockDim.x  ){
			sdata[index] = ( (sdata[index]  % mod  ) * (sdata[ index + s ] % mod ) )% mod;

		}
		__syncthreads();

	}
	*/

	if (tid == 0){
		output[blockIdx.x] = sdata[0];
	}
}

__global__ void sumCommMultiBlock(const int *gArr, int arraySize, int *gOut, int mod, int blockSize) {
    int thIdx = threadIdx.x;
    int gthIdx = thIdx + blockIdx.x*blockSize;
    const int gridSize = blockSize*gridDim.x;
    int sum = 1;
    for (int i = gthIdx; i < arraySize; i += gridSize)
        sum = ( ( sum % mod  ) *  (gArr[i] % mod ) ) % mod ;
    __shared__ int shArr[1024];
    shArr[thIdx] = sum;
    __syncthreads();
    for (int size = blockSize/2; size>0; size/=2) { //uniform
        if (thIdx<size)
		shArr[thIdx] = ( (shArr[thIdx]  % mod  ) * (shArr[ thIdx + size ] % mod ) )% mod;
        __syncthreads();
    }
    if (thIdx == 0)
        gOut[blockIdx.x] = shArr[0];
}

__global__ void init_reduction(int value, int *array, int n)
{
	int index = threadIdx.x + blockIdx.x * blockDim.x;
	if (index >= n) return;
	array[index] = value;
}


__global__ void rsa( int *num, int *key, int *den, unsigned int *result)
{
	int i = threadIdx.x;
	int temp;
	if (i == 0)
	{
		temp = mod( num[i], *key, *den);
		atomicExch( &result[i], temp );
	}
}

int main(){
	int nsize = 5;
	int num[5] = {104,101, 108, 108, 111};
	int key = 4000;
	int size = key / 2;
	int den = 91 * 97;
	int *d_num, *d_key, *d_den;
	unsigned int *d_res;
	unsigned int res[5] = {1,1,1,1,1};
	
	int num_blocks = (key + 2047 )/ 2048 ;
	int num_threads = 0;
	size <= 1024 ? num_threads = size:num_threads=1024;

	cudaMalloc( (void **)&d_num, nsize * sizeof(int) );
	cudaMalloc( (void **)&d_key, sizeof(int) );
	cudaMalloc( (void **)&d_den, sizeof(int)  );
	cudaMalloc( (void **)&d_res, nsize * sizeof(unsigned int) );
	
	cudaMemcpy( d_num, &num, nsize * sizeof(int), cudaMemcpyHostToDevice);
	cudaMemcpy( d_key, &key, sizeof(int), cudaMemcpyHostToDevice);
	cudaMemcpy( d_den, &den, sizeof(int), cudaMemcpyHostToDevice);
	cudaMemcpy( d_res, res, nsize* sizeof(unsigned int), cudaMemcpyHostToDevice);
	
	cudaEvent_t start_p, stop_p;
    	float time;
    	cudaEventCreate(&start_p);
    	cudaEventCreate(&stop_p);
    	cudaEventRecord(start_p, 0);
	
	rsa<<<1,5>>>(d_num, d_key, d_den, d_res);
	
	cudaEventRecord(stop_p, 0);
	cudaEventSynchronize(stop_p);
	cudaEventElapsedTime(&time, start_p, stop_p);

	cudaEventDestroy (start_p);
	cudaEventDestroy (stop_p);
	
	cudaMemcpy(res, d_res, nsize * sizeof(unsigned int), cudaMemcpyDeviceToHost);
	
	printf("Paper Time :   %f\n" , time );

	int base = (num[0] * num[0]) % den;
	int *input;
	int *output;
	int *ans;
	
	ans = (int *) malloc( size * sizeof(int)  );
	cudaMalloc( (void **)&input, size * sizeof(int)  );
	cudaMalloc( (void **)&output, size * sizeof(int)  );

	float new_time;
    	cudaEventCreate(&start_p);
    	cudaEventCreate(&stop_p);
    	cudaEventRecord(start_p, 0);

	init_reduction<<<num_blocks,num_threads>>>(base, input, size );

	parallel_reduction<<<num_blocks,num_threads,size * sizeof(int)>>>(input, output, den);
	//sumCommMultiBlock<<<num_blocks,num_threads>>>(input,size,output,den,num_blocks);
	
	cudaEventRecord(stop_p, 0);
	cudaEventSynchronize(stop_p);
	cudaEventElapsedTime(&new_time, start_p, stop_p);

	printf("Our Time : %f\n", new_time);
	printf("Speedup : %f\n", time/new_time);
	
	cudaEventDestroy (start_p);
	cudaEventDestroy (stop_p);
	
	cudaDeviceSynchronize();

	cudaMemcpy( ans, output, size * sizeof(int), cudaMemcpyDeviceToHost);
	
	int final_ans = ans[0];
	for (int i = 1;i < num_blocks;i++){
		final_ans = ( (final_ans % den) * (ans[i] % den ) ) % den;
	}
	
	printf("%d -  %d\n", final_ans, res[0] );
	cudaFree(d_num);
	cudaFree(d_key);
	cudaFree(d_den);
	cudaFree(d_res);
	cudaFree(input);
	cudaFree(output);
	free(ans);
	return 0;
}
