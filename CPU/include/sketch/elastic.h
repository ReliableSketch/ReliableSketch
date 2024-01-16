#ifndef ELASTIC_HEADER
#define ELASTIC_HEADER

#include "sketch.h"

#define COUNTER_PER_BUCKET 8
#define MAX_VALID_COUNTER 7

class ElasticSketch : public Sketch
{
private:
    struct Bucket
    {
        uint32_t key[COUNTER_PER_BUCKET];
        uint32_t val[COUNTER_PER_BUCKET];
    };

    Bucket *heavy_part;
    // simple CM
    uint8_t *light_part;

    int heavy_num_bkt, light_num_bkt;
    double total_mem, heavy_mem, light_mem;

public:
    int out_of_control;

    ElasticSketch(double total_mem, double mem_ratio);
    ~ElasticSketch();
    void init();
    void insert(int v);
    void insert_light(int v, int f, bool is_swap = false);
    int query_freq(int v);
    int query_freq_light(int v);
    vector<PII> query_heavyhitter(int threshold);
    void status();  
};

#endif