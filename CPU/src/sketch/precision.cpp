#include <sketch/precision.h>
#include <murmur3.h>
#include <utils.h>

#include <cstdio>
#include <cstring>
#include <cmath>
#include <climits>
#include <cstdint>
#include <map>
using std::map;

const int BYTES_PER_BUCKET = 8;

PRECISION::PRECISION(double total_mem, int n_stage) :
n_stage(n_stage)
{
	sprintf(name, "PRECISION");

    row_size = total_mem / BYTES_PER_BUCKET / n_stage;  // 8 bytes per bucket
    size = row_size * n_stage;
	cnt = new int[size];
	fp = new int[size];
    rand_seed = new int[n_stage];
}

PRECISION::~PRECISION()
{
	if (cnt)
		delete [] cnt;
	if (fp)
		delete [] fp;
    if (rand_seed)
        delete [] rand_seed;
}

void
PRECISION::init()
{
	memset(cnt, 0, size * sizeof(int));
	memset(fp, 0, size * sizeof(int));
    rand_seed[0] = rand() % 13337;
    for (int i = 1; i < n_stage; ++i)
        rand_seed[i] = rand_seed[i-1] + 2;
}

void
PRECISION::insert(int v)
{
	int i, base, pos;
    int carry_min = INT_MAX, min_stage = -1;
	for (i = 0, base = 0; i < n_stage; ++i, base += row_size)
	{
		pos = MurmurHash3_x86_32((void*)&v, sizeof(int), rand_seed[i]) % row_size + base;
		if (fp[pos] == v) {
            cnt[pos]++;
            return;
        }
        if (cnt[pos] < carry_min) {
            carry_min = cnt[pos];
            min_stage = i;
        }
	}
    int R = RandUint32() % (carry_min + 1);
    if (R == 0) {
        pos = MurmurHash3_x86_32((void*)&v, sizeof(int), rand_seed[min_stage]) % row_size + row_size * min_stage;
        fp[pos] = v;
        cnt[pos]++;
    }
}

int
PRECISION::query_freq(int v)
{
	for (int i = 0, base = 0; i < n_stage; ++i, base += row_size)
	{
		int pos = MurmurHash3_x86_32((void*)&v, sizeof(int), rand_seed[i]) % row_size + base;
		if (fp[pos] == v)
            return cnt[pos];
	}
	return 0;
}

vector<PII>
PRECISION::query_heavyhitter(int threshold)
{
	vector<PII> ans;

    for (int pos = 0; pos < size; ++pos)
        if (cnt[pos] >= threshold) {
            ans.push_back(mp(cnt[pos], fp[pos]));
        }
	sort(ans.begin(), ans.end(), greater<PII>());

	return ans;
}


void
PRECISION::status()
{
	printf("total_bucket: %d   n_stage: %d\n", size, n_stage);
}
