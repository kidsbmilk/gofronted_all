# A Go frontend

Ian Lance Taylor
Last update 15 June 2014

This is a compiler frontend for the [Go programming language](http://golang.org/). The frontend was originally developed at Google, and was released in November 2009. It was originally written by Ian Lance Taylor.

It was originally written for [GCC](http://gcc.gnu.org/). As of this writing it only supports GCC, but the GCC support has been separated from the rest of the frontend, so supporting another compiler is feasible.
（这里说的非常明白，最初 gofrontend 是给 gcc 使用的前端，后来也可以结合其他的后端进行 go 编译器的开发。）

The go subdirectory holds the frontend source code. This is mirrored to the gcc/go subdirectory in the GCC repository.

The libgo subdirectory holds the library source code. This is a copy of the main Go library with various changes appropriate for this compiler. The main Go library is hosted at <http://go.googlesource.com/go>, in the src directory. The libgo subdirectory is mirrored to the libgo subdirectory in the gcc repository.
（这个非常重要，libgo 里有大量的 go 代码，其实就是跟 go 官方的库同步的，只不过为了跟 llvm 配合，做了一些小修改，可以对比 go 官方代码看看。TODO-ZZ）

## Legal Matters

To contribute patches to the files in this directory, please see [Contributing to the gccgo frontend](http://golang.org/doc/gccgo_contribute.html).

The master copy of these files is hosted in [Gerrit](http://go.googlesource.com/gofrontend) (there is a mirror at [Github](http://github.com/golang/gofrontend)). Changes to these files require signing a Google contributor license agreement. If you are the copyright holder, you will need to agree to the [Google Individual Contributor License Agreement](http://code.google.com/legal/individual-cla-v1.0.html). This agreement can be completed online.

If your organization is the copyright holder, the organization will need to agree to the [Google Software Grant and Corporate Contributor License Agreement](http://code.google.com/legal/corporate-cla-v1.0.html).

If the copyright holder for your code has already completed the agreement in connection with another Google open source project, it does not need to be completed again.

The authors of these files may be found in the [AUTHORS](./AUTHORS) and [CONTRIBUTORS](./CONTRIBUTORS) files.
