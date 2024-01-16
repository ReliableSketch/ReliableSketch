from netaddr import IPAddress

#p4 = bfrt.ErrorControlWeight_no_report_value.pipe
p4 = bfrt.ErrorControlWeight_4layer.pipe

# This function can clear all the tables and later on other fixed objects
# once bfrt support is added.
def clear_all(verbose=True, batching=True):
    global p4
    global bfrt
    
    # The order is important. We do want to clear from the top, i.e.
    # delete objects that use other objects, e.g. table entries use
    # selector groups and selector groups use action profile members

    for table_types in (['MATCH_DIRECT', 'MATCH_INDIRECT_SELECTOR'],
                        ['SELECTOR'],
                        ['ACTION_PROFILE']):
        for table in p4.info(return_info=True, print_info=False):
            if table['type'] in table_types:
                if verbose:
                    print("Clearing table {:<40} ... ".
                          format(table['full_name']), end='', flush=True)
                table['node'].clear(batch=batching)
                if verbose:
                    print('Done')
                    
clear_all(verbose=True)


print(' ')
print('Add table entries now ')
print(' ')
    
adj_yes_no_counter = p4.Ingress.adj_yes_no_counter_t

adj_yes_no_counter.add_with_adj_yes_no_counter(locked1 = 0)
adj_yes_no_counter.add_with_inc_locked_ID_yes_no_counter(locked1 = 1)

adj_yes_no_counterb = p4.Ingress.adj_yes_no_counterb_t

adj_yes_no_counterb.add_with_adj_yes_no_counterb(locked2 = 0)
adj_yes_no_counterb.add_with_inc_locked_ID_yes_no_counterb(locked2 = 1)

adj_yes_no_counterc = p4.Ingress.adj_yes_no_counterc_t

adj_yes_no_counterc.add_with_adj_yes_no_counterc(locked1 = 0)
adj_yes_no_counterc.add_with_inc_locked_ID_yes_no_counterc(locked1 = 1)

adj_yes_no_counterd = p4.Ingress.adj_yes_no_counterd_t

adj_yes_no_counterd.add_with_adj_yes_no_counterd(locked2 = 0)
adj_yes_no_counterd.add_with_inc_locked_ID_yes_no_counterd(locked2 = 1)

mirror = bfrt.mirror.cfg
mirror.add_with_normal(sid=2,session_enable=True,ucast_egress_port=196,ucast_egress_port_valid=True,direction="INGRESS",max_pkt_len=64)
mirror.add_with_normal(sid=3,session_enable=True,ucast_egress_port=128,ucast_egress_port_valid=True,direction="INGRESS",max_pkt_len=64)


ipv4_host =  p4.Ingress.ipv4_host
#ipv4_host.add_with_unicast_send(
#    dst_addr=IPAddress('10.0.0.1'), port=128)
#ipv4_host.add_with_unicast_send(
#    dst_addr=IPAddress('10.0.0.2'),   port=44)

mirror_layer_a = p4.Ingress.mirror_set_t
mirror_layer_a.add_with_mirror_set(locked1=0,yes_no=0)


mirror_layer_b = p4.Ingress.mirror_setb_t
mirror_layer_b.add_with_mirror_set_b(locked2=0,yes_no=0)

mirror_layer_c = p4.Ingress.mirror_setc_t
mirror_layer_c.add_with_mirror_set_c(locked1=0,yes_no=0)

mirror_layer_d = p4.Ingress.mirror_setd_t
mirror_layer_d.add_with_mirror_set_d(locked2=0,yes_no=0)

#mirror_after = p4.Ingress.mirror_setafter_t
#mirror_after.add_with_mirror_set_first(session_id = 2)
set_filter_countera = p4.Ingress.set_filter_countera_t
set_filter_countera.add_with_set_filter_countera(constant = 0)

flag_bit = p4.Ingress.set_flag_bit_t
flag_bit.add_with_set_flag_bit(constant = 0)
    
flag_bitb = p4.Ingress.set_flag_bitb_t
flag_bitb.add_with_set_flag_bitb(constant = 0)

flag_bitc = p4.Ingress.set_flag_bitc_t
flag_bitc.add_with_set_flag_bitc(constant = 0)

flag_bitd = p4.Ingress.set_flag_bitd_t
flag_bitd.add_with_set_flag_bitd(constant = 0)

bfrt.complete_operations()

print('table entries added')
print(' ')
