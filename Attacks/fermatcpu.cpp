#include <iostream>
#include <ctime>
#include <unistd.h>
#include <stdlib.h>
#include <stdint.h>
#include <stdio.h>
#include <cmath>

using namespace std;

int
is_square(uint64_t t)
{
    return (uint64_t)sqrtf(t) * (uint64_t)sqrtf(t) == t;
}

void
fermat_factorization(const uint64_t n, uint64_t *p, uint64_t *q, const uint64_t a)
{
    //if (*flag > 0) return;
    printf("%lu\n", n-a);
    for (uint64_t i = 0; i < n - a; ++i)
    {
    	uint64_t offset = i;
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
	            
	            //return;
	        }  
	    }
    }
    

}

int 
main()
{
	uint64_t n = 4335743309;//69417725381;//18512544;//4335743309;//1103191240211;
			     
    uint64_t a = (uint64_t)sqrt(n);
    printf("a: %lu\n", a);
    uint64_t *p = (uint64_t *)malloc(sizeof(uint64_t));
    uint64_t *q = (uint64_t *)malloc(sizeof(uint64_t));
    float elapsed = 0;
    const clock_t begin_time = clock();
    fermat_factorization(n, p, q, a);
    float runTime = (float)(clock() - begin_time)*1000 / CLOCKS_PER_SEC;
    printf("p: %lu, q: %lu\n", *p, *q);
    printf("Time elapsed in cpu %.4f ms\n", runTime);
}