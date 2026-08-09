/*
 * Copyright:
 * ----------------------------------------------------------------------------
 * This confidential and proprietary software may be used only as authorized
 * by a licensing agreement from ARM Limited.
 *      (C) COPYRIGHT 2013 ARM Limited, ALL RIGHTS RESERVED
 * The entire notice above must be reproduced on all authorized copies and
 * copies may only be made to the extent permitted by a licensing agreement
 * from ARM Limited.
 * ----------------------------------------------------------------------------
 */

/* Kernel function to sum two vectors, result is stored in a. */
__kernel void add( __global float *a, __global float *b, uint length)
{
	/* Obtain the ID for this work item - we will use this to locate the corresponding */
	/* position in the vectors. */
	size_t id = get_global_id(0);

	/* The kernel may be invoked on data points which are outside the vector (in order to honour
	   global and local work space alignments for a particular device). Simply return in these cases. */
	if( id < length )
	{
		a[id] += b[id];
	}
}

/* Kernel function to multiply two vectors, result is stored in a. */
__kernel void mul( __global float *a, __global float *b, uint length)
{
	/* Obtain the ID for this work item - we will use this to locate the corresponding */
	/* position in the vectors. */
	size_t id = get_global_id(0);

	/* The kernel may be invoked on data points which are outside the vector (in order to honour
	   global and local work space alignments for a particular device). Simply return in these cases. */
	if( id < length )
	{
		a[id] *= b[id];
	}
}
