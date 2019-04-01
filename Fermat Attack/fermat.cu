#include <iostream>
#include <cuda.h>
#include <stdio.h>

/*
__global__ void
single_mult(const int n, const char* num, int len, char *result, const int index)
{
    int carry = 0;
    
    for (int i = len - 1; i >= 0; --i)
    {
        int m = num[i] - '0';
        result[i] = (m * n + carry) % 10;
        carry = m/10;
    }
}

__global__ void
big_multiply(const char *num1, const char* num2, char *result, int len1, int len2)
{
    
}


__device__ __host__ uint64_t
fast_sqroot(uint64_t n)
{

    uint64_t ret = 0;
    for (uint64_t h = n/2, l = 1, m = (h+l)/2; ; )
    {
        //printf("%lu %lu %lu %lu %lu\n", h, l, m, m*m, n);
        if (m*m == n)
        {
            ret = m;
            break;
        }
        else if (m*m < n)
        {
            l = m + 1;    
        }
        else
        {
            h = m - 1;
        }

        m = (h+l)/2;
        
        if (h <= l)
        {
            ret = m;
            break;
        }

        
    }
    
    return ret;
}

__global__ void
big_add(const char *a, const char *b, char *c)
{
    
}
*/
__device__ int
is_square(uint64_t t)
{
    return (uint64_t)sqrtf(t) * (uint64_t)sqrtf(t) == t;
}

__global__ void
fermat_factorization(const uint64_t n, uint64_t *p, uint64_t *q, const uint64_t a, int *flag)
{
    //if (*flag > 0) return;
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
        //printf("t: %lu\n", t);
        uint64_t b = (uint64_t)sqrtf(t);
        //printf("b: %lu, a: %lu, a-b: %lu, a+b: %lu\n", b, a, (a-b), (a+b));
        //printf("p*q: %lu, n: %lu\n", ((a-b) * (a+b)), n);
        uint64_t pr = (a+offset-b) * (a+offset+b);
        if (pr == n && a+offset>b)
        {
            
            *p = a+offset-b;
            *q = a+offset+b;
            //*flag += 1;
            printf("p: %lu, q: %lu\n", *p, *q);
            asm("trap;");
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
    /*
    char *message = (char *)malloc(sizeof(char) * 512);
    fgets(message, 512, stdin);
    message[strlen(message) - 1] = '\0';
    int message_size = strlen(message);
    unsigned int *plaintext = (unsigned int *)malloc(sizeof(unsigned int) * message_size);
    unsigned int *plaintext_device;
    char *message_device;
    cudaMalloc((void **)&plaintext_device, sizeof(unsigned int) * message_size);
    cudaMalloc((void **)&message_device, message_size);
    cudaMemcpy(message_device, message, message_size, cudaMemcpyHostToDevice);

    bytes_long <<<(message_size + 1023)/1024, 1024>>>(message_device, plaintext_device, message_size);

    cudaMemcpy(plaintext, plaintext_device, sizeof(unsigned int) * message_size, cudaMemcpyDeviceToHost);
    for (int i = 0 ; i < message_size ; ++i)
    {
        std::cout << plaintext[i];
    }
    std::cout<<"\n";
    
    int num_digits = 0;
    for (int i = 0 ; i < message_size ; ++i)
    {
        int cur = plaintext[i];
        while (cur > 0)
        {
            num_digits++;
            cur /= 10;
        }
    }
    */
    
    uint64_t n = 1103191240211;
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

    fermat_factorization<<<(n-a+1023)/1024, 1024>>>(n, p, q, a, flag);

    cudaMemcpy(ph, p, sizeof(uint64_t), cudaMemcpyDeviceToHost);
    cudaMemcpy(qh, q, sizeof(uint64_t), cudaMemcpyDeviceToHost);

    printf("%lu %lu\n", *ph, *qh);
    printf("Time elapsed in gpu %.2f ms\n", elapsed);
    
}