#include <sketch/hashpipe.h>
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

HashPipe::HashPipe(double total_mem, int n_stage) :
n_stage(n_stage)
{
	sprintf(name, "HashPipe");

    row_size = total_mem / BYTES_PER_BUCKET / n_stage;  // 8 bytes per bucket
    size = row_size * n_stage;
	cnt = new int[size];
	fp = new int[size];
    rand_seed = new int[n_stage];
}

HashPipe::~HashPipe()
{
	if (cnt)
		delete [] cnt;
	if (fp)
		delete [] fp;
    if (rand_seed)
        delete [] rand_seed;
}

void
HashPipe::init()
{
	memset(cnt, 0, size * sizeof(int));
	memset(fp, 0, size * sizeof(int));
    rand_seed[0] = rand() % 13337;
    for (int i = 1; i < n_stage; ++i)
        rand_seed[i] = rand_seed[i-1] + 2;
}

void
HashPipe::insert(int v)
{
	int i, base, pos;
    int ckey = v, cval = 1;
    {
		pos = MurmurHash3_x86_32((void*)&v, sizeof(int), rand_seed[0]) % row_size;
        if (fp[pos] == v) {
            cnt[pos]++;
            return;
        }
        swap(cnt[pos], cval);
        swap(fp[pos], ckey);
    }
	for (i = 1, base = row_size; i < n_stage; ++i, base += row_size)
	{
        if (cval == 0)
            return;
		pos = MurmurHash3_x86_32((void*)&v, sizeof(int), rand_seed[i]) % row_size + base;
        if (fp[pos] == ckey) {
            cnt[pos] += cval;
            return;
        }
        else if (cnt[pos] < cval) {
            swap(cnt[pos], cval);
            swap(fp[pos], ckey);
        }
	}
}

int
HashPipe::query_freq(int v)
{
    int ans = 0;
	for (int i = 0, base = 0; i < n_stage; ++i, base += row_size)
	{
		int pos = MurmurHash3_x86_32((void*)&v, sizeof(int), rand_seed[i]) % row_size + base;
		if (fp[pos] == v)
            ans += cnt[pos];
	}
	return ans;
}

vector<PII>
HashPipe::query_heavyhitter(int threshold)
{
	vector<PII> ans;
    map<int, int> local_ans;

    for (int pos = 0; pos < size; ++pos) {
        if (cnt[pos] == 0)
            continue;
        if (local_ans.find(fp[pos]) == local_ans.end()) {
            local_ans[fp[pos]] = 0;
        }
        local_ans[fp[pos]] += cnt[pos];
    }
    for (auto &it: local_ans) {
        if (it.second >= threshold) {
            ans.push_back(make_pair(it.second, it.first));
        }
    }
	sort(ans.begin(), ans.end(), greater<PII>());

	return ans;
}


void
HashPipe::status()
{
	printf("total_bucket: %d   n_stage: %d\n", size, n_stage);
}
