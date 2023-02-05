## Instruction Cache
Four-way set associative blocking cache. Block size of 16 words per block. Each block is 20-bits. There are 16 sets. 

- Best case miss penalty of 11 cycles. Improvements can be made using double data rate transactions between higher level memory and instruction cache. This way, the 40-bit wide memory interface remains the same but the number of cycles needed to receive the missed block is halved. Average case cache miss penalties can be improved with instruction stream buffers as a form of hardware prefetching.

- Post-layout timing closed at 40 Mhz using OpenLane (OpenSTA)
- Core Area: 0.76 mm^2. Dimensions 1538 x 969 um.
- Cache is designed to store 20-bit predecoded instructions. Encoded instructions are 16 bits. 
- Implemented using sky130 SRAM created using OpenRAM. There a a total of six SRAM macros which are used to the data, tag and status for each way (or block) in the cache.
    - The Data Array was implemented using four SRAMs. Each SRAM has 256 words with a word size of 20 bits.
    - The Tag Array was implemented using one SRAM. This SRAM has 256 words with a word size of 32 bits since there are 4 ways each tagged with 8 bits
    - The status array was implemented using one SRAM. This SRAM has 256 words with a word size of 8 bits since there are two status bits for each of the four ways. The stataus bits include a  valid bit and a use bit for pseudo-LRU replacement. Valid bits were initalized to 0 upon reset.

### Simulation Waveform 
Demonstrate a cache miss and the subsequent interaction with memory

### Layout Images