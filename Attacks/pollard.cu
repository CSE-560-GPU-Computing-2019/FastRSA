#include <iostream>
#include <cuda.h>
#include <stdio.h>

__device__ uint64_t
gcd(uint64_t u, uint64_t v)
{
    int shift;
    if (u == 0) return v;
    if (v == 0) return u;
    shift = __clzll(__brevll(u | v));
    u >>= __clzll(__brevll(u));
    do 
    {
        v >>= __clzll(__brevll(v));
        if (u > v) 
        {
            uint64_t t = v;
            v = u;
            u = t;
        }  
        v = v - u;
    } while (v != 0);
    return u << shift;
}


__global__ void
seive(uint64_t *arr, const uint64_t val, const uint64_t limit)
{
	int tx = threadIdx.x;
	int bx = blockIdx.x;
	int bd = blockDim.x;

	int idx = tx + bx * bd;

	if (idx * val > limit || idx == 0 || idx == 1)
		return;

	arr[idx * val] = 1;
}


__global__ void
pollard_factorization(const uint64_t n)
{
    int idx = threadIdx.x + blockDim.x * blockIdx.x;
    if (idx < 2)
    {
    	return;
    }

    int b = idx;

    uint64_t *arr = (uint64_t *)malloc((b+1) * sizeof(uint64_t));
    memset(arr, 0, (b+1) * sizeof(uint64_t));
    uint64_t M = 1;
    for (int i = 2; i <= b; ++i)
    {
    	if (arr[i] == 0)
    	{
    		seive<<<(b+1023)/1024, 1024>>>(arr, i, b);
    		cudaDeviceSynchronize();
    		M *= (uint64_t)ceil(pow(i, (uint64_t)(floor(__logf(b)/__logf(i)))));
    	}	
    }
    free(arr);
    uint64_t am = pow(2, M);
    am--;
    uint64_t p = gcd(am, n), q = n/p;
    if (p != 1 && p != n)
    {
    	printf("%llu %llu\n", p, q);
    }
}

__host__ int
main(int argc, char *argv[])
{
    
    uint64_t n = 299;//, b = atoi(argv[1]);
    float elapsed = 0;


    cudaEvent_t d_start, d_stop;
	cudaEventCreate(&d_start);
	cudaEventCreate(&d_stop);
	cudaEventRecord(d_start, 0);
    pollard_factorization<<<40, 20>>>(n);
    cudaEventRecord(d_stop);
	cudaEventSynchronize(d_stop);
	cudaEventElapsedTime(&elapsed, d_start, d_stop);
	cudaEventDestroy(d_start);
	cudaEventDestroy(d_stop);

    
    //printf("Time taken: %fms\n\n", runTime*1000);
    //printf("%lu %lu\n", *ph, *qh);
    printf("Time elapsed in gpu %.2f ms\n", elapsed);
    
}
