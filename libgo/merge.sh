#!/bin/sh

# Copyright 2009 The Go Authors. All rights reserved.
# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file.

# This script merges changes from the master copy of the Go library
# into the libgo library.  This does the easy stuff; the hard stuff is
# left to the user.
# 此脚本将 Go 库主副本中的更改合并到 libgo 库中。这很简单；困难的东西留给用户。
#（从这里可以看出，gofrontend/libgo 主要是同步来自于 go 官方的代码。非常重要！TODO-ZZ）
#（之前在我没有看 gollvm 实现之前，我的一个想法是：结合 go 官方里的代码，以及 llvm 的底层优化，其他人家 gollvm 已经在这么做了。TODO-ZZ）
#（或许，这里已经能解决我心中的疑惑了：gollvm 是如何处理运行时与 gc 的？TODO-ZZ）

# The file MERGE should hold the Git revision number of the last
# revision which was merged into these sources.  Given that, and given
# the current sources, we can run the usual diff3 algorithm to merge
# all changes into our sources.
# 文件 MERGE 应该包含合并到这些源中的最后一个修订的 Git 修订号。
# 鉴于此，并给定当前源，我们可以运行通常的 diff3 算法将所有更改合并到我们的源中。

set -e

TMPDIR=${TMPDIR:-/tmp}

OLDDIR=${TMPDIR}/libgo-merge-old
NEWDIR=${TMPDIR}/libgo-merge-new

if ! test -f MERGE; then
  echo 1>&2 "merge.sh: must be run in libgo source directory"
  exit 1
fi

rev=weekly
case $# in
1) ;;
2) rev=$2 ;;
*)
  echo 1>&2 "merge.sh: Usage: merge.sh git-repository [revision]"
  exit 1
  ;;
esac

repository=$1

old_rev=`sed 1q MERGE`

rm -rf ${OLDDIR}
git clone ${repository} ${OLDDIR}
(cd ${OLDDIR} && git checkout ${old_rev})

rm -rf ${NEWDIR}
git clone ${repository} ${NEWDIR}
(cd ${NEWDIR} && git checkout ${rev})

new_rev=`cd ${NEWDIR} && git log | sed 1q | sed -e 's/commit //'`

merge() {
  name=$1
  old=$2
  new=$3
  libgo=$4
  if test -d ${new}; then
    if ! test -d ${old}; then
      if test -f ${old}; then
	echo 1>&2 "merge.sh: ${name}: FILE BECAME DIRECTORY"
      fi
    fi
  elif ! test -f ${new}; then
    # The file does not exist in the new version.
    if ! test -f ${old}; then
      echo 1>&2 "merge.sh internal error no files $old $new"
      exit 1
    fi
    if ! test -f ${libgo}; then
      # File removed in new version and libgo.
      :;
    else
      echo "merge.sh: ${name}: REMOVED"
      rm -f ${libgo}
    fi
  elif test -f ${old}; then
    # The file exists in the old version.
    if ! test -f ${libgo}; then
      if ! cmp -s ${old} ${new}; then
        echo "merge.sh: $name: skipping: exists in old and new git, but not in libgo"
      fi
      return
    fi
    if cmp -s ${old} ${libgo}; then
      # The libgo file is unchanged from the old version.
      if cmp -s ${new} ${libgo}; then
        # File is unchanged from old to new version.
	return
      fi
      # Update file in libgo.
      echo "merge.sh: $name: updating"
      cp ${new} ${libgo}
    else
      # The libgo file has local changes.
      set +e
      diff3 -m -E ${libgo} ${old} ${new} > ${libgo}.tmp
      status=$?
      set -e
      case $status in
      0)
        echo "merge.sh: $name: updating"
        mv ${libgo}.tmp ${libgo}
        ;;
      1)
        echo "merge.sh: $name: CONFLICTS"
        mv ${libgo}.tmp ${libgo}
        ;;
      *)
        echo 1>&2 "merge.sh: $name: DIFF3 FAILURE"
        ;;
      esac
    fi
  else
    # The file does not exist in the old version.
    if test -f ${libgo}; then
      if ! cmp -s ${new} ${libgo}; then
        echo 1>&2 "merge.sh: $name: IN NEW AND LIBGO BUT NOT OLD"
      fi
    else
      echo "merge.sh: $name: NEW"
      dir=`dirname ${libgo}`
      if ! test -d ${dir}; then
        mkdir -p ${dir}
      fi
      cp ${new} ${libgo}
    fi
  fi
}

echo ${rev} > VERSION

(cd ${NEWDIR}/src && find . -name '*.go' -print) | while read f; do
  skip=false
  case "$f" in
  ./cmd/buildid/* | ./cmd/cgo/* | ./cmd/go/* | ./cmd/gofmt/* | ./cmd/test2json/* | ./cmd/vet/* | ./cmd/internal/browser/* | ./cmd/internal/buildid/* | ./cmd/internal/codesign/* | ./cmd/internal/edit/* | ./cmd/internal/objabi/* | ./cmd/internal/quoted/* | ./cmd/internal/test2json/* | ./cmd/internal/sys/* | ./cmd/internal/traceviewer/* | ./cmd/vendor/golang.org/x/tools/* | ./cmd/vendor/golang.org/x/mod/* | ./cmd/vendor/golang.org/x/xerrors/* | ./cmd/vendor/golang.org/x/crypto/ed25519 | ./cmd/vendor/golang.org/x/sync/semaphore)
    ;;
  ./cmd/*)
    skip=true
    ;;
  ./runtime/race/*)
    skip=true
    ;;
  esac
  if test "$skip" = "true"; then
    continue
  fi

  oldfile=${OLDDIR}/src/$f
  newfile=${NEWDIR}/src/$f
  libgofile=go/`echo $f | sed -e 's|cmd/vendor/|/|' | sed -e 's|/vendor/|/|'`
  merge $f ${oldfile} ${newfile} ${libgofile}
done

(cd ${NEWDIR}/src && find . -name 'go.mod' -print) | while read f; do
  oldfile=${OLDDIR}/src/$f
  newfile=${NEWDIR}/src/$f
  libgofile=go/`echo $f | sed -e 's|cmd/vendor/|/|' | sed -e 's|/vendor/|/|'`
  merge $f ${oldfile} ${newfile} ${libgofile}
done

(cd ${NEWDIR}/src && find . -name 'modules.txt' -print) | while read f; do
  oldfile=${OLDDIR}/src/$f
  newfile=${NEWDIR}/src/$f
  libgofile=go/$f
  merge $f ${oldfile} ${newfile} ${libgofile}
done

(cd ${NEWDIR}/src && find . -name testdata -print) | while read d; do
  skip=false
  case "$d" in
  ./cmd/buildid/* | ./cmd/cgo/* | ./cmd/go/* | ./cmd/gofmt/* | ./cmd/test2json/* | ./cmd/vet/* | ./cmd/internal/browser/* | ./cmd/internal/buildid/* | ./cmd/internal/codesign/* | ./cmd/internal/diff/* | ./cmd/internal/edit/* | ./cmd/internal/objabi/* | ./cmd/internal/test2json/* | ./cmd/internal/sys/* | ./cmd/internal/traceviewer/* | ./cmd/vendor/golang.org/x/tools/*)
    ;;
  ./cmd/*)
    skip=true
    ;;
  ./runtime/race/* | ./runtime/cgo/*)
    skip=true
    ;;
  esac
  if test "$skip" = "true"; then
    continue
  fi

  oldtd=${OLDDIR}/src/$d
  newtd=${NEWDIR}/src/$d
  libgotd=go/`echo $d | sed -e 's|cmd/vendor/|/|' | sed -e 's|/vendor/|/|'`
  if ! test -d ${oldtd}; then
    echo "merge.sh: $d: NEWDIR"
    continue
  fi
  (cd ${oldtd} && git ls-files .) | while read f; do
    if test "`basename -- $f`" = ".gitignore"; then
      continue
    fi
    name=$d/$f
    oldfile=${oldtd}/$f
    newfile=${newtd}/$f
    libgofile=${libgotd}/$f
    merge ${name} ${oldfile} ${newfile} ${libgofile}
  done
  (cd ${newtd} & git ls-files .) | while read f; do
    if test "`basename -- $f`" = ".gitignore"; then
      continue
    fi
    oldfile=${oldtd}/$f
    if ! test -f ${oldfile}; then
      name=$d/$f
      newfile=${newtd}/$f
      libgofile=${libgotd}/$f
      merge ${name} ${oldfile} ${newfile} ${libgofile}
    fi
  done
done

(cd ${NEWDIR}/misc/cgo && find . -type f -print) | while read f; do
  oldfile=${OLDDIR}/misc/cgo/$f
  newfile=${NEWDIR}/misc/cgo/$f
  libgofile=misc/cgo/$f
  merge $f ${oldfile} ${newfile} ${libgofile}
done

(cd ${OLDDIR}/src && find . -name '*.go' -print) | while read f; do
  oldfile=${OLDDIR}/src/$f
  newfile=${NEWDIR}/src/$f
  libgofile=go/$f
  if test -f ${newfile}; then
    continue
  fi
  if ! test -f ${libgofile}; then
    continue
  fi
  echo "merge.sh: ${libgofile}: REMOVED"
  rm -f ${libgofile}
done

(cd ${OLDDIR}/misc/cgo && find . -type f -print) | while read f; do
  oldfile=${OLDDIR}/misc/cgo/$f
  newfile=${NEWDIR}/misc/cgo/$f
  libgofile=misc/cgo/$f
  if test -f ${newfile}; then
    continue
  fi
  if ! test -f ${libgofile}; then
    continue
  fi
  echo "merge.sh: ${libgofile}: REMOVED"
  rm -f ${libgofile}
done

(echo ${new_rev}; sed -ne '2,$p' MERGE) > MERGE.tmp
mv MERGE.tmp MERGE
