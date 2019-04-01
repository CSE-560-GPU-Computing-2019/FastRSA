# FastRSA
### RSA
The code for RSA is implemented in the RSA folder. To run the code, first run `make` in the directory and then execute `./rsa`. You can see the time taken by both approaches, the effective speedup and the output of both methods.
### Fermat Attack
The code for this is implemented in the Fermat folder. Run `make` followed by `./fermat`. The timings wont be visible here as an assembly trap has been used. To view timings, use nvprof to see the percentage of time taken by the kernel, which will be around 0.01% of the total wall clock time.