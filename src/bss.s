	section .bss align=4096

zDataFilename:             resb 8
zInputDevices:
zInputFilenames:           resb 8 ; also points to the END of the size specs list - (size, start index) pairs
zInputCount:               resb 4
zSizeSpecCount:            resb 4
zCurrentFD:                resb 4
zCurrentOutputOffset:
zDefaultFileBlockSize:     resb 4
zExecutionMode:
zPartitionTableSizesMatch:
zPartitionTableType:       resb 1
zNoMoreOptions:
zRemainingBufferBlocks:    resb 1
zHeaderPartitionTableSize: resb 2
                           resb 4 ; padding
zStringBuffer:             ; 432 bytes total, also covering the following:
zGenericDataBuffer:        resb 8
zStatBuffer:               resb struct_stat_size
zRealFilenames:            resb 8
zInputBlockListPointer:    resb 8
zCurrentInputIndex:        resb 4
zCurrentBufferSize:        resb 4
zCurrentBuffer:            resb 8 ; allocated buffer in memory
zInputBlockBuffer:         resb 8 ; points to the next block, not the beginning of the buffer
                           resb 432 - ($ - zStringBuffer)
