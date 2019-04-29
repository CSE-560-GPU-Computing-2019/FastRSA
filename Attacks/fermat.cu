#include <iostream>
#include <cuda.h>
#include <stdio.h>

__device__ int
is_square(uint64_t t)
{
    return (uint64_t)sqrtf(t) * (uint64_t)sqrtf(t) == t;
}

__global__ void
fermat_factorization(const uint64_t n, uint64_t *p, uint64_t *q, const uint64_t a, int *flag)
{
    uint64_t offset = threadIdx.x + blockDim.x * blockIdx.x;

    if (offset + a >= n)
        return;

    if (n % 2 == 0)
    {
        *p = 2;
        *q = n>>1;
        return;
    }    
    
    uint64_t t = (a + offset)*(a + offset) - n;

    if (is_square(t))
    {
        uint64_t b = (uint64_t)sqrtf(t);
        uint64_t pr = (a+offset-b) * (a+offset+b);
        if (pr == n && a+offset>b)
        {
            
            *p = a+offset-b;
            *q = a+offset+b;
            
            //asm("trap;");
        }  
    }

}


__global__ void
big_product(unsigned int *a, unsigned int *b, unsigned int *accumulator, int n)
{
    int multiplier = 0;
    unsigned int index = (blockIdx.x * blockDim.x) + threadIdx.x;
    if (index >= n) return;
    unsigned int multiplicand = index;
    unsigned int product = 0;

    while(multiplier < n) 
    {
        product = a[multiplier] * b[multiplicand];
        atomicAdd(&accumulator[multiplier + index], product<<24>>24);
        atomicAdd(&accumulator[multiplier + index + 1], product>>8);
        multiplier++;
    }
	return;
}

__global__ void 
long_bytes(const unsigned int *input, char *output, int length)
{
    int tx = threadIdx.x;
    int bx = blockIdx.x;
    int bd = blockDim.x;
    int index = bx*bd + tx;
    if (index >= length) return;
    output[index] = (char)input[index];
}

__global__ void 
bytes_long(const char *input, unsigned int *output, const int length)
{
    int tx = threadIdx.x;
    int bx = blockIdx.x;
    int bd = blockDim.x;
    int index = bx*bd + tx;
    if (index >= length) return;
    output[index] = (uint64_t)input[index];
}


__host__ int
main()
{
    
    uint64_t n = 4335743309;//69417725381;//18512544;//4335743309;//1103191240211;//18512544
    uint64_t a = (uint64_t)sqrt(n);
    printf("a: %lu\n", a);
    uint64_t *p, *q;
    int *flag;
    uint64_t *ph = (uint64_t *)malloc(sizeof(uint64_t));
    uint64_t *qh = (uint64_t *)malloc(sizeof(uint64_t));
    cudaMalloc((void **)&p, sizeof(uint64_t));
    cudaMalloc((void **)&q, sizeof(uint64_t));
    cudaMalloc((void **)&flag, sizeof(int));
   

   	float elapsed = 0;


    cudaEvent_t d_start, d_stop;
	cudaEventCreate(&d_start);
	cudaEventCreate(&d_stop);
	cudaEventRecord(d_start, 0);
    fermat_factorization<<<(n-a+1023)/1024, 1024>>>(n, p, q, a, flag);
    cudaEventRecord(d_stop);
	cudaEventSynchronize(d_stop);
	cudaEventElapsedTime(&elapsed, d_start, d_stop);
	cudaEventDestroy(d_start);
	cudaEventDestroy(d_stop);
    cudaMemcpy(ph, p, sizeof(uint64_t), cudaMemcpyDeviceToHost);
    cudaMemcpy(qh, q, sizeof(uint64_t), cudaMemcpyDeviceToHost);
    
    //printf("Time taken: %fms\n\n", runTime*1000);
    //printf("%lu %lu\n", *ph, *qh);
    printf("p: %lu, q: %lu\n", *ph, *qh);
    printf("Time elapsed in gpu %.4f ms\n", elapsed);
    
}
