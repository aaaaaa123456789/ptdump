	section .bss align=4096

zDataFilename:             resb 8
zInputDevices:
zInputFilenames:           resb 8 ; also points to the END of the size specs list - (size, start index) pairs
zInputCount:               resb 4
zCurrentBlockSize:         resb 4
zTempValue:
zSizeSpecCount:            resb 4
zCurrentFD:                resb 4
zCurrentOutputOffset:
zDefaultFileBlockSize:     resb 4
zExecutionMode:
zPartitionTableSizesMatch:
zPartitionTableType:       resb 1
zNoMoreOptions:
zListingDelimiter:
zRemainingBufferBlocks:    resb 1
zFilenameLength:
zHeaderPartitionTableSize: resb 2
zStringBuffer:             ; 432 bytes total, also covering the following:
zGenericDataBuffer:        resb 8
zCurrentFilename:
zRealFilenames:            resb 8
zInputBlockListPointer:    resb 8
zCurrentInputOffset:
zCurrentInputIndex:        resb 4
zCurrentBufferSize:        resb 4
zCurrentBuffer:            resb 8 ; allocated buffer in memory
zInputBlockBuffer:         resb 8 ; points to the next block, not the beginning of the buffer
zStatBuffer:               resb struct_stat_size
                           resb 432 - ($ - zStringBuffer)
