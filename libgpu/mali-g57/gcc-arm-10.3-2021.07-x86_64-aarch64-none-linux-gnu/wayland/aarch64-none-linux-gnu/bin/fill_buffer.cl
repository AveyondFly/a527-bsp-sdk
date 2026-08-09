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

/* Simple kernel function which obtains the global work ID for this work item, and writes the ID (mod 256) to the
 * corresponding buffer location. */
__kernel void fill_buffer( __global unsigned char *buffer, const unsigned int buffer_size )
{
	/* Obtain the ID for this work item - we will use this to locate the corresponding */
	/* position in the buffer. */
	size_t id = get_global_id(0);

	/* The kernel may be invoked on data points which are outside the buffer (in order to honour
	global and local work space alignments for a particular device. Simply return in these cases. */
	if( id < buffer_size )
	{
		/* Fill the buffer location corresponding to this work item with the global ID (modulo 256) */
		buffer[id] = (id % 256);
	}
}
