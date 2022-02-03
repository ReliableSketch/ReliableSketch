#ifndef COCO_HEADER
#define COCO_HEADER

#include "sketch.h"
#include <set>
using std::set;

class CocoSketch : public Sketch
{
private:
    struct Bucket {
        uint32_t key;
        uint32_t val;
    };

public:
    Bucket *buckets;
	int num_hash, row_size;
    double total_mem;

	int rand_base;
	int rand_array[30];

	CocoSketch(double total_mem, int num_hash);
	~CocoSketch();

	void init();
	void insert(int v);
	int query_freq(int v);
    
	void status();
};

#endif