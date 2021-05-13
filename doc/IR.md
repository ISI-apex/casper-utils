CASPER Intermediate Representations
===================================

Throughout the compilation process, CASPER represents the application program
in a sequence of intermediate representations before the final object-code:
1. in-memory task graph constructed by the meta-program (TGIR)
2. in-memory Multi-Level IR (MLIR) with CASPER dialect
3. LLVM IR code (external file)

The first and second representations are specific to CASPER and are the
focus of this document. The third representation is the unmodified LLVM IR
from the LLVM project. The in-memory task graph representation exists only
as datastructures in memory and is not designed to be exported to files and
loaded from files, unlike the MLIR and the LLVM IR representations. In this
context, this document specifies the programatic API for creating a TGIR.

For context, please consult the documentation for the CASPER compiler
in `casper-utils/README.md`.

In-Memory Task Graph Intermediate Representation
------------------------------------------------

The CASPER Task Graph Intermediate Representation (TGIR) is a hierarchy of
objects that represent individual tasks in a program and datasets that those
tasks operate on. A task is a part of the computation workload, a section of
the program, that is usually written using a Domain Specific Language (DSL).
This section defines the type of objects in this hierarchy, how they
are constructed, and linked into a representation for the whole program.

### `TaskGraph`

The `TaskGraph` class is a top-level container that represents the whole
program. An object of this class contains and owns references to both the task
objects and dataset objects. A task graph object is taken as input into CASPER
API call for compiling the program into an executable.  A single meta-program
may create multiple task graph objects and compile each into a separate
executable.

    TaskGraph(const std::string &name)

Construct an empty CASPER program with the given name. The name is used
in filenames of artifacts created during compilation, and in debugging
log output.

    Task& createTask(HalideKernel kern,
                    std::vector<Value *> args = {},
                    std::vector<Task *> deps = {});
    Task& createTask(CKernel kern,
                    std::vector<Value *> args = {},
                    std::vector<Task *> deps = {});
    Task& createTask(PyKernel kern,
                    std::vector<Value *> args = {},
                    std::vector<Task *> deps = {});
    Task& createTask(FEMAKernel kern,
                    std::vector<Value *> args = {},
                    std::vector<Task *> deps = {});

Create a task and add it to the task graph that represents the whole program.
The first argument to a method in this family is a kernel objects that
represents the computation in the task (type described separately). The
`args` argument contains the list of datasets that the task operates on,
which can be scalars, multi-dimensional arrays, or Python objects (types
described separately).  All datasets operations are assumed to be read-write.
The tasks that the created task depends are passed in the `deps` list. A
dependency of Task B on Task A means that Task A must run before Task B.
These methods return a task object of the type that corresponds to the
type of the kernel (task types and kernel types described separately) --
however, in the current version, the return value is upcast to the parent
`Task` type, but that should be changed. The return value is a reference to an
allocated object whose memory is owned by the `TaskGraph` container; to pass it
into `deps` argument, this reference must be converted into a pointer.

    Dat& createDoubleDat(int dims, std::vector<int> size);
    Dat& createFloatDat(int dims, std::vector<int> size);
    Dat& createIntDat(int width, int dims, std::vector<int> size);

Create a multi-dimensional array dataset with elements of a given
type and with the number of dimensions given in `dims`. The size of each
dimension given in the list `size`. For example, `createFloatDat(2, {3, 3})`
creates a 3x3 matrix of single-precision floating point values. The `width`
argument specifies the number of bits in the integer value, only powers
of two are supported. These methods return a reference to an allocated object
whose memory is owned bythe `TaskGraph` container; to pass it into `args`
argument of task constructing methods, this reference must be converted into a
pointer.

    IntScalar& createIntScalar(uint8_t width, uint64_t v);
    DoubleScalar& createDoubleScalar(double v);

Create a dataset that holds just one element of a given type and with the
value given in `v`. The `width` argument specifies the number of bits
in the integer value, only powers of two are supported. Scalars can be used to
pass a parameter value into a task.  By default, scalars are passed to tasks by
value, which means a task cannot modify such a scalar value. To pass a scalar
by reference, create a pointer from the scalar object using `createPtrScalar()`
(see below), and pass that `PtrScalar` object to the task instead of the
original `Scalar` object.

    IntScalar& createIntScalar(uint8_t width);

Create a dataset that holds just one element of a given type, without
initializing the element to any value. This is only useful in conjuction
with `createPtrScalar()` (described below) for "returning" scalar values from
tasks.

    PtrScalar& createPtrScalar(Scalar *dest);

Create a dataset that represents a reference to a scalar dataset. The
returned `PtrScalar` object wraps the original `Scalar` object. This mechanism
allows passing a scalar dataset into a task by reference instead of by value.
A task that accepts a `PtrScalar` can set the value of the wrapped scalar
variable. This mechanism is useful for "returning" information from a task,
e.g. returning the image size from a task that loads an image from file.

    PyObj& createPyObj();

Create a dataset that can hold arbitrary Python objects, for passing to
and from tasks of type `PyTask` (described separately). The allocated object is
is a Python dictionary (key-value store). A task may insert values into this
dictionary under a key (a string) or lookup values by key. The type of this
object is derived from the common dataset type `Value` and can be passed to
task constructing methods via the `args` argument, along with other dataset
types.  The CASPER runtime components are responsible for reference-counting
this object within the Python interpreter instance linked into the CASPER
application executables.

### `Value` (dataset) hierarchy

The types derived in this hierarchy represent the containers for
data values that tasks operate on. See the `TaskGraph` type for methods for
constructing objects of these types.


    Value

The parent class from which all types of data containers are derived. This
class should not be instantiated directly, only derived classes should be used.

    Dat
    DoubleDat 
    FloatDat
    IntDat

The `Dat` family of types represent a multi-dimensional array of elements of a
given type. The memory layout (stride, offset, etc.) are not yet exposed to
the users of this class.

    Scalar
    IntScalar
    DoubleScalar

Each type in the `Scalar` family represent a single value of a given type.
This value is passed into the task by value, not by references. See `PtrScalar`
type for passing scalar values by reference.

    PtrScalar

A wrapper that wraps a scalar value and is used to pass a scalar value into
a task by reference.
    
    PyObj

A container object used to pass Python objects between tasks. This object
is a Python dictionary. Tasks may insert values into it and look them
up by key.

### `Kernel` heirarchy

A type in this hierarchy represents a portion of the program. Objects of
these types contain a reference to a callable function that is defined by
code written in a DSL or a general-purpose language (C, Python). Objects
of these types would generally be instantiated in a call to the methods for
creating `Task` objects on the `TaskGraph` object (see above) should be used --
those methods accept a kernel object as the first argument.

    HalideKernel(const std::string &func)

A kernel implemented in the Halide language using a generator, with the
entrypoint named `func` specified in the call to `HALIDE_REGISTER_GENERATOR`.

    FEMAKernel(const std::string &module, const std::string &kernelName)

A Finite Element Method (FEM) assembly kernel implemented in the Unified
Form Language (UFL) DSL, embedded into the Python language. Specifically,
this kernel object identifies a generator Python function that creates
and returns the UFL expressions and other state (see details in the compiler
documentation). This generator function is expected to be named `generate`
and to be in a file named `module` with the `.py` extension. The `kernelName`
argument is used only for logging purposes.

    CKernel(const std::string &func)

A kernel that is implemented by a function in C. The prototype of this
function depends on the dataset values associated with the task that
was initialized with this kernel. A value of `Scalar` type corresponds
to an argument of the respective type (e.g. `IntScalar` -> `int`);
a value of `Dat` type maps into a sequence of arguments:
* `T *M_buf`: pointer to the allocated memory region
* `T *M`: pointer to first value in the allocated memory region
* `int offset`: offset into the buffer
* `int n`: size of dimention, one argument for each dimension
* `int s`: strite along the dimension, one argument for each dimension
The function name specified by `func` must be the symbol name.

    PyKernel(const std::string &module, const std::string &func)

A kernel implemented by a function in Python. The function must be named
`func` and must be in a file named `module` with a `.py` extension. The
arguments into the function depend on the dataset values passed into the
task that was initialized with this kernel. Only dataset values of type
`PyObj` are supported. Each `PyObj` object will translate into an argument
to the kernel function, and this argument will be a dictionary into which
the kernel code may insert new values and lookup existing values (see `PyObj`).
The function may not return anything (except `None`).

### `Task` heirarchy

Task objects are the basic building block of a CASPER program. A task
associates a kernel (an object of type `Kernel`) with the datasets that
the kernel operates on. The `TaskGraph` container stores the information
about dependencies between tasks. Objects of this type should not be
instantiated directly, instead, the `createTask` methods on the `TaskGraph`
objects should be used.

    HalideTask

A task that is implemented using a kernel written in the Halide DSL
(`HalideKernel`). The associated dataset arguments may be of type `Dat` or
`Scalar`.

    CTask

A task that is implemented using a kernel written in C (`CKernel`). The
associated dataset arguments may be of type `Dat` or `Scalar`.

    PyTask

A task that is implemented using a kernel written in Python (`PyKernel`) or
Unified Form Language (UFL) for Finite Element Method assembly (`FEMAKernel`).
The associated dataset arguments may be of type `PyObj`.
