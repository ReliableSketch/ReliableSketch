#include <sketch/cu.h>
#include <murmur3.h>
#include <utils.h>

#include <cstdio>
#include <cmath>
#include <cstring>
#include <climits>

CUSketch::CUSketch(double total_mem, int num_hash) :
total_mem(total_mem), num_hash(num_hash)
{
	sprintf(name, "CUSketch");

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

CUSketch::~CUSketch()
{
	if (cnt)
		delete [] cnt;
}

void
CUSketch::init()
{
	memset(cnt, 0, size * sizeof(int));
}

void
CUSketch::status()
{
	printf("total mem: %.2lfKB   bucket: %d   hash: %d\n", total_mem/1024, size, num_hash);
}

void
CUSketch::insert(int v)
{
	int minp = INT_MAX;
	int i = 0, base = 0;
	// speed up
	static int sav_pos[20];

	for (i = 0, base = 0; i < num_hash; ++i, base += row_size)
	{
		int pos = MurmurHash3_x86_32((void*)&v, sizeof(int), rand_array[i]) % row_size + base;
		sav_pos[i] = pos;
		minp = min(minp, cnt[pos]);
	}

	for (i = 0, base = 0; i < num_hash; ++i, base += row_size)
	{
		int pos = sav_pos[i];
		if (cnt[pos] == minp)
			cnt[pos]++;
	}	
}

int
CUSketch::query_freq(int v)
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
