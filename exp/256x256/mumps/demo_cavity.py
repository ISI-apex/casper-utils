"""This demo solves the Stokes equations, using quadratic elements for
the velocity and first degree elements for the pressure (Taylor-Hood
elements) for the Lid-Driven cavity problem."""

import matplotlib.pyplot as plt
from dolfin import *
import time

import sys
print(linear_algebra_backends())
print(linear_solver_methods())
print(lu_solver_methods())

# Needed to match FreeFEM (otherwise, default choice results in out of memory for 256x256)
#PETScOptions.set('mat_umfpack_strategy', 'symmetric')
#sys.exit(0)

sparams = parameters["lu_solver"]
sparams["verbose"] = True
sparams["report"] = True
info(sparams, True)
set_log_level(LogLevel.DEBUG)

# Load mesh and subdomains
#mesh = Mesh("../dolfin_fine.xml.gz")
#sub_domains = MeshFunction("size_t", mesh, "../dolfin_fine_subdomains.xml.gz")
#mesh = UnitSquareMesh(8, 8)
#mesh = UnitSquareMesh(16, 16)
#mesh = UnitSquareMesh(128, 128)
mesh = UnitSquareMesh(256, 256)
#mesh = UnitSquareMesh(512,512)

plt.figure()
plot(mesh)

t_start = time.time()

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
#time.sleep(30)
solve(a == L, w, bcs,
        #solver_parameters=dict(linear_solver="umfpack"))
        solver_parameters=dict(linear_solver="mumps"))

print("Time:", time.time() - t_start, "s")

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
