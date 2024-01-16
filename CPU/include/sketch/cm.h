#ifndef CMS_HEADER
#define CMS_HEADER

#include "sketch.h"

class CMSketch : public Sketch
{
private:
	int size, num_hash, row_size;
	int *cnt;

	int rand_base;
	int rand_array[30];

	double total_mem;

public:
	CMSketch(double total_mem, int num_hash);
	~CMSketch();
	void init();
	void insert(int v);
	int query_freq(int v);
	void status();
};

#endif