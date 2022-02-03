import time

table1 = bfrt.ErrorControlShort.pipe.Ingress.total_counter_c
tic = time.time()
a = table1.dump(return_ents=True,json=True,from_hw=True)
datas = json.loads(a)
f2 = open("/root/ErrorControl/total_c", 'w')
for data in datas:
    f2.write(str(data['data']['Ingress.total_counter_c.f1'][1])+'\n')
f2.close()
toc = time.time()
tim = toc - tic
print(tim)
#f2 = open("/root/ErrorControl/result2", 'w')
#b = table1.dump(json=True, return_ents=True)
#f2.write(b)
#f2.close()
