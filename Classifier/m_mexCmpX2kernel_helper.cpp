/*
 * m_mexCmpKernel
 *
 * Created on: Aug 10, 2012
 * Author: Minh Hoai Nguyen, University of Oxford
 * Email:  minhhoai@robots.ox.ac.uk
 */

#include <stdlib.h>
#include <math.h>
#include <mex.h>
#include <vector>
#include <limits>

typedef unsigned int  uint32 ;
typedef unsigned char uint8;
typedef unsigned int retType;
//typedef double retType;

using namespace std;

// Compute train and test kernels
void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {
   enum{
      A_IN = 0,  // first matrix, train data
      B_IN,      // second matrix, test data
      TYPE_IN    // 'X2' or 'inter'
   };
      
   int d = mxGetM(prhs[A_IN]);
   int n = mxGetN(prhs[A_IN]);
   int m = mxGetN(prhs[B_IN]);
   
   double eps = numeric_limits<double>::epsilon();
   
   if (mxGetM(prhs[B_IN]) != d) mexErrMsgTxt("dimension mismatch");
   
   double *A_ptr = (double *) mxGetPr(prhs[A_IN]);
   double *B_ptr = (double *) mxGetPr(prhs[B_IN]);
   
   plhs[0] = mxCreateDoubleMatrix(m, n, mxREAL);
   double *K_ptr  = (double*) mxGetPr(plhs[0]);
      
   // compute the train kernel
   double *a_i, *b_j;
   double val;   
   
   //Compute the kernel before exponetial
   for (int i=0; i < n; i++){
	   a_i = A_ptr + d*i;   
	   for (int j=0; j < m; j++){
		   b_j = B_ptr + d*j;
		   val = 0;
		   for (int u=0; u < d; u++){
			   val += pow(a_i[u] - b_j[u], 2)/(a_i[u] + b_j[u] + eps); 			   
		   }		   
		   *K_ptr++ = val;
	   }
   }
}
