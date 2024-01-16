#ifndef RS_HEADER
#define RS_HEADER

#include "sketch.h"
#include <set>
using std::set;


class ReliableSketch : public Sketch
{
public:
    struct Bucket {
        int yes_cnt, no_cnt, id;
        bool locked;
        Bucket() {
            yes_cnt = 0;
            no_cnt = 0;
            id = 0;
            locked = false;
        }
    };

    // mice filter params
    int mf_n_hash;
    int mf_row_size, mf_err_bound;
    int *mf;

    // ReliableSketch params
	int rs_level, rs_threshold_0;
    int rs_row_size[30], rs_err_bound[30];
    double rs_r_w, rs_r_l;
	Bucket *rs[30];

    // trivial metas
    int mf_num_bkt, rs_num_bkt;
    int mf_eps, rs_eps;
    double total_mem, mem_ratio;

    int out_of_control;
    int rand_base;
    int rand_mf[30], rand_rs[30];

	ReliableSketch(double total_mem, double mem_ratio,
              int rs_level, int rs_threshold, double rs_r_w, double rs_r_l,
              int mf_threshold, int mf_n_hash);
	~ReliableSketch();

    int get_rs_bkt_0_by_mem(double rs_mem);
    double get_rs_mem_by_bkt_0(int rs_bkt_0);
    void construct_rs(int rs_bkt_0);
    void construct_mf(int mf_bkt_0);

	void init();
	void insert(int v);
	void insert(int v, int f);
	int query_freq(int v);
	int query_freq_low(int v);
	int query_freq_level(int v);
	int query_hash(int v);
    vector<PII> query_heavyhitter(int threshold);
    
	void status();
    void print_mf_payload();
};

#endif