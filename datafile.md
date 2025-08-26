# Data file format documentation

The data files created by this tool are binary files containing images of sectors, intended to contain the partition
tables and boot sectors of a drive (understanding by "boot sectors" the code and data often found in MBR-type disks
before the first partition).

The size of a data file must be a multiple of 4 bytes, and all locations within the file are written at a 4-byte
granularity (e.g., a location of 30 indicates the position starting at byte offset 120).
All locations in the file are absolute.
The maximum valid size of a data file is 16 GiB.

For the remainder of this document, a 4-byte quantity will be referred to as a **word**.
Data files are therefore word-addressable, and the maximum valid size of a data file corresponds to the maximum word
address that will fit in a word.
All words, when treated as integers, represent unsigned values.

### Basic structure

In order to facilitate compression, particularly block-oriented compression (such as that provided by the `mksquashfs`
tool), the main data structures are located at the _end_ of the data file.
The file therefore contains the images of sectors at the beginning of the file and the data tables that describe the
metadata for those images at the end.

The main data structure is the file table, which describes each logical file stored in the data file.
Logical files will usually represent physical disks (e.g., `/dev/sda`), but they may represent actual files, those
files being disk images.

The very last word of the data file indicates the number of entries in the file table, i.e., the number of logical
files stored in the data file.
This word must not be zero; a final word of zero is reserved for future versions of this format.
The file table itself immediately precedes this word; its size is determined by the product between that word and the
size of an entry (three words).
Other metadata will be located by reference through the file table.

### File table

Each entry in the file table represents a logical file.
Entries consist of four fields, packed into three words (12 bytes):

|Offset|Size|Description        |
|-----:|---:|:------------------|
|     0|   4|Filename location  |
|     4|   2|Filename length    |
|     6|   2|Block size         |
|     8|   4|Block list location|

Filenames can contain absolute or relative paths; they should not contain any embedded null bytes.
Applications should not expect them to contain a trailing null byte: the length must not include such a terminator.
Filenames must be unique within a data file, and they must not be empty.
Unlike other values in the data file, the filename length is in bytes.

The block size indicates the size of each block (or sector) of the underlying disk or disk image, in words.
A value of zero in this field indicates the maximum possible size, 65,536 words (i.e., 256 kiB).

The block list contains the locations for each block image within the data file, as well as the block number in the
original disk or disk image where that block was taken from (or should be restored to).

### Block list

The block list encodes, for each block, two pieces of information: the block number (in other words, the position in
the original disk or disk image where the block was found) and the block location (within the data file).
Since the block list encodes blocks, all sizes are in blocks: the conversion from blocks to words is given by the
block size field for that file in the file table.
The block number is an 8-byte value, and thus it needs two words to be represented; these two words (referenced as the
low and high words of the block number) are encoded separately.

The block list contains a sequence of entries, one after the other.
There are two types of entries: sequence entries and RLE entries.
The first word of each entry determines the type of entry: if its least significant byte is zero, it is an RLE entry;
otherwise, it is a sequence entry.
A word with a value of zero (at a location where an entry would start) terminates the list.
The list must not be empty.

### RLE block entries

RLE entries in the block list represent a sequence of blocks, consecutively numbered, located one after the other in
the data file.

An RLE entry consists of four words:

- Shifted length
- Location
- Initial block number, low
- Initial block number, high

The length (in blocks) is shifted up by 8 bits, so that the least significant byte of the first word is zero.
(In other words, the length is stored in the three most significant bytes of the first word.)
The length cannot be zero: if it was, the first word would be zero, and it would be interpreted as a block list
terminator, not the beginning of an entry.

The second word of the entry indicates the location of the first block in the data file.
Subsequent blocks are located one after the other at that location, up to the length indicated by the first word.
The block number for the first of those blocks is the number given by the initial block number stored in the entry;
subsequent blocks have consecutive numbers.
(It is invalid for the block number to overflow this way.)

Note: even though the last two words can be interpreted as a single 8-byte little-endian value, there is no guarantee
that it will be aligned to 8 bytes.
Only word (i.e., 4-byte) alignment can be assumed.

### Sequence block entries

Sequence entries in the block list represent arbitrary sequences of individual blocks stored consecutively in the data
file.
Block numbers in the sequence are represented as offsets from the previous value; the maximum offset between two block
numbers in a sequence is thus limited to the maximum word value of 4,294,967,295 (0xffffffff).

A sequence entry consists of three or more words:

- Length and shifted initial block number (high)
- Location
- Block number offset (one per block)

The first word of a sequence entry indicates both the length of the sequence entry and the initial block number.
The least significant byte (which must not be zero, or otherwise the entry would be interpreted as an RLE entry)
indicates the number of blocks in the sequence.
The remainder of the value is the (shifted) high word of the initial block number; the low word of the initial block
number is zero.
(Since the entry contains a block number offset for each block, the first block's offset word will therefore encode
the low word of its block number.)
For example, if the first word of the entry is 0x00000302, that indicates that the entry will contain two blocks, and
the initial block number's high word is 3 (i.e., the initial block number is 0x300000000).

The second word of the entry indicates the location of the first block in the data file.
Subsequent blocks are located one after the other at that location, up to the length indicated by the first word.

After the initial two words, the entry contains one word for each block in the sequence, which is the block number
offset.
This is the value that must be added to the block number of the previous block in the entry to obtain the current
block's block number.
For the first block in the entry, the previous block number is the initial block number indicated by the first word of
the entry; since the initial block number always has a low word of zero, this offset will be equal to the low word of
the block's block number.

It is permissible for a sequence entry to contain just one block.
In fact, this is advisable for single blocks: a sequence entry with one block in it will occupy three words, whereas
encoding it as an RLE block would take four words.

Note: since the high word of the initial block number is encoded in the upper 24 bits of the entry's first word, this
effectively limits the initial block number to 56 bits.
However, this imposes no limit in practice: given a typical block size of 512 bytes, a disk would need to exceed 32
EiB in size in order to contain a block number that would exceed 56 bits.
