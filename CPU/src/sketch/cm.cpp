#include <sketch/cm.h>
#include <murmur3.h>
#include <utils.h>

#include <cstdio>
#include <cmath>
#include <cstring>
#include <climits>

CMSketch::CMSketch(double total_mem, int num_hash) :
total_mem(total_mem), num_hash(num_hash)
{
	sprintf(name, "CMSketch");

	size = (int)(total_mem/4);
	if (size <= 0 || num_hash <= 0)
	{
		panic("SIZE & NUM_HASH must be POSITIVE integers.");
	}
	cnt = new int[size];
	
    rand_base = RandUint32() % 13337;
    for (int i = 0; i < num_hash; ++i)
        rand_array[i] = rand_base + i;
	row_size = size / num_hash;
}

CMSketch::~CMSketch()
{
	if (cnt)
		delete [] cnt;
}

void
CMSketch::init()
{
	memset(cnt, 0, size * sizeof(int));
}

void
CMSketch::status()
{
	printf("total mem: %.2lfKB   bucket: %d   hash: %d\n", total_mem/1024, size, num_hash);
}

void
CMSketch::insert(int v)
{
	int i = 0, base = 0;

	for (i = 0, base = 0; i < num_hash; ++i, base += row_size)
	{
		int pos = MurmurHash3_x86_32((void*)&v, sizeof(int), rand_array[i]) % row_size + base;
		cnt[pos]++;
	}
}

int
CMSketch::query_freq(int v)
{
	int ans = INT_MAX;
	int i = 0, base = 0;

	for (i = 0, base = 0; i < num_hash; ++i, base += row_size)
	{
		int pos = MurmurHash3_x86_32((void*)&v, sizeof(int), rand_array[i]) % row_size + base;
		ans = min(ans, cnt[pos]);
	}

	return ans;
}
