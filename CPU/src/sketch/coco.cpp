#include <sketch/coco.h>
#include <murmur3.h>
#include <utils.h>

#include <cstdio>
#include <cmath>
#include <cstring>
#include <climits>

#define MEM_PER_BUCKET 8

CocoSketch::CocoSketch(double total_mem, int num_hash) :
total_mem(total_mem), num_hash(num_hash)
{
	sprintf(name, "CocoSketch");

	if (total_mem <= 0 || num_hash <= 0)
	{
		panic("TOTAL_MEM & NUM_HASH must be POSITIVE.");
	}

    rand_base = RandUint32() % 13337;
    for (int i = 0; i < num_hash; ++i)
        rand_array[i] = rand_base + i;
    row_size = (int)(total_mem / num_hash / MEM_PER_BUCKET);
    buckets = new Bucket[row_size * num_hash];
    total_mem = row_size * num_hash * MEM_PER_BUCKET;  // fix
}

CocoSketch::~CocoSketch()
{
    if (buckets)
        delete [] buckets;
}

void
CocoSketch::init()
{
	memset(buckets, 0, row_size * num_hash * sizeof(Bucket));
}

void
CocoSketch::status()
{
	printf("total_mem: %.2lfKB  row_size: %d   hash: %d\n", total_mem/1024, row_size, num_hash);
}

void
CocoSketch::insert(int v)
{
	int i = 0, base = 0;
    int min_val = INT_MAX, min_pos = -1;

	for (i = 0, base = 0; i < num_hash; ++i, base += row_size)
	{
		int pos = MurmurHash3_x86_32((void*)&v, sizeof(int), rand_array[i]) % row_size + base;
        Bucket &bucket = buckets[pos];
		if (bucket.key == v) {
            bucket.val += 1;
            return;
        }
        if (bucket.val < min_val) {
            min_val = bucket.val;
            min_pos = pos;
        }
	}

    buckets[min_pos].val += 1;
    min_val += 1;
    // replace ID
    if (RandUint32() % min_val == 0) {
        buckets[min_pos].key = v;
    }
}

int
CocoSketch::query_freq(int v)
{
	int i = 0, base = 0;
    int ans = INT_MAX;

	for (i = 0, base = 0; i < num_hash; ++i, base += row_size)
	{
		int pos = MurmurHash3_x86_32((void*)&v, sizeof(int), rand_array[i]) % row_size + base;
        Bucket &bucket = buckets[pos];
		if (bucket.key == v) {
            return bucket.val;
        }
        ans = min(ans, (int)bucket.val);
	}
    return ans;
}
