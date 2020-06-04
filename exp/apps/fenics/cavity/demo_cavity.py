"""This demo solves the Stokes equations, using quadratic elements for
the velocity and first degree elements for the pressure (Taylor-Hood
elements) for the Lid-Driven cavity problem."""

import time
import os
import sys

N = int(sys.argv[1])
SOLVER = sys.argv[2]
if len(sys.argv) > 3:
    GPU = int(sys.argv[3])
else:
    GPU = 1
if len(sys.argv) > 4:
    THREADS = int(sys.argv[4])
else:
    THREADS = 1

# Must be before dolfin (at least this is true for Firedrake)
os.environ["OMP_NUM_THREADS"] = str(THREADS)

omp_threads = THREADS

#if "OMP_NUM_THREADS" in os.environ:
#    omp_threads = int(os.environ["OMP_NUM_THREADS"])
#else:
#    omp_threads = 1

import matplotlib.pyplot as plt
from dolfin import *

print(linear_algebra_backends())
print(linear_solver_methods())
print(lu_solver_methods())
print(krylov_solver_methods())
#sys.exit(0)

# Needed to match FreeFEM (otherwise, default choice results in out of memory for 256x256)
#PETScOptions.set('mat_umfpack_strategy', 'symmetric')
#sys.exit(0)

sparams = parameters["lu_solver"]
sparams["verbose"] = True
sparams["report"] = True
info(sparams, True)
set_log_level(LogLevel.DEBUG)


# Load mesh and subdomains

mesh = UnitSquareMesh(N, N)

#mesh = Mesh("../dolfin_fine.xml.gz")
#sub_domains = MeshFunction("size_t", mesh, "../dolfin_fine_subdomains.xml.gz")
#mesh = UnitSquareMesh(8, 8)
#mesh = UnitSquareMesh(16, 16)
#mesh = UnitSquareMesh(64, 64)
#mesh = UnitSquareMesh(100, 100)
#mesh = UnitSquareMesh(128, 128)
#mesh = UnitSquareMesh(256, 256)
#mesh = UnitSquareMesh(512,512)

#plt.figure()
#plot(mesh)

start_time = time.time()

#plt.figure()
#plot(sub_domains)

# Define function spaces
P2 = VectorElement("Lagrange", mesh.ufl_cell(), 2)
P1 = FiniteElement("Lagrange", mesh.ufl_cell(), 1)
TH = P2 * P1
W = FunctionSpace(mesh, TH)

# No-slip boundary condition for velocity
# x1 = 0, x1 = 1 and around the dolphin
#noslip = Constant((0, 0))
#bc0 = DirichletBC(W.sub(0), noslip, sub_domains, 0)
def lid_boundary(x, on_boundary):
    return on_boundary and x[1] == 1
def wall_boundary(x, on_boundary):
    return on_boundary and x[1] != 1
bc0 = DirichletBC(W.sub(0), Constant((1, 0)), lid_boundary)
bc1 = DirichletBC(W.sub(0), Constant((0, 0)), wall_boundary)

# Inflow boundary condition for velocity
# x0 = 1
#inflow = Expression(("-sin(x[1]*pi)", "0.0"), degree=2)
#bc1 = DirichletBC(W.sub(0), inflow, sub_domains, 1)

# Collect boundary conditions
bcs = [bc0, bc1]

# Define variational problem
(u, p) = TrialFunctions(W)
(v, q) = TestFunctions(W)
f = Constant((0, 0))
a = (inner(grad(u), grad(v)) - div(v)*p + q*div(u))*dx
L = inner(f, v)*dx

# Compute solution
w = Function(W)
info(LinearVariationalSolver.default_parameters(), 1)
#exit(0)
#time.sleep(30)

# NOTE: KSPType defaults to PREONLY (not GMRES)

PETScOptions.set("mat_pastix_threadnbr", omp_threads)
PETScOptions.set("mat_pastix_gpunbr", GPU)
PETScOptions.set("mat_pastix_verbose", 2)
PETScOptions.set("mat_pastix_scheduler", 3)
PETScOptions.set("mat_pastix_refinement", -1)
PETScOptions.set("mat_pastix_epsilonrefinement", 1e-4)

#"mat_pastix_verbose": 2,
#"mat_pastix_scheduler": 3,
##"mat_pastix_itermax": 1,
##"mat_pastix_gmresim": 50,
#"mat_pastix_epsilonrefinement": 1e-6
##"mat_pastix_threadnbr": ((GPU + 1) % 2),
#"mat_pastix_gpunbr": GPU,
solve(a == L, w, bcs,
        #solver_parameters=dict(linear_solver="umfpack"))
        #solver_parameters=dict(linear_solver="mumps"))
        #solver_parameters=dict(linear_solver="superlu_dist"))
        #solver_parameters=dict(linear_solver="pastix"))
        solver_parameters=dict(linear_solver=SOLVER))
        #krylov_solver=dict(absolute_tolerance=1e-2)))

end_time = time.time()
print("EXEC TIME (sec): mesh", N, "solver", SOLVER, "threads", THREADS, "gpu", GPU, ":", end_time - start_time)

# Split the mixed solution using deepcopy
# (needed for further computation on coefficient vector)
(u, p) = w.split(True)

print("Norm of velocity coefficient vector: %.15g" % u.vector().norm("l2"))
print("Norm of pressure coefficient vector: %.15g" % p.vector().norm("l2"))

# # Split the mixed solution using a shallow copy
(u, p) = w.split()

# Save solution in VTK format
ufile_pvd = File("velocity.pvd")
ufile_pvd << u
pfile_pvd = File("pressure.pvd")
pfile_pvd << p

# Plot solution
f = plt.figure()
plot(u, title="velocity")
f.savefig('velocity.pdf', bbox_inches='tight')

f = plt.figure()
plot(p, title="pressure")
f.savefig('pressure.pdf', bbox_inches='tight')

# Display plots
plt.show()
