p4 = bfrt.ErrorControlWeight_4layer.pipe

# dump all tables
print("""
******************* PROGAMMING RESULTS *****************
""")
print ("""

       ********** Table Entries Dump in A************
""")

print("Table: filter_counter_a")
filter_counter_a = p4.Ingress.filter_counter_a
fca_json_data = filter_counter_a.dump(return_ents=True,json=True,from_hw=True)
fca_datas = json.loads(fca_json_data)
file_fca = open('/root/ErrorControl/OutputTables/file_fca','w')
for data in fca_datas:
    file_fca.write(str(data['data']['Ingress.filter_counter_a.f1'][1])+'\n')
file_fca.close()

print ("Table: yes_no_counter_a")
yes_no_counter_a = p4.Ingress.yes_no_counter_a
ynca_json_data = yes_no_counter_a.dump(return_ents=True,json=True,from_hw=True)
ynca_datas = json.loads(ynca_json_data)
file_ynca = open('/root/ErrorControl/OutputTables/file_ynca','w')
for data in ynca_datas:
    file_ynca.write("ID: ")
    file_ynca.write(str(data['data']['Ingress.yes_no_counter_a.ID'][1])+'\n')
    file_ynca.write("yes_no: ")
    file_ynca.write(str(data['data']['Ingress.yes_no_counter_a.yes_no'][1])+'\n')
file_ynca.close()

print ("Table: collision_counter_a")
collision_counter_a = p4.Ingress.collision_counter_a
cca_json_data = collision_counter_a.dump(return_ents=True,json=True,from_hw=True)
cca_datas = json.loads(cca_json_data)
file_cca = open('/root/ErrorControl/OutputTables/file_cca','w')
for data in cca_datas:
    file_cca.write("collision: ")
    file_cca.write(str(data['data']['Ingress.collision_counter_a.f1'][1])+'\n')
file_cca.close()   

print ("Table: flag_bit_a")
flag_bit_a = p4.Ingress.flag_bit_a
fba_json_data = flag_bit_a.dump(return_ents=True,json=True,from_hw=True)
fba_datas = json.loads(fba_json_data)
file_fba = open('/root/ErrorControl/OutputTables/file_fba','w')
for data in fba_datas:
    file_fba.write("flag bit: ")
    file_fba.write(str(data['data']['Ingress.flag_bit_a.f1'][1])+'\n')
file_fba.close() 



print ("""

       ********** Table Entries Dump in B************
""")

print("Table: filter_counter_b")
filter_counter_b = p4.Ingress.filter_counter_b
fcb_json_data = filter_counter_b.dump(return_ents=True,json=True,from_hw=True)
fcb_datas = json.loads(fcb_json_data)
file_fcb = open('/root/ErrorControl/OutputTables/file_fcb','w')
for data in fcb_datas:
    file_fcb.write(str(data['data']['Ingress.filter_counter_b.f1'][1])+'\n')
file_fcb.close()

print ("Table: yes_no_counter_b")
yes_no_counter_b = p4.Ingress.yes_no_counter_b
yncb_json_data = yes_no_counter_b.dump(return_ents=True,json=True,from_hw=True)
yncb_datas = json.loads(yncb_json_data)
file_yncb = open('/root/ErrorControl/OutputTables/file_yncb','w')
for data in yncb_datas:
    file_yncb.write("ID: ")
    file_yncb.write(str(data['data']['Ingress.yes_no_counter_b.ID'][1])+'\n')
    file_yncb.write("yes_no: ")
    file_yncb.write(str(data['data']['Ingress.yes_no_counter_b.yes_no'][1])+'\n')
file_yncb.close()

print ("Table: collision_counter_b")
collision_counter_b = p4.Ingress.collision_counter_b
ccb_json_data = collision_counter_b.dump(return_ents=True,json=True,from_hw=True)
ccb_datas = json.loads(ccb_json_data)
file_ccb = open('/root/ErrorControl/OutputTables/file_ccb','w')
for data in ccb_datas:
    file_ccb.write("collision: ")
    file_ccb.write(str(data['data']['Ingress.collision_counter_b.f1'][1])+'\n')
file_ccb.close()   

print ("Table: flag_bit_b")
flag_bit_b = p4.Ingress.flag_bit_b
fbb_json_data = flag_bit_b.dump(return_ents=True,json=True,from_hw=True)
fbb_datas = json.loads(fbb_json_data)
file_fbb = open('/root/ErrorControl/OutputTables/file_fbb','w')
for data in fbb_datas:
    file_fbb.write("flag bit: ")
    file_fbb.write(str(data['data']['Ingress.flag_bit_b.f1'][1])+'\n')
file_fbb.close()


print ("""

       ********** Table Entries Dump in C************
""")

print ("Table: yes_no_counter_c")
yes_no_counter_c = p4.Ingress.yes_no_counter_c
yncc_json_data = yes_no_counter_c.dump(return_ents=True,json=True,from_hw=True)
yncc_datas = json.loads(yncc_json_data)
file_yncc = open('/root/ErrorControl/OutputTables/file_yncc','w')
for data in yncc_datas:
    file_yncc.write("ID: ")
    file_yncc.write(str(data['data']['Ingress.yes_no_counter_c.ID'][1])+'\n')
    file_yncc.write("yes_no: ")
    file_yncc.write(str(data['data']['Ingress.yes_no_counter_c.yes_no'][1])+'\n')
file_yncc.close()

print ("Table: collision_counter_c")
collision_counter_c = p4.Ingress.collision_counter_c
ccc_json_data = collision_counter_c.dump(return_ents=True,json=True,from_hw=True)
ccc_datas = json.loads(ccc_json_data)
file_ccc = open('/root/ErrorControl/OutputTables/file_ccc','w')
for data in ccc_datas:
    file_ccc.write("collision: ")
    file_ccc.write(str(data['data']['Ingress.collision_counter_c.f1'][1])+'\n')
file_ccc.close()   

print ("Table: flag_bit_c")
flag_bit_c = p4.Ingress.flag_bit_c
fbc_json_data = flag_bit_c.dump(return_ents=True,json=True,from_hw=True)
fbc_datas = json.loads(fbc_json_data)
file_fbc = open('/root/ErrorControl/OutputTables/file_fbc','w')
for data in fbc_datas:
    file_fbc.write("flag bit: ")
    file_fbc.write(str(data['data']['Ingress.flag_bit_c.f1'][1])+'\n')
file_fbc.close() 



print ("""

       ********** Table Entries Dump in D************
""")

print ("Table: yes_no_counter_d")
yes_no_counter_d = p4.Ingress.yes_no_counter_d
yncd_json_data = yes_no_counter_d.dump(return_ents=True,json=True,from_hw=True)
yncd_datas = json.loads(yncd_json_data)
file_yncd = open('/root/ErrorControl/OutputTables/file_yncd','w')
for data in yncd_datas:
    file_yncd.write("ID: ")
    file_yncd.write(str(data['data']['Ingress.yes_no_counter_d.ID'][1])+'\n')
    file_yncd.write("yes_no: ")
    file_yncd.write(str(data['data']['Ingress.yes_no_counter_d.yes_no'][1])+'\n')
file_yncd.close()

print ("Table: collision_counter_d")
collision_counter_d = p4.Ingress.collision_counter_d
ccd_json_data = collision_counter_d.dump(return_ents=True,json=True,from_hw=True)
ccd_datas = json.loads(ccd_json_data)
file_ccd = open('/root/ErrorControl/OutputTables/file_ccd','w')
for data in ccd_datas:
    file_ccd.write("collision: ")
    file_ccd.write(str(data['data']['Ingress.collision_counter_d.f1'][1])+'\n')
file_ccd.close()   

print ("Table: flag_bit_d")
flag_bit_d = p4.Ingress.flag_bit_d
fbd_json_data = flag_bit_d.dump(return_ents=True,json=True,from_hw=True)
fbd_datas = json.loads(fbd_json_data)
file_fbd = open('/root/ErrorControl/OutputTables/file_fbd','w')
for data in fbd_datas:
    file_fbd.write("flag bit: ")
    file_fbd.write(str(data['data']['Ingress.flag_bit_d.f1'][1])+'\n')
file_fbd.close() 

print ("Table: out_d")
out_d = p4.Ingress.out_d
od_json_data = out_d.dump(return_ents=True,json=True,from_hw=True)
od_datas = json.loads(od_json_data)
file_od = open('/root/ErrorControl/OutputTables/file_od','w')
for data in od_datas:
    file_od.write("out d: ")
    file_od.write(str(data['data']['Ingress.out_d.f1'][1])+'\n')
file_od.close() 
