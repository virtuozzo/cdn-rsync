#!/bin/bash

function main() {
    echo ================================================
    echo "RUNNING TESTS: SOURCE IS A FILE"
    run_test "file"

    echo ================================================
    echo "RUNNING TESTS: SOURCE IS A SYMLINK TO A FILE"
    run_test "symlink"
}

function run_test() {
    file_type=$1

    echo ================================================
    echo TEST: File does not exist at dest, no attributes
    init $file_type
    set_mtime src/file.txt 1
    sync

    assert_size  dst/file.txt 16
    assert_mtime dst/file.txt 1
    assert_same  src/file.txt dst/file.txt

    echo ================================================
    echo TEST: File exists at dest, no attributes
    sync

    assert_size  dst/file.txt 16
    assert_mtime dst/file.txt 1
    assert_same  src/file.txt dst/file.txt

    echo ================================================
    echo TEST: File has no attributes, older at dst - dst should change
    init $file_type
    echo quick brown fox > src/file.txt
    set_mtime src/file.txt 2
    echo lazy brown dogs > dst/file.txt
    set_mtime dst/file.txt 1
    sync

    assert_size  dst/file.txt 16
    assert_mtime dst/file.txt 2
    assert_same  src/file.txt dst/file.txt

    echo ================================================
    echo TEST: File has no attributes, newer at dst - dst should change
    init $file_type
    echo quick brown fox > src/file.txt
    set_mtime src/file.txt 1
    echo lazy brown dogs > dst/file.txt
    set_mtime dst/file.txt 2
    sync

    assert_size  dst/file.txt 16
    assert_mtime dst/file.txt 1
    assert_same  src/file.txt dst/file.txt

    echo ================================================
    echo TEST: Checksum/txn exists at src but not at dst - dst should change even though newer
    init $file_type
    echo quick brown fox > src/file.txt
    set_checksum src/file.txt
    set_txn      src/file.txt 1
    set_mtime    src/file.txt 1
    echo lazy old dog > dst/file.txt
    set_mtime    dst/file.txt 2
    sync

    assert_size dst/file.txt 16
    assert_attr dst/file.txt user.checksum $(md5 dst/file.txt)
    assert_attr dst/file.txt user.txn_time 1
    assert_same  src/file.txt dst/file.txt

    echo ================================================
    echo TEST: Checksum/txn exists at dst but not at src - dst should change
    init $file_type
    echo quick brown fox > src/file.txt
    set_mtime    src/file.txt 2
    echo lazy old dog > dst/file.txt
    set_txn      dst/file.txt 1
    set_checksum dst/file.txt
    set_mtime    dst/file.txt 1
    sync

    assert_size dst/file.txt 16
    assert_attr dst/file.txt user.checksum ""
    assert_attr dst/file.txt user.txn_time ""
    assert_same  src/file.txt dst/file.txt

    echo ================================================
    echo TEST: Checksum/txn exists at dst but not at src - dst should change even though newer
    init $file_type
    echo quick brown fox > src/file.txt
    set_mtime    src/file.txt 1
    echo lazy old dog > dst/file.txt
    set_txn      dst/file.txt 1
    set_checksum dst/file.txt
    set_mtime    dst/file.txt 2
    sync

    assert_size dst/file.txt 16
    assert_attr dst/file.txt user.checksum ""
    assert_attr dst/file.txt user.txn_time ""
    assert_same  src/file.txt dst/file.txt

    echo ================================================
    echo TEST: Checksum same, src txn and mtime newer - only dst txn_time should change
    init $file_type
    echo quick brown fox > src/file.txt
    set_checksum src/file.txt
    set_txn      src/file.txt 2
    set_mtime    src/file.txt 2
    echo quick brown fox > dst/file.txt
    set_checksum dst/file.txt
    set_txn      dst/file.txt 1
    set_mtime    dst/file.txt 1
    sync

    assert_size  dst/file.txt 16
    assert_mtime dst/file.txt 1
    assert_attr  dst/file.txt user.txn_time 2
    assert_attr  dst/file.txt user.checksum $(md5 dst/file.txt)
    assert_same  src/file.txt dst/file.txt

    echo ================================================
    echo TEST: Checksum/txn same, file sizes different - dst should change
    init $file_type
    echo quick brown fox > src/file.txt
    set_checksum src/file.txt
    set_txn      src/file.txt 1
    set_mtime    src/file.txt 1
    echo quick brown fox > dst/file.txt
    set_checksum dst/file.txt
    echo -n > dst/file.txt # simulate file being zero-length
    set_txn      dst/file.txt 1
    set_mtime    dst/file.txt 1
    sync

    assert_size  dst/file.txt 16
    assert_mtime dst/file.txt 1
    assert_attr  dst/file.txt user.txn_time 1
    assert_attr  dst/file.txt user.checksum $(md5 dst/file.txt)
    assert_same  src/file.txt dst/file.txt

    echo ================================================
    echo TEST: checksum different, src txn older than dst txn - dst should not change
    init $file_type
    set_checksum src/file.txt
    set_txn      src/file.txt 1
    echo lazy old dog > dst/file.txt
    set_checksum dst/file.txt
    set_txn      dst/file.txt 2
    original_md5=$(md5 dst/file.txt)
    sync

    assert_size  dst/file.txt 13
    assert_attr  dst/file.txt user.txn_time 2
    assert_attr  dst/file.txt user.checksum $original_md5

    echo ================================================
    echo TEST: checksum different, file sizes same, src txn older than dst txn - dst should not change
    init $file_type
    echo quick brown fox > dst/file.txt
    set_checksum src/file.txt
    set_txn      src/file.txt 1
    echo lazy brown dogs > dst/file.txt
    set_checksum dst/file.txt
    set_txn      dst/file.txt 2
    original_md5=$(md5 dst/file.txt)
    sync

    assert_size  dst/file.txt 16
    assert_attr  dst/file.txt user.txn_time 2
    assert_attr  dst/file.txt user.checksum $original_md5

    echo ================================================
    echo TEST: checksum different, src txn same as dst txn - dst should not change
    init $file_type
    set_checksum src/file.txt
    set_txn      src/file.txt 2
    echo lazy old dog > dst/file.txt
    set_checksum dst/file.txt
    set_txn      dst/file.txt 2
    original_md5=$(md5 dst/file.txt)
    sync

    assert_size  dst/file.txt 13
    assert_attr  dst/file.txt user.txn_time 2
    assert_attr  dst/file.txt user.checksum $original_md5

    echo ================================================
    echo TEST: checksum different, src txn newer than dst txn - dst should change
    init $file_type
    set_checksum src/file.txt
    set_txn      src/file.txt 3
    src_md5=$(md5 src/file.txt)
    echo lazy old dog > dst/file.txt
    set_checksum dst/file.txt
    set_txn      dst/file.txt 2
    sync

    assert_size  dst/file.txt 16
    assert_attr  dst/file.txt user.txn_time 3
    assert_attr  dst/file.txt user.checksum $src_md5
    assert_same  src/file.txt dst/file.txt

    echo ================================================
    echo TEST: checksum different, src txn newer than dst txn - high precision number - dst should change
    init $file_type
    set_checksum src/file.txt
    set_txn      src/file.txt 1458134105.81
    src_md5=$(md5 src/file.txt)
    echo lazy old dog > dst/file.txt
    set_checksum dst/file.txt
    set_txn      dst/file.txt 1458134105.80
    sync

    assert_size  dst/file.txt 16
    assert_attr  dst/file.txt user.txn_time 1458134105.81
    assert_attr  dst/file.txt user.checksum $src_md5
    assert_same  src/file.txt dst/file.txt
}

function init() {
    file_type=$1

    # Cleanup and create directories
    if [ $(basename $PWD) = "test" ]; then cd ..; fi

    rm -fR test/
    mkdir -p test/src test/dst
    cd test

    case $file_type in
    symlink)
        echo quick brown fox > file.txt
        ln -s ../file.txt src/file.txt
        ;;
    file)
        echo quick brown fox > src/file.txt
        ;;
    *)
        assert_fail "unknown file_type $file_type"
        ;;
    esac
}

function sync() {
    ../rsync -a --copy-links --onapp-compare --xattrs src/ dst/
}

function set_checksum() {
    file=$1
    setfattr -n user.checksum -v $(md5 $file) $file
}

function set_txn() {
    file=$1
    txn_time=$2
    setfattr -n user.txn_time -v $txn_time $file
}

function set_mtime() {
    file=$1
    mtime=$2
    touch -d @$mtime $file
}

function md5() {
    file=$1
    md5sum $file | cut -d' ' -f1
}

function assert_fail() {
    echo "ASSERTION FAILED: $1"
    exit 1
}

function assert_stat() {
    stat_type=$1
    file=$2
    expected=$3

    case $stat_type in
    size)
        format_str=%s
        ;;
    mtime)
        format_str=%Y
        ;;
    *)
        assert_fail "Unknown stat_type $stat_type"
        ;;
    esac

    actual=$(stat -c$format_str $file)

    if [ $actual -ne $expected ]; then
        assert_fail "$file $stat_type actual=$actual expected=$expected"
    fi
}

function assert_size() {
    file=$1
    expected_size=$2

    assert_stat "size" $file $expected_size
}

function assert_mtime() {
    file=$1
    expected_mtime=$2

    assert_stat "mtime" $file $expected_mtime
}

function assert_attr() {
    file=$1
    attr_name=$2
    expected_val=$3
    actual_val=$(getfattr -n $attr_name --only-values $file 2>/dev/null)

    if [ "$actual_val" != "$expected_val" ]; then
        assert_fail "$file attr $attr_name actual=$actual_val expected=$expected_val"
    fi
}

function assert_same() {
    file1=$1
    file2=$2

    if ! cmp "$file1" "$file2"; then
        assert_fail "$file1 and $file2 are different"
    fi
}

main
