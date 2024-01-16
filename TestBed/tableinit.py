table = bfrt.mirror.cfg
table.add_with_normal(sid=2,session_enable=True,ucast_egress_port=xxx ,ucast_egress_port_valid=True,direction="INGRESS",max_pkt_len=64)
table.add_with_normal(sid=3,session_enable=True,ucast_egress_port=xxx ,ucast_egress_port_valid=True,direction="INGRESS",max_pkt_len=64)

table1 = bfrt.ErrorControlShort.pipe.Ingress.ipv4_host
table1.clear()
table1.add_with_unicast_send(dst_addr='x',port=xxx)
table1.add_with_unicast_send(dst_addr='x',port=xxx)

table4 = bfrt.ErrorControlShort.pipe.Ingress.mirror_set_t
table4.clear()
table4.add_with_mirror_set(collision=18)

table5 = bfrt.ErrorControlShort.pipe.Ingress.mirror_setb_t
table5.clear()
table5.add_with_mirror_set_b(collision=10)

table6 = bfrt.ErrorControlShort.pipe.Ingress.mirror_setc_t
table6.clear()
table6.add_with_mirror_set_c(collision=6)

table3 = bfrt.ErrorControlShort.pipe.Ingress.arp_host
table3.clear()
table3.add_with_unicast_send(proto_dst_addr='x',port=xxx)
table3.add_with_unicast_send(proto_dst_addr='x',port=xxx)

table2 = bfrt.ErrorControlShort.pipe.Ingress.mirror_setafter_t
table2.clear()
table2.add_with_mirror_set_first(session_id=2)
#table2.add_with_mirror_set_after_1(layer_id=1)
#table2.add_with_mirror_set_after_2(layer_id=2)
#table2.add_with_mirror_set_after_3(layer_id=3)
