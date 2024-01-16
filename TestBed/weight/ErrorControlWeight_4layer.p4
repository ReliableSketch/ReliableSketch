/* -*- P4_16 -*- */
//need to handle ARP
#include <core.p4>
#include <tna.p4>

#define threshold_a 10
#define threshold_b 10
#define threshold_c 10
#define cf_threshold 23000 //assume average packet length 200, 30*200=6000
#define max_col_a 19000   
#define max_col_b 15000   
#define max_col_c 11000
#define max_col_d 7000
#define mt_a 28
#define mt_b 20
#define mt_c 16
#define length_a 65536
#define length_b 32768
#define length_c 16384
#define length_d 8192
#define index_lena 16
#define index_lenb 15
#define index_lenc 14
#define index_lend 13
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
struct ID_yes_no {
    bit<32>  ID;
    bit<32>  yes_no;
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
header sketch_h{
    bit<32> sketch_value; 
    //bit<8> output;

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
    sketch_h           sketch;
}


    /******  G L O B A L   I N G R E S S   M E T A D A T A  *********/


struct my_ingress_metadata_t {
    MirrorId_t session_id;
    ingress_mirror_header_t mirror_header;
    bit<32> ID;
    bit<32> output_ID;
    bit<32> yes_no;
    bit<index_lena> index1;
    bit<index_lenb> index2;
    bit<index_lenc> index3;
    bit<index_lend> index4;
    bit<16> pktlen;
    bit<16> collision;  //filter_value here
    bit<1> locked1;
    bit<1> locked2;
    bit<1> constant;
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
        meta.output_ID=0;
        meta.yes_no=0;
        meta.index1=0;
        meta.index2=0;
        meta.index3=0;
        meta.index4=0;
        meta.collision=0;
        meta.locked1=0;
        meta.locked2=0;
        meta.constant=0;
        meta.session_id=0;
        hdr.sketch.setValid();
        hdr.sketch.sketch_value=0;
        //hdr.sketch.output=0;
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
        meta.pktlen=hdr.ipv4.total_len;
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
bit<index_lena> index_cf1=0;
bit<index_lena> index_cf2=0;
bit<16> flag_cf=1;
bit<16> flag_cf2=1;
    CRCPolynomial<bit<32>>(0xDB710641,false,false,false,32w0xFFFFFFFF,32w0xFFFFFFFF) crc321;
    CRCPolynomial<bit<32>>(0x82608EDB,false,false,false,32w0xFFFFFFFF,32w0xFFFFFFFF) crc322;
    CRCPolynomial<bit<32>>(0x04C11DB7,false,false,false,32w0xFFFFFFFF,32w0xFFFFFFFF) crc32a;
    CRCPolynomial<bit<32>>(0xEDB88320,false,false,false,32w0xFFFFFFFF,32w0xFFFFFFFF) crc32b;
    CRCPolynomial<bit<32>>(0xBA0DC66B,false,false,false,32w0xFFFFFFFF,32w0xFFFFFFFF) crc32c;
    CRCPolynomial<bit<32>>(0x992C1A4C,false,false,false,32w0xFFFFFFFF,32w0xFFFFFFFF) crc32d;

    Hash<bit<index_lena>>(HashAlgorithm_t.CUSTOM,crc321) hash_cf1;
    Hash<bit<index_lena>>(HashAlgorithm_t.CUSTOM,crc322) hash_cf2;
    Hash<bit<index_lena>>(HashAlgorithm_t.CUSTOM,crc32a) hash_1;
    Hash<bit<index_lenb>>(HashAlgorithm_t.CUSTOM,crc32b) hash_2;
    Hash<bit<index_lenc>>(HashAlgorithm_t.CUSTOM,crc32c) hash_3;
    Hash<bit<index_lend>>(HashAlgorithm_t.CUSTOM,crc32d) hash_4;

Register<bit<16>, bit<32>>(length_a) filter_counter_a;
RegisterAction<bit<16>, bit<32>, bit<16>>(filter_counter_a) set_filter_counter_a=
    {
void apply(inout bit<16> register_data, out bit<16> result) {
            if(register_data<cf_threshold){
                register_data = register_data + meta.pktlen;
                result=register_data-cf_threshold;
            }
        }
    };
Register<bit<16>, bit<32>>(length_a) filter_counter_b;
RegisterAction<bit<16>, bit<32>, bit<16>>(filter_counter_b) set_filter_counter_b=
    {
void apply(inout bit<16> register_data, out bit<16> result) {
            if(register_data<cf_threshold){
                register_data = register_data + meta.pktlen;
                result=register_data-cf_threshold;
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


Register<bit<1>, bit<32>>(length_d) flag_bit_d;
RegisterAction<bit<1>, bit<32>, bit<1>>(flag_bit_d) set_flag_bit_d=
    {
void apply(inout bit<1> register_data) {

            register_data=1;
        }
    };
RegisterAction<bit<1>, bit<32>, bit<1>>(flag_bit_d) get_flag_bit_d=
    {
void apply(inout bit<1> register_data, out bit<1> result) {
            result=register_data;
        }
    };




Register<bit<32>, bit<32>>(length_d) out_d;
RegisterAction<bit<32>, bit<32>, bit<32>>(out_d) calc_out_d=
    {
void apply(inout bit<32> register_data, out bit<32> result){
        register_data=register_data+ (bit<32>)meta.pktlen;
        result = register_data;
        }
    };

Register<ID_yes_no, bit<32>>(length_a) yes_no_counter_a;
RegisterAction<ID_yes_no, bit<32>, bit<32>>(yes_no_counter_a) adj_yes_no_counter_a=
    {
void apply(inout ID_yes_no register_data, out bit<32> result) {
        if(meta.ID!=register_data.ID && register_data.yes_no==0){
            register_data.ID=meta.ID;
            
        }
        if(meta.ID!=register_data.ID && register_data.yes_no != 0){
            register_data.yes_no=register_data.yes_no |-| (bit<32>)meta.pktlen;
        }else{
            register_data.yes_no=register_data.yes_no+(bit<32>)meta.pktlen;
            result=register_data.yes_no;
        }
        }
    };

RegisterAction<ID_yes_no, bit<32>, bit<32>>(yes_no_counter_a) inc_locked_ID_yes_no_counter_a=
    {
void apply(inout ID_yes_no register_data, out bit<32> result) {
        result=0;
        if (meta.ID==register_data.ID)
        {
            register_data.yes_no=register_data.yes_no+(bit<32>)meta.pktlen;
            result=register_data.yes_no;
        }
    }
    };


Register<bit<32>, bit<32>>(length_a) collision_counter_a;
RegisterAction<bit<32>, bit<32>, bit<32>>(collision_counter_a) inc_collision_counter_a=
    {
void apply(inout bit<32> register_data, out bit<32> result) {
        result=0;
        register_data=register_data + (bit<32>)meta.pktlen;
        // after register_data exceeds threshold, register_data is quickly locked.
        if (register_data>=max_col_a)
        {
            result=register_data-max_col_a;
        }
    }
    };



Register<ID_yes_no, bit<32>>(length_b) yes_no_counter_b;
RegisterAction<ID_yes_no, bit<32>, bit<32>>(yes_no_counter_b) adj_yes_no_counter_b=
    {
void apply(inout ID_yes_no register_data, out bit<32> result) {
        if(meta.ID!=register_data.ID && register_data.yes_no==0){
            register_data.ID=meta.ID;
            
        }
        if(meta.ID!=register_data.ID && register_data.yes_no != 0){
            register_data.yes_no=register_data.yes_no |-| (bit<32>)meta.pktlen;
        }else{
            register_data.yes_no=register_data.yes_no+ (bit<32>)meta.pktlen;
            result=register_data.yes_no;
        }
        }
    };

RegisterAction<ID_yes_no, bit<32>, bit<32>>(yes_no_counter_b) inc_locked_ID_yes_no_counter_b=
    {
void apply(inout ID_yes_no register_data, out bit<32> result) {
        result=0;
        if (meta.ID==register_data.ID)
        {
            register_data.yes_no=register_data.yes_no+(bit<32>)meta.pktlen;
            result=register_data.yes_no;
        }
    }
    };


Register<bit<32>, bit<32>>(length_b) collision_counter_b;
RegisterAction<bit<32>, bit<32>, bit<32>>(collision_counter_b) inc_collision_counter_b=
    {
void apply(inout bit<32> register_data, out bit<32> result) {
        result=0;
        register_data=register_data + (bit<32>)meta.pktlen;
        if (register_data>=max_col_b)
        {
            result=register_data-max_col_b;
        }
    }
    };




Register<ID_yes_no, bit<32>>(length_c) yes_no_counter_c;
RegisterAction<ID_yes_no, bit<32>, bit<32>>(yes_no_counter_c) adj_yes_no_counter_c=
    {
void apply(inout ID_yes_no register_data, out bit<32> result) {
        if(meta.ID!=register_data.ID && register_data.yes_no==0){
            register_data.ID=meta.ID;
            
        }
        if(meta.ID!=register_data.ID && register_data.yes_no != 0){
            register_data.yes_no=register_data.yes_no |-| (bit<32>)meta.pktlen;
        }else{
            register_data.yes_no=register_data.yes_no+ (bit<32>)meta.pktlen;
            result=register_data.yes_no;
        }
        }
    };

RegisterAction<ID_yes_no, bit<32>, bit<32>>(yes_no_counter_c) inc_locked_ID_yes_no_counter_c=
    {
void apply(inout ID_yes_no register_data, out bit<32> result) {
        result=0;
        if (meta.ID==register_data.ID)
        {
            register_data.yes_no=register_data.yes_no+ (bit<32>)meta.pktlen;
            result=register_data.yes_no;
        }
    }
    };


Register<bit<32>, bit<32>>(length_c) collision_counter_c;
RegisterAction<bit<32>, bit<32>, bit<32>>(collision_counter_c) inc_collision_counter_c=
    {
void apply(inout bit<32> register_data, out bit<32> result) {
        result=0;
        register_data=register_data+ (bit<32>)meta.pktlen;
        if (register_data>=max_col_c)
        {
            result=register_data-max_col_c;
        }
    }
    };



Register<ID_yes_no, bit<32>>(length_d) yes_no_counter_d;
RegisterAction<ID_yes_no, bit<32>, bit<32>>(yes_no_counter_d) adj_yes_no_counter_d=
    {
void apply(inout ID_yes_no register_data, out bit<32> result) {
        if(meta.ID!=register_data.ID && register_data.yes_no==0){
            register_data.ID=meta.ID;
            
        }
        if(meta.ID!=register_data.ID && register_data.yes_no != 0){
            register_data.yes_no=register_data.yes_no |-| (bit<32>)meta.pktlen;
        }else{
            register_data.yes_no=register_data.yes_no+ (bit<32>)meta.pktlen;
            result=register_data.yes_no;
        }
        }
    };

RegisterAction<ID_yes_no, bit<32>, bit<32>>(yes_no_counter_d) inc_locked_ID_yes_no_counter_d=
    {
void apply(inout ID_yes_no register_data, out bit<32> result) {
        result=0;
        if (meta.ID==register_data.ID)
        {
            register_data.yes_no=register_data.yes_no+ (bit<32>)meta.pktlen;
            result=register_data.yes_no;
        }
    }
    };


Register<bit<32>, bit<32>>(length_d) collision_counter_d;
RegisterAction<bit<32>, bit<32>, bit<32>>(collision_counter_d) inc_collision_counter_d=
    {
void apply(inout bit<32> register_data, out bit<32> result) {
        result=0;
        register_data=register_data+ (bit<32>)meta.pktlen;
        if (register_data>=max_col_c)
        {
            result=register_data-max_col_d;
        }
    }
    };





DirectCounter<bit<64>>(CounterType_t.PACKETS) mirror_stats;
DirectCounter<bit<64>>(CounterType_t.PACKETS) filter_stats;
//DirectCounter<bit<64>>(CounterType_t.PACKETS) flag_stats;
DirectCounter<bit<64>>(CounterType_t.PACKETS) mirror_set_after_stats;



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
     table arp_host {
        key = { hdr.arp.proto_dst_addr : exact; }
        actions = { unicast_send; drop; }
        default_action = drop();
    }
     table ipv4_host {
        //key = { hdr.ipv4.dst_addr : exact; }
        actions = { unicast_send; unicast_send_2; drop; }
        default_action = unicast_send(128);
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
        filter_stats.count();
        //flag_cf=set_filter_counter_a.execute(0);
    }
    @stage(1) table set_filter_countera_t {
        key = {meta.constant:exact;}
        actions = {@defaultonly NoAction;set_filter_countera;}
        counters= filter_stats;
        default_action = NoAction;
    }

    action set_filter_counterb()
    {
        flag_cf2=set_filter_counter_b.execute((bit<32>)index_cf2);
        //flag_cf2=set_filter_counter_b.execute(0);
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

    action cal_index4()
    {
        meta.index4=hash_4.get(hdr.ipv4.src_addr);
        //meta.index3=meta.index3 >> 2;
    }
    @stage(0) table cal_index4_t {
        actions = { cal_index4; }
        default_action = cal_index4;
    }

    action get_flag_bit()
    {
        //meta.locked1=get_flag_bit_a.execute(0);
        meta.locked1=get_flag_bit_a.execute((bit<32>)meta.index1);
    }
     table get_flag_bit_t {
        actions = { get_flag_bit; }
        default_action = get_flag_bit;
    }
    action set_flag_bit()
    {
        set_flag_bit_a.execute((bit<32>)hdr.inform.index);
        //set_flag_bit_a.execute(0);
        //flag_stats.count();
    }
     table set_flag_bit_t { // the called stage should be check
        key = {meta.constant: exact;}
        actions = {@defaultonly NoAction;set_flag_bit;}
        //counters = flag_stats;
        const default_action = NoAction;
    }

    action get_flag_bitb()
    {
        meta.locked2=get_flag_bit_b.execute((bit<32>)meta.index2);
        //meta.locked2=get_flag_bit_b.execute(0);
    }
     table get_flag_bitb_t {
        actions = { get_flag_bitb; }
        default_action = get_flag_bitb;
    }
    action set_flag_bitb()
    {
        //set_flag_bit_b.execute(0);
        set_flag_bit_b.execute((bit<32>)hdr.inform.index);
    }
     table set_flag_bitb_t {
         key = {meta.constant: exact;}
        actions = {@defaultonly NoAction; set_flag_bitb; }
        const default_action = NoAction;
    }

    action get_flag_bitc()
    {
        //meta.locked3=get_flag_bit_c.execute(0);
        meta.locked1=get_flag_bit_c.execute((bit<32>)meta.index3);
    }
     table get_flag_bitc_t {
        actions = { get_flag_bitc; }
        default_action = get_flag_bitc;
    }
    action set_flag_bitc()
    {
        //set_flag_bit_c.execute(0);
        set_flag_bit_c.execute((bit<32>)hdr.inform.index);
    }
     table set_flag_bitc_t {
         key = { meta.constant: exact; }
        actions = { @defaultonly NoAction;set_flag_bitc; }
        const default_action = NoAction;
    }
    action get_flag_bitd()
    {
        //meta.locked3=get_flag_bit_c.execute(0);
        meta.locked2=get_flag_bit_d.execute((bit<32>)meta.index4);
    }
     table get_flag_bitd_t {
        actions = { get_flag_bitd; }
        default_action = get_flag_bitd;
    }
    action set_flag_bitd()
    {
        //set_flag_bit_c.execute(0);
        set_flag_bit_d.execute((bit<32>)hdr.inform.index);
    }
     table set_flag_bitd_t {
         key = { meta.constant: exact; }
        actions = { @defaultonly NoAction;set_flag_bitd; }
        const default_action = NoAction;
    }

     action calc_outd(){
         //hdr.sketch.sketch_value = calc_out_c.execute(0);
        // hdr.sketch.sketch_value = calc_out_d.execute((bit<32>)meta.index4);
          calc_out_d.execute((bit<32>)meta.index4);
     }
     table calc_outd_t{
         actions={calc_outd;}
         default_action=calc_outd;
     }

   action adj_yes_no_counter()
    {
        meta.yes_no=adj_yes_no_counter_a.execute((bit<32>)meta.index1);
        //meta.yes_no=adj_yes_no_counter_a.execute(0);
    }
    action inc_locked_ID_yes_no_counter()
    {
        //meta.yes_no=inc_locked_ID_yes_no_counter_a.execute(0);
        meta.yes_no=inc_locked_ID_yes_no_counter_a.execute((bit<32>)meta.index1);
    }
     table adj_yes_no_counter_t {
        key={meta.locked1:exact;}
        actions = { adj_yes_no_counter; 
        inc_locked_ID_yes_no_counter;
                    @defaultonly NoAction; }
        const default_action = NoAction();
    }
    action inc_collision_counter()
    {
        //meta.pktlen=(bit<16>)inc_collision_counter_a.execute(0);
        meta.pktlen=(bit<16>)inc_collision_counter_a.execute((bit<32>)meta.index1);
    }
     table inc_collision_counter_t {
        actions = { inc_collision_counter; }
        const default_action = inc_collision_counter;
    }
   


   action adj_yes_no_counterb()
    {
        meta.yes_no=adj_yes_no_counter_b.execute((bit<32>)meta.index2);
        //meta.yes_no=adj_yes_no_counter_b.execute(0);
    }
    action inc_locked_ID_yes_no_counterb()
    {
       //meta.yes_no=inc_locked_ID_yes_no_counter_b.execute(0);
        meta.yes_no=inc_locked_ID_yes_no_counter_b.execute((bit<32>)meta.index2);
    }
     table adj_yes_no_counterb_t {
        key={meta.locked2:exact;}
        actions = { adj_yes_no_counterb; 
                    inc_locked_ID_yes_no_counterb;
                    @defaultonly NoAction; }
        const default_action = NoAction();
    }
    action inc_collision_counterb()
    {
        meta.pktlen=(bit<16>)inc_collision_counter_b.execute((bit<32>)meta.index2);
        //meta.pktlen=(bit<16>)inc_collision_counter_b.execute(0);
    }
     table inc_collision_counterb_t {
        actions = { inc_collision_counterb;} 
        const default_action = inc_collision_counterb;
    }
   


   action adj_yes_no_counterc()
    {
        meta.yes_no=adj_yes_no_counter_c.execute((bit<32>)meta.index3);
        //meta.yes_no=adj_yes_no_counter_c.execute(0);
    }
    action inc_locked_ID_yes_no_counterc()
    {
        //meta.yes_no=inc_locked_ID_yes_no_counter_c.execute(0);
        meta.yes_no=inc_locked_ID_yes_no_counter_c.execute((bit<32>)meta.index3);
    }
     table adj_yes_no_counterc_t {
        key = {meta.locked1:exact;}
        actions = { adj_yes_no_counterc; 
                    inc_locked_ID_yes_no_counterc;
                    @defaultonly NoAction; }
        const default_action = NoAction();
    }
    action inc_collision_counterc()
    {
        //meta.pktlen=(bit<16>)inc_collision_counter_c.execute(0);
        meta.pktlen=(bit<16>)inc_collision_counter_c.execute((bit<32>)meta.index3);
    }
     table inc_collision_counterc_t {
        actions = { inc_collision_counterc;} 
        const default_action = inc_collision_counterc;
    }
   

   action adj_yes_no_counterd()
    {
        meta.yes_no=adj_yes_no_counter_d.execute((bit<32>)meta.index4);
        //meta.yes_no=adj_yes_no_counter_c.execute(0);
    }
    action inc_locked_ID_yes_no_counterd()
    {
        //meta.yes_no=inc_locked_ID_yes_no_counter_c.execute(0);
        meta.yes_no=inc_locked_ID_yes_no_counter_d.execute((bit<32>)meta.index4);
    }
     table adj_yes_no_counterd_t {
        key = {meta.locked2:exact;}
        actions = { adj_yes_no_counterd; 
                    inc_locked_ID_yes_no_counterd;
                    @defaultonly NoAction; }
        const default_action = NoAction();
    }
    action inc_collision_counterd()
    {
        //meta.pktlen=(bit<16>)inc_collision_counter_c.execute(0);
        meta.pktlen=(bit<16>)inc_collision_counter_d.execute((bit<32>)meta.index4);
    }
     table inc_collision_counterd_t {
        actions = { inc_collision_counterd;} 
        const default_action = inc_collision_counterd;
    }



   

    action mirror_set()
    {
        meta.session_id=2;
        ig_dprsr_md.mirror_type=2;
        meta.mirror_header.layer_id=1;
        meta.mirror_header.index=(bit<16>)meta.index1;   
        mirror_stats.count();
    }
 /*   action mirror_set_2()
    {
        mirror_stats.count();

    }*/
    table mirror_set_t
    {
        key={
            meta.locked1:exact;
            meta.yes_no:exact;}
        actions={mirror_set;@defaultonly NoAction;}
        counters = mirror_stats;
        const default_action=NoAction;
    }
    action mirror_set_b()
    {
        meta.session_id=2;
        ig_dprsr_md.mirror_type=2;
        meta.mirror_header.layer_id=2;
        meta.mirror_header.index=(bit<16>)meta.index2;
    }
     table mirror_setb_t
    {
        key={
            meta.locked2:exact;
             meta.yes_no:exact;}
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
     table mirror_setc_t
    {
        key={
            meta.locked1:exact;
            meta.yes_no:exact;}
        actions={mirror_set_c;NoAction;}
        default_action=NoAction;
    }

    action mirror_set_d()
    {
        meta.session_id=2;
        ig_dprsr_md.mirror_type=2;
        meta.mirror_header.layer_id=4;
        meta.mirror_header.index=(bit<16>)meta.index4;
    }
    @stage(10) table mirror_setd_t
    {
        key={
            meta.locked2:exact;
            meta.yes_no:exact;}
        actions={mirror_set_d;NoAction;}
        default_action=NoAction;
    }
   

    action mirror_set_first()
    {
        meta.mirror_header.ether_type=0x1111;
        meta.mirror_header.dst_addr=0x1234;
        meta.mirror_header.src_addr=0x4321;
        //mirror_set_after_stats.count();
    }
    @stage(11) table mirror_setafter_t
    {
        //key={meta.session_id:exact;}
        actions={mirror_set_first; }
        //counters=mirror_set_after_stats;
        const default_action=mirror_set_first;
    }

apply {
    //inc_total_counterd_t.apply();
    if (hdr.arp.isValid())
    {
        arp_host.apply();
    }
    else if (hdr.ipv4.isValid())
    {
        ipv4_host.apply();
        if (hdr.tcp.isValid())
        {
            //calculating the hashing index
            cal_ID_t.apply();
            cal_index1_t.apply(); //0
            cal_index2_t.apply(); //0
            cal_index3_t.apply(); //0
            cal_index4_t.apply(); //0
            cal_index_cf1_t.apply(); //0
            cal_index_cf2_t.apply(); //0

            get_flag_bit_t.apply(); //1

            set_filter_countera_t.apply();//1
            //flag_cf=0 || flag_cf=register1+pktlen(after subtracting threshold, may be negative)
            set_filter_counterb_t.apply();//1
            //flag_cf2=0 || flag_cf2=register2+pktlen(after subtracting threshold, may be negative)
            meta.collision=min(flag_cf,flag_cf2);//2
            if((!(meta.collision&0x8000==0x8000))){  //3
                //first layer  
                adj_yes_no_counter_t.apply(); // yes_no!=0 equal, est_low(id)=yes_no
                //yes_no=0 not equal no replacement || yes_no=pktlen replacement
                //yes_no=0 not equal || yes_no!=0 equal
                hdr.sketch.sketch_value=meta.yes_no; 
                if(meta.yes_no==0&&meta.locked1==0) // when not locked, not equal check collision
                    inc_collision_counter_t.apply(); //5 
                // update pktlen directly, pktlen >0 when not locked ,exceed, =0, when not locked,
                // not exceed.(not equal) When equal, pktlen still >0
                if(meta.pktlen>0)
                    mirror_set_t.apply();//5 use ternary match, if pktlen>0, yes_no==0, lock==0, lock
                             
                //second layer
                get_flag_bitb_t.apply(); // update meta.locked to second layer   
                if(meta.yes_no==0&&meta.pktlen>0){   
                    adj_yes_no_counterb_t.apply(); 
                    hdr.sketch.sketch_value=meta.yes_no; 
                    if(meta.yes_no==0&&meta.locked2==0)
                        inc_collision_counterb_t.apply();
                    if(meta.pktlen>0)
                    mirror_setb_t.apply();
                
                    
                    get_flag_bitc_t.apply();
                    // third layer  
                    if(meta.yes_no==0&&meta.pktlen>0){
                        adj_yes_no_counterc_t.apply();
                      //  meta.collision=0;
                        
                        hdr.sketch.sketch_value=meta.yes_no; 
                        if(meta.yes_no==0&&meta.locked1==0)
                            inc_collision_counterc_t.apply();
                        if(meta.pktlen>0)
                        mirror_setc_t.apply();
                        
                           get_flag_bitd_t.apply(); 
                        if(meta.yes_no==0&&meta.pktlen>0){
                                adj_yes_no_counterd_t.apply();

                                hdr.sketch.sketch_value = meta.yes_no;
                                if(meta.yes_no == 0 && meta.locked2==0)
                                    inc_collision_counterd_t.apply();
                                if(meta.pktlen>0)
                                    mirror_setd_t.apply();

                                if(meta.yes_no==0&& meta.pktlen>0)
                                    calc_outd_t.apply();
                                //hdr.sketch.output = 1;
                        }                    
                    }
                }
                mirror_setafter_t.apply();//11
            }
            
        }
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
        if(hdr.inform.layer_id == 4){
            set_flag_bitd_t.apply();
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
    Checksum() tcp_csum;
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
        if(hdr.tcp.isValid()){
            hdr.tcp.checksum = tcp_csum.update({
                    hdr.tcp.src_port, hdr.tcp.dst_port, hdr.tcp.seq_no,
                    hdr.tcp.ack_no, hdr.tcp.data_offset, hdr.tcp.res,
                    hdr.tcp.flags, hdr.tcp.window, hdr.tcp.urgent_ptr});
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
