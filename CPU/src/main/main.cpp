#include <murmur3.h>
#include <utils.h>
#include <sketch/cm.h>
#include <sketch/cu.h>
#include <sketch/ss.h>
#include <sketch/rs.h>
#include <sketch/elastic.h>
#include <sketch/coco.h>
#include <sketch/hashpipe.h>
#include <sketch/precision.h>

#include <string.h>
#include <fstream>
#include <sstream>
#include <iostream>
#include <vector>
#include <map>
#include <cmath>
#include <algorithm>
#include <stdint.h>
using namespace std;

#define ft first
#define sc second

vector<int> flow;  // global flow
string log_file;  // log file
fstream fout;  // global fout stream


// #include <boost/program_options.hpp>
// using namespace boost::program_options;

// void ParseArg(int argc, char *argv[])
// {
//     options_description oprs("Benchmark Options");

//     oprs.add_options()
// /*      ("verbose,v", "print more info")
//         ("debug,d", "print debug info")
//         ("filename,f", value<string>()->required(), "file dir")*/
//         ("help,h", "print help info")
//         ;
//     variables_map vm;
    
//     store(parse_command_line(argc, argv, oprs), vm);

//     if(vm.count("help"))
//     {
//         cout << oprs << endl;
//         return;
//     }
// }


/*
Load IP_TRACE dataset
*/
void LoadData_IP_TRACE(char file[], int flow_size)
{
    // hash_id.initialize(0);
    int rand_base = RandUint32() % 10000;
    
    ifstream is(file, ios::in | ios::binary);
    char buf[2000] = {0};

    for (int i = 1; i <= flow_size; i++)
    {
        if(!is.read(buf, 21))
        {
            // panic("Data Loading Error.\n");
            break;
        }
        flow.push_back(MurmurHash3_x86_32((void*)buf, 8, rand_base));
        // for (int i = 3; i >= 0; i++)
        //     printf("%d:", (int)(unsigned char)buf[i]);
        // printf("\n");
    }

    cout << "Loading complete. flow_size: " << flow_size << endl;
}


/*
Load Web Stream dataset
*/
void LoadData_Web_Stream(char file[], int flow_size)
{
    int rand_base = RandUint32() % 10000;
    
    ifstream is(file, ios::in | ios::binary);
    char buf[2000] = {0};

    for (int i = 1; i <= flow_size; i++)
    {
        if(!is.read(buf, 13))
        {
            // panic("Data Loading Error.\n");
            break;
        }
        flow.push_back(MurmurHash3_x86_32((void*)buf, 4, rand_base));
    }

    cout << "Loading complete. flow_size: " << flow.size() << endl;
}


/*
Load IMC dataset
*/
void LoadData_IMC(char file[], int flow_size)
{
    int rand_base = RandUint32() % 10000;
    
    ifstream is(file, ios::in | ios::binary);
    char buf[2000] = {0};

    for (int i = 1; i <= flow_size; i++)
    {
        if(!is.read(buf, 13))
        {
            // panic("Data Loading Error.\n");
            break;
        }
        flow.push_back(MurmurHash3_x86_32((void*)buf, 8, rand_base));
    }

    cout << "Loading complete. flow_size: " << flow.size() << endl;
}


/*
Load Synthesis dataset
*/
void LoadData_Synthesis(char file[], int flow_size)
{
    int rand_base = RandUint32() % 10000;
    
    ifstream is(file, ios::in | ios::binary);
    char buf[2000] = {0};

    for (int i = 1; i <= flow_size; i++)
    {
        if(!is.read(buf, 4))
        {
            cout << "Data Loading Error." << endl;
            break;
        }
        flow.push_back(MurmurHash3_x86_32((void*)buf, 4, rand_base));
    }

    cout << "Loading complete. flow_size: " << flow.size() << endl;
}


/*
MPETest, several metrics(ARE, AAE, PR, overeps...)

sk: condidate sketches
flow: test trace
k: conduct resulrs only by top k flows
eps: user-defined threshold
init_first: init all sketches before insertion
*/
int MPETest(vector<Sketch*>& sk, vector<int>& flow, int k, int eps, bool init_first = true)
{
    static map<int, int> flow_cnt;
    int n = flow.size(), n_sk = sk.size();
    // ============== INSERTION ==============
    // groundtruth
    flow_cnt.clear();
    for (int i = 0; i < n; ++i)
        flow_cnt[ flow[i] ] = 0;
    for (int i = 0; i < n; ++i)
        flow_cnt[ flow[i] ]++;

    // sketch insertion
    for (int id = 0; id < n_sk; ++id)
    {
        if (init_first)
            sk[id]->init();
        for (int i = 0; i < n; ++i)
            sk[id]->insert(flow[i]);
    }

    // ============== PREPROCESS ==============
    static vector<PII> res;
    res.clear();
    map<int, int>::iterator it = flow_cnt.begin();
    while (it != flow_cnt.end())
    {
        res.push_back(mp((*it).sc, (*it).ft));
        it++;
    }
    // get total pkt num
    int sum = 0;
    it = flow_cnt.begin();
    while (it != flow_cnt.end())
    {
        sum += (*it).sc;
        it++;
    }
    // sort flow by their sizes
    sort(res.begin(), res.end(), greater<PII>());


    // ============== QUERY & SUMMARY ==============
    printf("\n\nMPE Test (based on Top %d), unique flow: %d, biggest flow: %d, total packers: %d\n", k, flow_cnt.size(), res[0].ft, sum);
    printf("-------------------------------------\n");
    int sz = min(k, (int)res.size());
    // for (int i = 0; i < sz; ++i)
    // {
    //     // mouse flows are not counted
    //     if (res[i].ft < 10)
    //     {
    //         sz = i;
    //         break;
    //     }
    // }
    // printf(">=10: %d\n", sz);
    for (int id = 0; id < n_sk; ++id)
    {
        printf("===== [%d] %s =====\n", id, sk[id]->name);

        int max_it = 0;
        double avg_it = 0.;
        double lvl_dis[101];
        double are = 0., aae = 0., pr = 0.;
        double it_div_ae = 0.;
        double over_est = 0., under_est = 0.;
        double over_eps = 0;

        // special summary for us
        if (strcmp(sk[id]->name, "ReliableSketch") == 0)
        {
            memset(lvl_dis, 0, sizeof(lvl_dis));
            for (int i = 0; i < sz; ++i)
            {
                int high = sk[id]->query_freq(res[i].sc);
                int low = sk[id]->query_freq_low(res[i].sc);
                int lvl = ((ReliableSketch*)sk[id])->query_freq_level(res[i].sc);
                max_it = max(max_it, high - low);
                avg_it += high - low;
                lvl_dis[lvl+1] += 1;

                int err = abs(high - res[i].ft);
                are += (double)err / res[i].ft;
                aae += (double)err;
                pr += (high == res[i].ft);
                over_eps += (err > eps);
                it_div_ae += (double)(high - low + 1) / (err + 1);
                if (high > res[i].ft)
                    over_est += 1;
                else if (high < res[i].ft)
                    under_est += 1;
            }
        }
        else
        {
            for (int i = 0; i < sz; ++i)
            {
                int high = sk[id]->query_freq(res[i].sc);
                // int low = sk[id]->query_freq_low(res[i].sc);
                int low = 0;
                max_it = max(max_it, high - low);
                avg_it += high - low;

                int err = abs(high - res[i].ft);
                are += (double)err / res[i].ft;
                aae += (double)err;
                pr += (high == res[i].ft);
                over_eps += (err > eps);
                if (high > res[i].ft)
                    over_est += 1;
                else if (high < res[i].ft)
                    under_est += 1;
            }
        }

        sk[id]->status();
        // print level distr for RS
        if (strcmp(sk[id]->name, "ReliableSketch") == 0)
        {
            ((ReliableSketch*)sk[id])->print_mf_payload();
            int level = ((ReliableSketch*)sk[id])->rs_level;
            printf("Lvl Distr.: filtered: %.3lf  [  ", lvl_dis[100]/sz);
            for (int j = 1; j <= level; ++j)
                printf("%.3lf(%d)  ", lvl_dis[j]/sz, (int)lvl_dis[j]);
            printf("]  conflicting: %.3lf  not recorded: %.3lf(%d)\n", lvl_dis[0]/sz, lvl_dis[level+1]/sz, (int)lvl_dis[level+1]);
        }
        printf("** acc result **\n");
        printf("Pr: %.3lf  ARE: %1.3lf(%.3lf)  AAE: %1.3lf(%.3lf)  OverEps: %1.3lf(%d)\n", pr/sz, are/sz, log10(are/sz), aae/sz, log10(aae/sz), over_eps/sz, (int)over_eps);
        printf("Avg. Range: %.3lf  Max Range: %d  Avg. Range/Error:  %.3lf\n", avg_it/sz, max_it, it_div_ae/sz);
        printf("OverEst: %.3lf(%d)  UnderEst: %.3lf(%d)\n", over_est/sz, (int)over_est, under_est/sz, (int)under_est);
    }
    return 0;
}

int main(int argc, char *argv[])
{
    srand(time(0));
    // srand(2020);
    // parse args
    // ParseArg(argc, argv);

    int flow_size = 1e7;
    // ============= LOAD DATA =============
    // LoadData_IP_TRACE("data/130000.dat", flow_size);
    LoadData_Web_Stream("data/webdocs_form00.dat", flow_size);
    // LoadData_IMC("data/fin.dat", flow_size);
    // flow_size = 1e8; LoadData_Synthesis("../topk/data/030.dat", flow_size); flow_size = flow.size();
    // flow_size = 1e8; LoadData_Synthesis("../topk/data/003.dat", flow_size); flow_size = flow.size();

    // ============= TEST =============
    // default configs for ReliableSketch
    int eps = 25;
    int mf_n_hash = 2;
    double rs_r_l = 2.5, rs_r_w = 2.;
    int rs_level = 20;
    int mf_threshold = 3;
    double mem_ratio = 0.2;

    for (int i = 1; i <= 20; i++)
    {
        // memory - KB
        double mem_kb = i*200;
        double mem_bytes = mem_kb * 1024;
        printf("\n\nMemory Consumption: %.2lf KB\n", mem_kb);

        // ** dynamic threshold setting (average error test) **
        // double N = flow_size;
        // double W = (double)mem_kb * 1024;
        // eps = (int) (N * (rs_r_w*rs_r_l) * (rs_r_w*rs_r_l) / W / (rs_r_w-1) * (rs_r_l-1));
        // printf("RS eps = %d\n", eps);
        // if (eps < 5)
        // {
        //     mem_ratio = 0;
        //     mf_threshold = 0;
        // }

        vector<Sketch*> sk;
        ReliableSketch *rs = new ReliableSketch(mem_bytes, mem_ratio,
                                                rs_level, eps - mf_threshold, rs_r_w, rs_r_l,
                                                mf_threshold, mf_n_hash);
        CMSketch *cms = new CMSketch(mem_bytes, 3); strcpy(cms->name, "CM Sketch (fast)");
        CUSketch *cus = new CUSketch(mem_bytes, 3); strcpy(cus->name, "CU Sketch (fast)");
        SpaceSaving *ss = new SpaceSaving(mem_bytes);
        ElasticSketch *elastic = new ElasticSketch(mem_bytes, 0.25);
        CocoSketch *coco = new CocoSketch(mem_bytes, 2);
        HashPipe *hashpipe = new HashPipe(mem_bytes, 6);
        PRECISION *precision = new PRECISION(mem_bytes, 3);
        // CM CU accurate ver.
        CMSketch *cms_acc = new CMSketch(mem_bytes, 16); strcpy(cms_acc->name, "CM Sketch (accurate)");
        CUSketch *cus_acc = new CUSketch(mem_bytes, 16); strcpy(cus_acc->name, "CU Sketch (accurate)");
        // push candidate sketches
        sk.clear();
        sk.push_back(rs);
        sk.push_back(cms);
        sk.push_back(cus);
        sk.push_back(ss);
        sk.push_back(cms_acc);
        sk.push_back(cus_acc);
        sk.push_back(elastic);
        sk.push_back(coco);
        sk.push_back(hashpipe);
        sk.push_back(precision);
        MPETest(sk, flow, flow_size, eps, true);
        delete rs;
        delete cms;
        delete cus;
        delete ss;
        delete cms_acc;
        delete cus_acc;
        delete elastic;
        delete coco;
        delete hashpipe;
        delete precision;
    }

    return 0;
}
