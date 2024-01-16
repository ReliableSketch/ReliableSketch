# ReliableSketch - CPU Implementation

### File Descriptions

- `rs.h/cpp` contains the implementation of our ReliableSketch.
- `cm.h/cpp` contains the implementation of CM Sketch.
- `cu.h/cpp` contains the implementation of CU Sketch.
- `ss.h/cpp` contains the implementation of Space-Saving.
- `elastic.h/cpp` contains the implementation of ElasticSketch.
- `coco.h/cpp` contains the implementation of CocoSketch.
- `hashpipe.h/cpp` contains the implementation of HashPipe.
- `precision.h/cpp` contains the implementation of PRECISION.
- `murmur3.h` contains the implementation of Murmur Hash.
- `main.cpp` is the entry of all benchmarks.

### Usages

- Modify the code of function `main()` in `main.cpp` to change parameters of experimental sketches or tasks.
- Type `make` to build benchmark program and `./benchmark` to run it.


### Notes

- All sketch classes are derived from `class Sketch` so that you can push any sketch to the vector `sk`, which is sent to the test function. 
- Before evoking test functions, you can change the size of sketches.
- Datasets can be found in the reference of the paper.