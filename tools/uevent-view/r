BIN="uv"

adb push $OUT/system/bin/$BIN /data/
adb shell chmod 755 /data/$BIN

adb shell /data/$BIN $@

