/* -*- P4_16 -*- */
//need to handle ARP
#include <core.p4>
#include <tna.p4>

#define cf_threshold 30
#define max_col_a 18
#define max_col_b 10
#define max_col_c 6
#define threshold_a 10
#define threshold_b 10
#define threshold_c 10
#define mt_a 28
#define mt_b 20
#define mt_c 16
//#define length_a 65536
//#define length_b 32768
//#define length_c 16384
#define length_a 65536
#define length_b 32768
#define length_c 16384
#define index_lena 16
#define index_lenb 15
#define index_lenc 14
/*************************************************************************
 ************* C O N S T A N T S    A N D   T Y P E S  *******************
*************************************************************************/
enum bit<16> ether_type_t {
    TPID       = 0x8100,
    IPV4       = 0x0800,
    ARP        = 0x0806,
    INFORM     = 0x1111
}

enum bit<8>  ip_proto_t {
    ICMP  = 1,
    IGMP  = 2,
    TCP   = 6,
    UDP   = 17
}
struct ID_collision {
    bit<32>  ID;
    bit<32>  collision;
}


type bit<48> mac_addr_t;

/*************************************************************************
 ***********************  H E A D E R S  *********************************
 *************************************************************************/
/*  Define all the headers the program will recognize             */
/*  The actual sets of headers processed by each gress can differ */

/* Standard ethernet header */
header ethernet_h {
    mac_addr_t    dst_addr;
    mac_addr_t    src_addr;
    ether_type_t  ether_type;
}
header inform_h
{
    bit<8> layer_id;
    bit<16> index;
}
header vlan_tag_h {
    bit<3>        pcp;
    bit<1>        cfi;
    bit<12>       vid;
    ether_type_t  ether_type;
}

header arp_h {
    bit<16>       htype;
    bit<16>       ptype;
    bit<8>        hlen;
    bit<8>        plen;
    bit<16>       opcode;
    mac_addr_t    hw_src_addr;
    bit<32>       proto_src_addr;
    mac_addr_t    hw_dst_addr;
    bit<32>       proto_dst_addr;
}

header ipv4_h {
    bit<4>       version;
    bit<4>       ihl;
    bit<7>       diffserv;
    bit<1>       res;
    bit<16>      total_len;
    bit<16>      identification;
    bit<3>       flags;
    bit<13>      frag_offset;
    bit<8>       ttl;
    bit<8>   protocol;
    bit<16>      hdr_checksum;
    bit<32>  src_addr;
    bit<32>  dst_addr;
}

header icmp_h {
    bit<16>  type_code;
    bit<16>  checksum;
}

header igmp_h {
    bit<16>  type_code;
    bit<16>  checksum;
}

header tcp_h {
    bit<16>  src_port;
    bit<16>  dst_port;
    bit<32>  seq_no;
    bit<32>  ack_no;
    bit<4>   data_offset;
    bit<4>   res;
    bit<8>   flags;
    bit<16>  window;
    bit<16>  checksum;
    bit<16>  urgent_ptr;
}

header udp_h {
    bit<16>  src_port;
    bit<16>  dst_port;
    bit<16>  len;
    bit<16>  checksum;
}
header ingress_mirror_header_t
{
    bit<48>    dst_addr;
    bit<48>    src_addr;
    bit<16>  ether_type;
    bit<8> layer_id;
    bit<16> index;
}
/*************************************************************************
 **************  I N G R E S S   P R O C E S S I N G   *******************
 *************************************************************************/

    /***********************  H E A D E R S  ************************/

struct my_ingress_headers_t {
    ethernet_h         ethernet;
    inform_h           inform;
    arp_h              arp;
    vlan_tag_h[2]      vlan_tag;
    ipv4_h             ipv4;
    icmp_h             icmp;
    igmp_h             igmp;
    tcp_h              tcp;
    udp_h              udp;
}


    /******  G L O B A L   I N G R E S S   M E T A D A T A  *********/


struct my_ingress_metadata_t {
    MirrorId_t session_id;
    ingress_mirror_header_t mirror_header;
    bit<32> ID;
    bit<32> total;
    bit<index_lena> index1;
    bit<index_lenb> index2;
    bit<index_lenc> index3;
    bit<32> collision;
    bit<1> locked;
}

    /***********************  P A R S E R  **************************/

parser IngressParser(packet_in        pkt,
    /* User */
    out my_ingress_headers_t          hdr,
    out my_ingress_metadata_t         meta,
    /* Intrinsic */
    out ingress_intrinsic_metadata_t  ig_intr_md)
{
    /* This is a mandatory state, required by Tofino Architecture */
    state start {
        pkt.extract(ig_intr_md);
        pkt.advance(PORT_METADATA_SIZE);
        transition meta_init;
    }

    state meta_init {
        meta.ID=0;
        meta.total=0;
        meta.index1=0;
        meta.index2=0;
        meta.index3=0;
        meta.collision=0;
        meta.locked=0;
        meta.session_id=0;
        transition parse_ethernet;
    }

    state parse_ethernet {
        pkt.extract(hdr.ethernet);
        /*
         * The explicit cast allows us to use ternary matching on
         * serializable enum
         */
        transition select((bit<16>)hdr.ethernet.ether_type) {
            (bit<16>)ether_type_t.TPID &&& 0xEFFF :  parse_vlan_tag;
            (bit<16>)ether_type_t.IPV4            :  parse_ipv4;
            (bit<16>)ether_type_t.ARP             :  parse_arp;
            (bit<16>)ether_type_t.INFORM          :  parse_inform;
            default :  accept;
        }
    }

    state parse_arp {
        pkt.extract(hdr.arp);
        transition accept;
    }
    state parse_inform {
        pkt.extract(hdr.inform);
        transition accept;
    }
    state parse_vlan_tag {
        pkt.extract(hdr.vlan_tag.next);
        transition select(hdr.vlan_tag.last.ether_type) {
            ether_type_t.TPID :  parse_vlan_tag;
            ether_type_t.IPV4 :  parse_ipv4;
            default: accept;
        }
    }

    state parse_ipv4 {
        pkt.extract(hdr.ipv4);
        transition select(hdr.ipv4.protocol) {
            1 : parse_icmp;
            2 : parse_igmp;
            6 : parse_tcp;
           17 : parse_udp;
            default : accept;
        }
    }


    state parse_icmp {

        pkt.extract(hdr.icmp);
        transition accept;
    }

    state parse_igmp {

        pkt.extract(hdr.igmp);
        transition accept;
    }

    state parse_tcp {

        pkt.extract(hdr.tcp);
        transition accept;
    }

    state parse_udp {

        pkt.extract(hdr.udp);
        transition accept;
    }


}
control Ingress(/* User */
    inout my_ingress_headers_t                       hdr,
    inout my_ingress_metadata_t                      meta,
    /* Intrinsic */
    in    ingress_intrinsic_metadata_t               ig_intr_md,
    in    ingress_intrinsic_metadata_from_parser_t   ig_prsr_md,
    inout ingress_intrinsic_metadata_for_deparser_t  ig_dprsr_md,
    inout ingress_intrinsic_metadata_for_tm_t        ig_tm_md)
{





//bit<32> errorcode=0;
bit<32> temp=0;
bit<index_lena> index_cf1=0;
bit<index_lena> index_cf2=0;
bit<1> flag_cf=0;
bit<1> flag_cf2=0;
    CRCPolynomial<bit<32>>(0xDB710641,false,false,false,32w0xFFFFFFFF,32w0xFFFFFFFF) crc321;
    CRCPolynomial<bit<32>>(0x82608EDB,false,false,false,32w0xFFFFFFFF,32w0xFFFFFFFF) crc322;
    CRCPolynomial<bit<32>>(0x04C11DB7,false,false,false,32w0xFFFFFFFF,32w0xFFFFFFFF) crc32a;
    CRCPolynomial<bit<32>>(0x741B8CD7,false,false,false,32w0xFFFFFFFF,32w0xFFFFFFFF) crc32b;
    CRCPolynomial<bit<32>>(0xDB710641,false,false,false,32w0xFFFFFFFF,32w0xFFFFFFFF) crc32c;
    //CRCPolynomial<bit<32>>(0x82608EDB,false,false,false,32w0xFFFFFFFF,32w0xFFFFFFFF) crc32fp;

    Hash<bit<index_lena>>(HashAlgorithm_t.CUSTOM,crc321) hash_cf1;
    Hash<bit<index_lena>>(HashAlgorithm_t.CUSTOM,crc322) hash_cf2;
    Hash<bit<index_lena>>(HashAlgorithm_t.CUSTOM,crc32a) hash_1;
    Hash<bit<index_lenb>>(HashAlgorithm_t.CUSTOM,crc32b) hash_2;
    Hash<bit<index_lenc>>(HashAlgorithm_t.CUSTOM,crc32c) hash_3;
    //Hash<bit<32>>(HashAlgorithm_t.CUSTOM,crc32fp) hash_ID;

Register<bit<8>, bit<32>>(length_a) filter_counter_a;
RegisterAction<bit<8>, bit<32>, bit<1>>(filter_counter_a) set_filter_counter_a=
    {
void apply(inout bit<8> register_data, out bit<1> result) {
            result=0;
            if(register_data==cf_threshold){
                result=1;
            } else {
                register_data = register_data + 2;
            }     
        }
    };
Register<bit<8>, bit<32>>(length_a) filter_counter_b;
RegisterAction<bit<8>, bit<32>, bit<1>>(filter_counter_b) set_filter_counter_b=
    {
void apply(inout bit<8> register_data, out bit<1> result) {
            result=0;
            if(register_data==cf_threshold){
                result=1;
            } else {
                register_data = register_data + 2;
            }
            
        }
    };


Register<bit<1>, bit<32>>(length_a) flag_bit_a;
RegisterAction<bit<1>, bit<32>, bit<1>>(flag_bit_a) set_flag_bit_a=
    {
void apply(inout bit<1> register_data) {
            register_data=1;
        }
    };
RegisterAction<bit<1>, bit<32>, bit<1>>(flag_bit_a) get_flag_bit_a=
    {
void apply(inout bit<1> register_data, out bit<1> result) {
            result=register_data;
        }
    };
Register<bit<1>, bit<32>>(length_b) flag_bit_b;
RegisterAction<bit<1>, bit<32>, bit<1>>(flag_bit_b) set_flag_bit_b=
    {
void apply(inout bit<1> register_data) {

            register_data=1;
        }
    };
RegisterAction<bit<1>, bit<32>, bit<1>>(flag_bit_b) get_flag_bit_b=
    {
void apply(inout bit<1> register_data, out bit<1> result) {
            result=register_data;
        }
    };
Register<bit<1>, bit<32>>(length_c) flag_bit_c;
RegisterAction<bit<1>, bit<32>, bit<1>>(flag_bit_c) set_flag_bit_c=
    {
void apply(inout bit<1> register_data) {

            register_data=1;
        }
    };
RegisterAction<bit<1>, bit<32>, bit<1>>(flag_bit_c) get_flag_bit_c=
    {
void apply(inout bit<1> register_data, out bit<1> result) {
            result=register_data;
        }
    };

Register<bit<32>, bit<32>>(length_c) out_c;
RegisterAction<bit<32>, bit<32>, bit<32>>(out_c) calc_out_c=
    {
void apply(inout bit<32> register_data) {
            register_data=register_data + 1;
        }
    };

Register<bit<32>, bit<32>>(1) temp_a;
RegisterAction<bit<32>, bit<32>, bit<32>>(temp_a) calc_temp_a=
    {
void apply(inout bit<32> register_data, out bit<32> result) {
            register_data=meta.total-threshold_a;
            result=register_data;
        }
    };
Register<bit<32>, bit<32>>(1) temp_b;
RegisterAction<bit<32>, bit<32>, bit<32>>(temp_b) calc_temp_b=
    {
void apply(inout bit<32> register_data, out bit<32> result) {
            register_data=meta.total-threshold_b;
            result=register_data;
        }
    };
Register<bit<32>, bit<32>>(1) temp_c;
RegisterAction<bit<32>, bit<32>, bit<32>>(temp_c) calc_temp_c=
    {
void apply(inout bit<32> register_data, out bit<32> result) {
            register_data=meta.total-threshold_c;
            result=register_data;
        }
    };

Register<bit<32>, bit<32>>(1) temp_counter;
RegisterAction<bit<32>, bit<32>, bit<32>>(temp_counter) calc_count=
    {
void apply(inout bit<32> register_data, out bit<32> result) {
            register_data=register_data+2;
            result=register_data;
        }
    };

Register<bit<32>, bit<32>>(length_a) total_counter_a;
RegisterAction<bit<32>, bit<32>, bit<32>>(total_counter_a) inc_total_counter_a=
    {
void apply(inout bit<32> register_data, out bit<32> result) {

            register_data=register_data+1;
            result=register_data;
        }
    };

Register<bit<32>, bit<32>>(length_b) total_counter_b;
RegisterAction<bit<32>, bit<32>, bit<32>>(total_counter_b) inc_total_counter_b=
    {
void apply(inout bit<32> register_data, out bit<32> result) {

            register_data=register_data+1;
            result=register_data;
        }
    };

Register<bit<32>, bit<32>>(length_c) total_counter_c;
RegisterAction<bit<32>, bit<32>, bit<32>>(total_counter_c) inc_total_counter_c=
    {
void apply(inout bit<32> register_data, out bit<32> result) {

            register_data=register_data+1;
            result=register_data;
        }
    };

Register<ID_collision, bit<32>>(length_a) ID_collision_counter_a;
RegisterAction<ID_collision, bit<32>, bit<32>>(ID_collision_counter_a) inc_ID_collision_counter_a=
    {
void apply(inout ID_collision register_data, out bit<32> result) {
        if (meta.total-register_data.collision<=0)
        {
            register_data.ID=meta.ID;
        }

        else if (meta.ID!=register_data.ID&&meta.total-register_data.collision>0)
        {
            register_data.collision=register_data.collision+2;
        }

        result=register_data.collision;
    }
    };
RegisterAction<ID_collision, bit<32>, bit<32>>(ID_collision_counter_a) inc_locked_ID_collision_counter_a=
    {
void apply(inout ID_collision register_data, out bit<32> result) {
        result=0;
        if (meta.ID==register_data.ID)
        {
            register_data.collision=register_data.collision+2;
            result=register_data.collision;
        }
    }
    };

Register<ID_collision, bit<32>>(length_b) ID_collision_counter_b;
RegisterAction<ID_collision, bit<32>, bit<32>>(ID_collision_counter_b) inc_ID_collision_counter_b=
    {
void apply(inout ID_collision register_data, out bit<32> result) {
        if (meta.total-register_data.collision<=0)
        {
            register_data.ID=meta.ID;
        }

        else if (meta.ID!=register_data.ID&&meta.total-register_data.collision>0)
        {
            register_data.collision=register_data.collision+2;
        }

        result=register_data.collision;
    }
    };
RegisterAction<ID_collision, bit<32>, bit<32>>(ID_collision_counter_b) inc_locked_ID_collision_counter_b=
    {
void apply(inout ID_collision register_data, out bit<32> result) {
        result=0;
        if (meta.ID==register_data.ID)
        {
            register_data.collision=register_data.collision+2;
            result=register_data.collision;
        }
    }
    };

Register<ID_collision, bit<32>>(length_b) ID_collision_counter_c;
RegisterAction<ID_collision, bit<32>, bit<32>>(ID_collision_counter_c) inc_ID_collision_counter_c=
    {
void apply(inout ID_collision register_data, out bit<32> result) {
        if (meta.total-register_data.collision<=0)
        {
            register_data.ID=meta.ID;
        }

        else if (meta.ID!=register_data.ID&&meta.total-register_data.collision>0)
        {
            register_data.collision=register_data.collision+2;
        }

        result=register_data.collision;
    }
    };
RegisterAction<ID_collision, bit<32>, bit<32>>(ID_collision_counter_c) inc_locked_ID_collision_counter_c=
    {
void apply(inout ID_collision register_data, out bit<32> result) {
        result=0;
        if (meta.ID==register_data.ID)
        {
            register_data.collision=register_data.collision+2;
            result=register_data.collision;
        }
    }
    };



    /* arp packets processing */
    action unicast_send(PortId_t port) {
        ig_tm_md.ucast_egress_port = port;
        ig_tm_md.bypass_egress=1;
    }
    action unicast_send_1() {
        ig_tm_md.ucast_egress_port = 160;
        ig_tm_md.bypass_egress=1;
    }
    action unicast_send_2() {
        ig_tm_md.ucast_egress_port = 128;
        ig_tm_md.bypass_egress=1;
    }
    action drop() {
        ig_dprsr_md.drop_ctl = 1;
    }
    @stage(0) table arp_host {
        key = { hdr.arp.proto_dst_addr : exact; }
        actions = { unicast_send; drop; }
        default_action = drop();
    }
    @stage(0) table ipv4_host {
        key = { hdr.ipv4.dst_addr : exact; }
        actions = { unicast_send; unicast_send_2; drop; }
        default_action = drop;
    }
    action cal_ID()
    {
        meta.ID=hdr.ipv4.src_addr;
    }
    @stage(0) table cal_ID_t {
        actions = { cal_ID; }
        default_action = cal_ID;
    }

    action cal_index_cf1()
    {
        index_cf1=hash_cf1.get(hdr.ipv4.src_addr);
    }
    @stage(0) table cal_index_cf1_t {
        actions = { cal_index_cf1; }
        default_action = cal_index_cf1;
    }

    action cal_index_cf2()
    {
        index_cf2=hash_cf2.get(hdr.ipv4.src_addr);
    }
    @stage(0) table cal_index_cf2_t {
        actions = { cal_index_cf2; }
        default_action = cal_index_cf2;
    }

    action set_filter_countera()
    {

        flag_cf=set_filter_counter_a.execute((bit<32>)index_cf1);
    }
    @stage(1) table set_filter_countera_t {
        actions = {set_filter_countera;}
        default_action = set_filter_countera;
    }

    action set_filter_counterb()
    {
        flag_cf2=set_filter_counter_b.execute((bit<32>)index_cf2);
    }
    @stage(1) table set_filter_counterb_t {
        actions = {set_filter_counterb;}
        default_action = set_filter_counterb;
    }



    action cal_index1()
    {
        meta.index1=hash_1.get(hdr.ipv4.src_addr);
    }
    @stage(0) table cal_index1_t {
        actions = { cal_index1; }
        default_action = cal_index1;
    }

    action cal_index2()
    {
        meta.index2=hash_2.get(hdr.ipv4.src_addr);
        //meta.index2=meta.index2 >> 1;
    }
    @stage(0) table cal_index2_t {
        actions = { cal_index2; }
        default_action = cal_index2;
    }

    action cal_index3()
    {
        meta.index3=hash_3.get(hdr.ipv4.src_addr);
        //meta.index3=meta.index3 >> 2;
    }
    @stage(0) table cal_index3_t {
        actions = { cal_index3; }
        default_action = cal_index3;
    }


    action get_flag_bit()
    {
        meta.locked=get_flag_bit_a.execute((bit<32>)meta.index1);
    }
    @stage(1) table get_flag_bit_t {
        actions = { get_flag_bit; }
        default_action = get_flag_bit;
    }
    action set_flag_bit()
    {
        set_flag_bit_a.execute((bit<32>)hdr.inform.index);
    }
    @stage(1) table set_flag_bit_t { // the called stage should be check
        actions = { set_flag_bit; }
        default_action = set_flag_bit;
    }

    action get_flag_bitb()
    {
        meta.locked=get_flag_bit_b.execute((bit<32>)meta.index2);
    }
    @stage(3) table get_flag_bitb_t {
        actions = { get_flag_bitb; }
        default_action = get_flag_bitb;
    }
    action set_flag_bitb()
    {
        set_flag_bit_b.execute((bit<32>)hdr.inform.index);
    }
    @stage(3) table set_flag_bitb_t {
        actions = { set_flag_bitb; }
        default_action = set_flag_bitb;
    }

    action get_flag_bitc()
    {
        meta.locked=get_flag_bit_c.execute((bit<32>)meta.index3);
    }
    @stage(5) table get_flag_bitc_t {
        actions = { get_flag_bitc; }
        default_action = get_flag_bitc;
    }
    action set_flag_bitc()
    {
        set_flag_bit_c.execute((bit<32>)hdr.inform.index);
    }
    @stage(5) table set_flag_bitc_t {
        actions = { set_flag_bitc; }
        default_action = set_flag_bitc;
    }

    action calc_tempa(){
        temp=calc_temp_a.execute(0);
    }
    @stage(4) table calc_tempa_t {
        actions = { calc_tempa; }
        default_action = calc_tempa;
    }
    action calc_tempb(){
        temp= calc_temp_b.execute(0);
    }
    @stage(6) table calc_tempb_t {
        actions = { calc_tempb; }
        default_action = calc_tempb;
    }
    action calc_tempc(){
        temp= calc_temp_c.execute(0);
    }
    @stage(8) table calc_tempc_t {
        actions = { calc_tempc; }
        default_action = calc_tempc;
    }

    action calc_co(){
        temp= calc_count.execute(0);
    }
    @stage(6) table calc_count_t {
        actions = { calc_co; }
        default_action = calc_co;
    }

    action inc_total_counter()
    {
        meta.total=inc_total_counter_a.execute((bit<32>)meta.index1);
    }
    @stage(2) table inc_total_counter_t {
        actions = { inc_total_counter; }
        default_action = inc_total_counter;
    }
    
    action inc_ID_collision_counter()
    {
        meta.collision=inc_ID_collision_counter_a.execute((bit<32>)meta.index1);
    }
    @stage(3) table inc_ID_collision_counter_t {
        actions = { inc_ID_collision_counter; }
        default_action = inc_ID_collision_counter;
    }
    action inc_locked_ID_collision_counter()
    {
        meta.collision=inc_locked_ID_collision_counter_a.execute((bit<32>)meta.index1);
    }
    @stage(3) table inc_locked_ID_collision_counter_t {
        actions = { inc_locked_ID_collision_counter; }
        default_action = inc_locked_ID_collision_counter;
    }

    action inc_total_counterb()
    {
        meta.total=inc_total_counter_b.execute((bit<32>)meta.index2);
    }
    @stage(4) table inc_total_counterb_t {
        actions = { inc_total_counterb; }
        default_action = inc_total_counterb;
    }
    action inc_ID_collision_counterb()
    {
        meta.collision=inc_ID_collision_counter_b.execute((bit<32>)meta.index2);
    }
    @stage(5) table inc_ID_collision_counterb_t {
        actions = { inc_ID_collision_counterb; }
        default_action = inc_ID_collision_counterb;
    }
    action inc_locked_ID_collision_counterb()
    {
        meta.collision=inc_locked_ID_collision_counter_b.execute((bit<32>)meta.index2);
    }
    @stage(5) table inc_locked_ID_collision_counterb_t {
        actions = { inc_locked_ID_collision_counterb; }
        default_action = inc_locked_ID_collision_counterb;
    }

    action inc_total_counterc()
    {
        meta.total=inc_total_counter_c.execute((bit<32>)meta.index3);
    }
    @stage(6) table inc_total_counterc_t {
        actions = { inc_total_counterc; }
        default_action = inc_total_counterc;
    }
    action inc_ID_collision_counterc()
    {
        meta.collision=inc_ID_collision_counter_c.execute((bit<32>)meta.index3);
    }
    @stage(7) table inc_ID_collision_counterc_t {
        actions = { inc_ID_collision_counterc; }
        default_action = inc_ID_collision_counterc;
    }
    action inc_locked_ID_collision_counterc()
    {
        meta.collision=inc_locked_ID_collision_counter_c.execute((bit<32>)meta.index3);
    }
    @stage(7) table inc_locked_ID_collision_counterc_t {
        actions = { inc_locked_ID_collision_counterc; }
        default_action = inc_locked_ID_collision_counterc;
    }


    action mirror_set()
    {
        meta.session_id=2;
        ig_dprsr_md.mirror_type=2;
        meta.mirror_header.layer_id=1;
        meta.mirror_header.index=(bit<16>)meta.index1;   
    }
    @stage(5) table mirror_set_t
    {
        key={meta.collision:exact;}
        actions={mirror_set;NoAction;}
        default_action=NoAction;
    }
    action mirror_set_b()
    {
        meta.session_id=2;
        ig_dprsr_md.mirror_type=2;
        meta.mirror_header.layer_id=2;
        meta.mirror_header.index=(bit<16>)meta.index2;
    }
    @stage(7) table mirror_setb_t
    {
        key={meta.collision:exact;}
        actions={mirror_set_b;NoAction;}
        default_action=NoAction;
    }
    action mirror_set_c()
    {
        meta.session_id=2;
        ig_dprsr_md.mirror_type=2;
        meta.mirror_header.layer_id=3;
        meta.mirror_header.index=(bit<16>)meta.index3;
    }
    @stage(9) table mirror_setc_t
    {
        key={meta.collision:exact;}
        actions={mirror_set_c;NoAction;}
        default_action=NoAction;
    }

    action calc_outc(){
        calc_out_c.execute((bit<32>)meta.index3);
    }
    @stage(8) table calc_outc_t
    {
        actions={calc_outc;}
        default_action=calc_outc;
    }

    action mirror_set_first()
    {
        meta.mirror_header.ether_type=0x1111;
        meta.mirror_header.dst_addr=0x1234;
        meta.mirror_header.src_addr=0x4321;
    }
    @stage(11) table mirror_setafter_t
    {
        key={meta.session_id:exact;}
        actions={mirror_set_first;NoAction;}
        default_action=NoAction;
    }

    action send_to_cup_a()
    {
        meta.session_id=3;
        ig_dprsr_md.mirror_type=2;//send();
    }
    @stage(5) table send_to_cupa_t
    {
        actions={send_to_cup_a;}
        default_action=send_to_cup_a;
    }
    action send_to_cup_b()
    {
        meta.session_id=3;
        ig_dprsr_md.mirror_type=2;//send();
    }
    @stage(7) table send_to_cupb_t
    {
        actions={send_to_cup_b;}
        default_action=send_to_cup_b;
    }
    action send_to_cup_c()
    {
        meta.session_id=3;
        ig_dprsr_md.mirror_type=2;//send();
    }
    @stage(9) table send_to_cupc_t
    {
        actions={send_to_cup_c;}
        default_action=send_to_cup_c;
    }

    @stage(4) table send_to_cup_locka_t
    {
        actions={send_to_cup_a;}
        default_action=send_to_cup_a;
    }
    @stage(6) table send_to_cup_lockb_t
    {
        actions={send_to_cup_b;}
        default_action=send_to_cup_b;
    }
    @stage(8) table send_to_cup_lockc_t
    {
        actions={send_to_cup_c;}
        default_action=send_to_cup_c;
    }

apply {
    if (hdr.arp.isValid())
    {
        arp_host.apply();
    }
    else if (hdr.ipv4.isValid())
    {
        ipv4_host.apply();
        //if (hdr.tcp.isValid())
        //{
            cal_ID_t.apply();
            cal_index1_t.apply(); //0
            cal_index2_t.apply(); //0
            cal_index3_t.apply(); //0
            cal_index_cf1_t.apply(); //0
            cal_index_cf2_t.apply(); //0
            get_flag_bit_t.apply(); //1
            set_filter_countera_t.apply();//1
            set_filter_counterb_t.apply();//1
            if(flag_cf==1){
                if(flag_cf2==1){
                    if (meta.locked==0)
                    {
                        inc_total_counter_t.apply();//2
                        inc_ID_collision_counter_t.apply(); //3
                        mirror_set_t.apply(); //4
                    }
                    else
                    {
                        inc_locked_ID_collision_counter_t.apply(); //3
                        get_flag_bitb_t.apply(); //3
                        if (meta.collision==0)
                        {
                            //insert into next layer;
                            if (meta.locked==0)
                            {
                                inc_total_counterb_t.apply(); //4
                                inc_ID_collision_counterb_t.apply(); //5
                                mirror_setb_t.apply(); //6
                            }
                            else
                            {
                                inc_locked_ID_collision_counterb_t.apply(); //5
                                get_flag_bitc_t.apply(); //5
                                if (meta.collision==0)
                                {
                                    if(meta.locked==0)
                                    {
                                        inc_total_counterc_t.apply(); //6
                                        inc_ID_collision_counterc_t.apply(); //7
                                        mirror_setc_t.apply(); //8
                                    } else {
                                        inc_locked_ID_collision_counterc_t.apply(); //7
                                        if (meta.collision==0) {
                                            calc_outc_t.apply(); //8
                                        }
                                    }
                                } 
                            }
                       } 
                    }
                    mirror_setafter_t.apply();//11
                }
            }
            
        //}
    }
    else if (hdr.inform.isValid())
    {
        if(hdr.inform.layer_id == 1){
            set_flag_bit_t.apply();
        }
        if(hdr.inform.layer_id == 2){
            set_flag_bitb_t.apply();
        }
        if(hdr.inform.layer_id == 3){
            set_flag_bitc_t.apply();
        }
        ig_dprsr_md.drop_ctl=1;
    }
    
    }

}
control IngressDeparser(packet_out pkt,
    /* User */
    inout my_ingress_headers_t                       hdr,
    in    my_ingress_metadata_t                      meta,
    /* Intrinsic */
    in    ingress_intrinsic_metadata_for_deparser_t  ig_dprsr_md)
{
        // Checksum() ipv4_checksum;


    Checksum() ipv4_checksum;
    Mirror() mirror;
    apply {
        if (hdr.ipv4.isValid()) {
            hdr.ipv4.hdr_checksum = ipv4_checksum.update({
                hdr.ipv4.version,
                hdr.ipv4.ihl,
                hdr.ipv4.diffserv,
                hdr.ipv4.res,
                hdr.ipv4.total_len,
                hdr.ipv4.identification,
                hdr.ipv4.flags,
                hdr.ipv4.frag_offset,
                hdr.ipv4.ttl,
                hdr.ipv4.protocol,
                hdr.ipv4.src_addr,
                hdr.ipv4.dst_addr
            });
        }
        if (ig_dprsr_md.mirror_type == 2)
        mirror.emit<ingress_mirror_header_t>(meta.session_id,meta.mirror_header);
        pkt.emit(hdr);

    }
}
/*************************************************************************
 ****************  E G R E S S   P R O C E S S I N G   *******************
 *************************************************************************/

    /***********************  H E A D E R S  ************************/


    struct my_egress_headers_t {

    ethernet_h         ethernet;
vlan_tag_h[2]       vlan_tag;
    ipv4_h          ipv4;

}



    /********  G L O B A L   E G R E S S   M E T A D A T A  *********/

struct my_egress_metadata_t {

}

    /***********************  P A R S E R  **************************/

parser EgressParser(packet_in        pkt,
    /* User */
    out my_egress_headers_t          hdr,
    out my_egress_metadata_t         meta,
    /* Intrinsic */
    out egress_intrinsic_metadata_t  eg_intr_md)
{
    /* This is a mandatory state, required by Tofino Architecture */
    state start {
        pkt.extract(eg_intr_md);
        transition accept;
    }
}

    /***************** M A T C H - A C T I O N  *********************/

control Egress(
    /* User */
    inout my_egress_headers_t                          hdr,
    inout my_egress_metadata_t                         meta,
    /* Intrinsic */
    in    egress_intrinsic_metadata_t                  eg_intr_md,
    in    egress_intrinsic_metadata_from_parser_t      eg_prsr_md,
    inout egress_intrinsic_metadata_for_deparser_t     eg_dprsr_md,
    inout egress_intrinsic_metadata_for_output_port_t  eg_oport_md)
{


    apply {

}
}



    /*********************  D E P A R S E R  ************************/

control EgressDeparser(packet_out pkt,
    /* User */
    inout my_egress_headers_t                       hdr,
    in    my_egress_metadata_t                      meta,
    /* Intrinsic */
    in    egress_intrinsic_metadata_for_deparser_t  eg_dprsr_md)
{



    apply {
          pkt.emit(hdr);
    }
}


/************ F I N A L   P A C K A G E ******************************/
Pipeline(
    IngressParser(),
    Ingress(),
    IngressDeparser(),
    EgressParser(),
    Egress(),
    EgressDeparser()
) pipe;

Switch(pipe) main;