#pragma once

#include <ddprof/ffi.h>

#define      CPU_TIME_VALUE {.type_ = DDPROF_FFI_CHARSLICE_C("cpu-time"),      .unit = DDPROF_FFI_CHARSLICE_C("nanoseconds")}
#define   CPU_SAMPLES_VALUE {.type_ = DDPROF_FFI_CHARSLICE_C("cpu-samples"),   .unit = DDPROF_FFI_CHARSLICE_C("count")}
#define     WALL_TIME_VALUE {.type_ = DDPROF_FFI_CHARSLICE_C("wall-time"),     .unit = DDPROF_FFI_CHARSLICE_C("nanoseconds")}
#define ALLOC_SAMPLES_VALUE {.type_ = DDPROF_FFI_CHARSLICE_C("alloc-samples"), .unit = DDPROF_FFI_CHARSLICE_C("count")}
#define   ALLOC_SPACE_VALUE {.type_ = DDPROF_FFI_CHARSLICE_C("alloc-space"),   .unit = DDPROF_FFI_CHARSLICE_C("bytes")}
#define    HEAP_SPACE_VALUE {.type_ = DDPROF_FFI_CHARSLICE_C("heap-space"),    .unit = DDPROF_FFI_CHARSLICE_C("bytes")}

const static ddprof_ffi_ValueType enabled_value_types[] = {CPU_TIME_VALUE, CPU_SAMPLES_VALUE, WALL_TIME_VALUE};
#define ENABLED_VALUE_TYPES_COUNT (sizeof(enabled_value_types) / sizeof(ddprof_ffi_ValueType))

void record_sample(VALUE recorder_instance, ddprof_ffi_Sample sample);
