#ifndef CUS_HEADER
#define CUS_HEADER

#include "sketch.h"

class CUSketch : public Sketch
{
private:
	int size, num_hash, row_size;
	int *cnt;

	int rand_base;
	int rand_array[30];

	double total_mem;

public:
	CUSketch(double total_mem, int num_hash);
	~CUSketch();
	void init();
	void insert(int v);
	int query_freq(int v);
	void status();
};

#endif