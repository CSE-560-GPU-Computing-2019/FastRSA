#include <iostream>
#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <cmath>
#include <string.h>
#include <ctime>
#include <iomanip>

using namespace std;

uint64_t
gcd(uint64_t u, uint64_t v)
{
	if (v)
        return gcd(v, u % v);
    else
        return u;
}


void
pollard_factorization(const uint64_t n)
{
    for (int b = 2; b < 10000; b++)
    {
    	uint64_t *arr = (uint64_t *)malloc((b+1) * sizeof(uint64_t));
	    memset(arr, 0, (b+1) * sizeof(uint64_t));
	    uint64_t M = 1;
	    for (int i = 2; i <= b; ++i)
	    {
	    	if (arr[i] == 0)
	    	{
	    		for (int j = i+i; j <= b; j += i)
	    		{
	    			arr[j] = 1;
	    		}

	    		M *= pow(i, (uint64_t)floor(log(b)/log(i)));
	    	}	
	    }
	    uint64_t am = pow(2, M);
	    am--;
	    uint64_t p = gcd(am, n), q = n/p;
	    if (p != 1 && p != n)
	    {
	    	printf("%lu %lu\n", p, q);
	    }
    }
}

int
main(int argc, char *argv[])
{
    
    uint64_t n = 299;
    float elapsed = 0;


    clock_t start, stop;
    start = clock();
    pollard_factorization(n);
    stop = clock();
    cout << "Execution Time: " << fixed << (double(stop - start) / double(CLOCKS_PER_SEC))*1000 << setprecision(5) << " ms\n";
}
