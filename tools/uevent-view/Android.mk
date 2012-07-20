LOCAL_PATH := $(call my-dir)

include $(CLEAR_VARS)

NC_includes:= \
        $(LOCAL_PATH)

LOCAL_MODULE := uv

LOCAL_SRC_FILES := \
    main.c

LOCAL_CFLAGS += -Wall -DANDROID

LOCAL_LDLIBS += -lpthread

LOCAL_SHARED_LIBRARIES := libutils libcutils
LOCAL_PRELINK_MODULE := false
LOCAL_MODULE_TAGS := eng

include $(BUILD_EXECUTABLE)

