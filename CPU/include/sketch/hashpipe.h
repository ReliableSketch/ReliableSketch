#ifndef HASHPIPE_HEADER
#define HASHPIPE_HEADER

#include "sketch.h"
#include <set>
using std::set;

#define mp make_pair
#define ft first
#define sc second

class HashPipe : public Sketch
{
private:
    int size, n_stage;
    int row_size;

    int *cnt, *fp;
    int *rand_seed;

public:
    HashPipe(double total_mem, int n_stage);
    ~HashPipe();
    void init();
    void insert(int v);
    int query_freq(int v);
    vector<PII> query_heavyhitter(int threshold);
    void status();  
};

#endif