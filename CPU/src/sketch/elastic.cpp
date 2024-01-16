#include <sketch/elastic.h>
#include <murmur3.h>
#include <utils.h>

#include <cstdio>
#include <cstring>
#include <cmath>
#include <climits>

#define ELASTIC_HASH_SEED 1
#define CM_HASH_SEED 2

#define GetCounterVal(val) ((uint32_t)((val) & 0x7FFFFFFF))
#define HIGHEST_BIT_IS_1(val) ((val) & 0x80000000)
#define JUDGE_IF_SWAP(min_val, guard_val) ((guard_val) > ((min_val) << 3))
#define UPDATE_GUARD_VAL(guard_val) ((guard_val) + 1)


ElasticSketch::ElasticSketch(double total_mem, double mem_ratio) :
total_mem(total_mem)
{
	sprintf(name, "ElasticSketch");

    heavy_mem = total_mem * mem_ratio;
    heavy_num_bkt = (int)(heavy_mem / COUNTER_PER_BUCKET / 8);  // 8 bytes per bucket
    heavy_mem = heavy_num_bkt * COUNTER_PER_BUCKET * 8;  //fix
    light_num_bkt = (int)(total_mem - heavy_mem);
    light_mem = light_num_bkt;
    total_mem = light_mem + heavy_mem;  // fix

	if (heavy_mem <= 0 || light_mem <= 0)
	{
		panic("MEM of both parts must be POSITIVE.");
	}

    heavy_part = new Bucket[heavy_num_bkt];
    light_part = new uint8_t[light_num_bkt];
}

ElasticSketch::~ElasticSketch()
{
    delete [] heavy_part;
    delete [] light_part;
}

void
ElasticSketch::init()
{
    memset(heavy_part, 0, heavy_num_bkt * sizeof(Bucket));
    memset(light_part, 0, light_num_bkt);
    out_of_control = 0;
}

void
ElasticSketch::insert(int v)
{
    uint32_t fp = v;
    int pos = MurmurHash3_x86_32((void*)&v, sizeof(int), ELASTIC_HASH_SEED) % heavy_num_bkt;
    int f = 1;

    /* find if there has matched bucket */
    int matched = -1, empty = -1, min_counter = 0;
    uint32_t min_counter_val = GetCounterVal(heavy_part[pos].val[0]);
    for(int i = 0; i < COUNTER_PER_BUCKET - 1; i++){
        if(heavy_part[pos].key[i] == fp){
            matched = i;
            break;
        }
        if(heavy_part[pos].key[i] == 0 && empty == -1)
            empty = i;
        if(min_counter_val > GetCounterVal(heavy_part[pos].val[i])){
            min_counter = i;
            min_counter_val = GetCounterVal(heavy_part[pos].val[i]);
        }
    }

    /* if matched */
    if(matched != -1){
        heavy_part[pos].val[matched] += f;
        return;
    }

    /* if there has empty bucket */
    if(empty != -1){
        heavy_part[pos].key[empty] = fp;
        heavy_part[pos].val[empty] = f;
        return;
    }

    /* update guard val and comparison */
    uint32_t guard_val = heavy_part[pos].val[MAX_VALID_COUNTER];
    guard_val = UPDATE_GUARD_VAL(guard_val);

    if(!JUDGE_IF_SWAP(GetCounterVal(min_counter_val), guard_val)) {
        heavy_part[pos].val[MAX_VALID_COUNTER] = guard_val;
        insert_light(v, 1, false);
    }
    else {
        uint32_t swap_key = heavy_part[pos].key[min_counter];
        uint32_t swap_val = heavy_part[pos].val[min_counter];

        heavy_part[pos].val[MAX_VALID_COUNTER] = 0;
        heavy_part[pos].key[min_counter] = fp;
        heavy_part[pos].val[min_counter] = 0x80000001;

        insert_light(swap_key, GetCounterVal(swap_val), HIGHEST_BIT_IS_1(swap_val));
    }
}

void
ElasticSketch::insert_light(int v, int f, bool is_swap)
{
    int pos = MurmurHash3_x86_32((void*)&v, sizeof(int), CM_HASH_SEED) % light_num_bkt;

    /* add directly */
    if (!is_swap) {
        if ((int)light_part[pos] + f > 255)
            out_of_control++;
        light_part[pos] = min((int)light_part[pos] + f, 255);
    }
    else if (light_part[pos] < f) {
        if (f > 255)
            out_of_control++;
        light_part[pos] = min(f, 255);
    }
}

int
ElasticSketch::query_freq(int v)
{
    uint32_t fp = v;
    int pos = MurmurHash3_x86_32((void*)&v, sizeof(int), ELASTIC_HASH_SEED) % heavy_num_bkt;

    for(int i = 0; i < COUNTER_PER_BUCKET - 1; i++) {
        if(heavy_part[pos].key[i] == fp) {
            uint32_t res = heavy_part[pos].val[i];
            if (HIGHEST_BIT_IS_1(res))
                return GetCounterVal(res) + query_freq_light(v);
            else
                return GetCounterVal(res);
        }
    }
    return query_freq_light(v);
}

int
ElasticSketch::query_freq_light(int v)
{
    int pos = MurmurHash3_x86_32((void*)&v, sizeof(int), CM_HASH_SEED) % light_num_bkt;
    return light_part[pos];
}

vector<PII>
ElasticSketch::query_heavyhitter(int threshold)
{
	vector<PII> ans;
    ans.clear();
    for (int i = 0; i < heavy_num_bkt; ++i) 
        for (int j = 0; j < MAX_VALID_COUNTER; ++j) 
        {
            uint32_t key = heavy_part[i].key[j];
            int val = query_freq(key);
            if (val >= threshold)
                ans.push_back(mp(val, (int)key));
        }
    return ans;
}

void
ElasticSketch::status()
{
    printf("total mem: %.2lfKB  (heavy: %.2lfKB, light: %.2lfKB)\n", total_mem/1024, heavy_mem/1024, light_mem/1024);
	printf("heavy bucket: %d   light bucket: %d\n", heavy_num_bkt, light_num_bkt);
}
