# ReliableSketch - P4 Implementation

## File Descriptions

- `ErrorControlShort.p4` is the p4 implementation of ReliableSketch. 
- `p4_build.sh` is the script to compile the p4 program.
- `port-add` and `tableinit.py` is the script to set p4 port and table entry. 
- `dump` contains the codes to dump all the register from p4 switch by python, the format of result is JSON. 
- `weight` contains the code of ReliableSketch with weighted insertion. `weight/ErrorControlWeight_4layer.p4` is the p4 implementation of of ReliableSketch with weighted insertion.  `weight/table_init_weight.py` contains the codes to set table entry. `weight/dump_weight.py` contains the codes to dump all the register from p4 switch by python with one script.

## Usage

1. Use p4 script to compile the ErrorControlShort.p4 or ErrorControlWeight_4layer.p4

```
./p4_build.sh ErrorControlShort.p4
(Or ./p4_build.sh ErrorControlWeight_4layer.p4)
```

2. Run the compiled program on switch

3. Run `port-add` and `tableinit.py`, port and ip in `tableinit.py` should be modified by information of your server. 

```
bfshell -f port-add 
bfshell -b tableinit.py
(or bfshell -b table_init_weight.py)
```

4. After setting the table entry, it works.