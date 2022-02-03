# ReliableSketch - FPGA Implementation

### Descriptions

We implement the ReliableSketch on an FPGA network experimental platform (Virtex-7 VC709). The FPGA integrated with the platform is xc7vx690tffg1761-2 with 433200 Slice LUTs, 866400 Slice Register, and 1470 Block RAM Tile. The implementation mainly consists of three hardware modules: calculating hash values (hash), looking for the most frequent flow (CS_bucket), and emergency solution (ES_bucket). FPGA-based ReliableSketch is fully pipelined, which can input one key in every clock, and complete the writing after 41 clocks. According to the synthesis report, the clock frequency of our implementation in FPGA is 339 MHz, meaning the throughput of the system can be 339 Mops.

