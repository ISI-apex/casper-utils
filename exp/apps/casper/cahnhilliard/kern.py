import os
import sys
import time

# Must be before importing firedrake!
os.environ["OMP_NUM_THREADS"] = str(1)

from firedrake import *
import casper

mesh_size = 128
dim = 2
preconditioner = 'fieldsplit'
ksp = 'gmres'
inner_ksp = 'preonly'
max_iterations = 1
degree = 1
dt = 5.0e-06
lmbda = 1.0e-02
theta = 0.5
steps = 1
compute_norms = False # TODO
verbose = False

solution_out = None
#solution_out = 'ch-sol.pvd'

def generate():
    tasks = dict()

    params = {'pc_type': preconditioner,
              'ksp_type': ksp,
              #'ksp_monitor': True,
              'snes_monitor': None,

              #'snes_rtol': 1e-9,
              #'snes_atol': 1e-10,
              #'snes_stol': 1e-14,

              'snes_rtol': 1e-5,
              'snes_atol': 1e-6,
              'snes_stol': 1e-7,

              #'snes_rtol': 1e-4,
              #'snes_atol': 1e-6,
              #'snes_stol': 1e-8,

              #'snes_rtol': 1e-2,
              #'snes_atol': 1e-4,
              #'snes_stol': 1e-6,
              'snes_linesearch_type': 'basic',
              'snes_linesearch_max_it': 1,
              #'ksp_rtol': 1e-6,
              #'ksp_atol': 1e-15,

              #'ksp_rtol': 1e-5,
              #'ksp_atol': 1e-9,

              'ksp_rtol': 1e-4,
              'ksp_atol': 1e-8,
              'pc_fieldsplit_type': 'schur',
              'pc_fieldsplit_schur_factorization_type': 'lower',
              'pc_fieldsplit_schur_precondition': 'user',
              'fieldsplit_0_ksp_type': inner_ksp,
              'fieldsplit_0_ksp_max_it': max_iterations,
              'fieldsplit_0_pc_type': 'hypre',
              'fieldsplit_1_ksp_type': inner_ksp,
              'fieldsplit_1_ksp_max_it': max_iterations,
              'fieldsplit_1_pc_type': 'mat'}
    if verbose:
        params['ksp_monitor'] = True
        params['snes_view'] = True
        params['snes_monitor'] = True

    # TODO: on the generator path, this shouldn't distribute the mesh
    if dim == 2:
        mesh = UnitSquareMesh(mesh_size, mesh_size)
    else:
        mesh = UnitCubeMesh(mesh_size, mesh_size, mesh_size)

    V = FunctionSpace(mesh, "Lagrange", degree)
    ME = V*V

    # Define trial and test functions
    du = TrialFunction(ME)
    q, v = TestFunctions(ME)

    # Define functions
    u = Function(ME)   # current solution
    u0 = Function(ME)  # solution from previous converged step

    # Split mixed functions
    dc, dmu = split(du)
    c, mu = split(u)
    c0, mu0 = split(u0)

    # Create intial conditions and interpolate
    init_code = "A[0] = 0.63 + 0.02*(0.5 - (double)random()/RAND_MAX);"
    user_code = """int __rank;
    MPI_Comm_rank(MPI_COMM_WORLD, &__rank);
    srandom(2 + __rank);"""
    tasks["init"] = [par_loop(init_code, direct, {'A': (u[0], WRITE)},
             headers=["#include <stdlib.h>"], user_code=user_code,
             compute=False)]

    u.dat.data_ro

    # Compute the chemical potential df/dc
    c = variable(c)
    f = 100*c**2*(1-c)**2
    dfdc = diff(f, c)

    mu_mid = (1.0-theta)*mu0 + theta*mu

    # Weak statement of the equations
    F0 = c*q*dx - c0*q*dx + dt*dot(grad(mu_mid), grad(q))*dx
    F1 = mu*v*dx - dfdc*v*dx - lmbda*dot(grad(c), grad(v))*dx
    F = F0 + F1

    # Compute directional derivative about u in the direction of du (Jacobian)
    J = derivative(F, u, du)

    problem = NonlinearVariationalProblem(F, u, J=J)
    solver = NonlinearVariationalSolver(problem, solver_parameters=params)

    sigma = 100
    # PC for the Schur complement solve
    trial = TrialFunction(V)
    test = TestFunction(V)

    tasks["mass"] = casper.assemble(inner(trial, test)*dx)

    a = 1
    c = (dt * lmbda)/(1+dt * sigma)

    tasks["hats"] = casper.assemble(sqrt(a) * inner(trial, test)*dx + \
            sqrt(c)*inner(grad(trial), grad(test))*dx)

    tasks["assign"] = casper.assign(u0, u)

    # TODO: define a class (contract with Casper compiler, so
    # need to define the class in a py module offered by Casper to the app)
    return tasks, solver, dict(u=u, u0=u0)

def solve(ctx, state):
    out_file = File(solution_out) if solution_out else None

    mass = state["mass"]
    hats = state["hats"]

    u = ctx[2]["u"]
    u0 = ctx[2]["u0"]
    solver = ctx[1]

    from firedrake.petsc import PETSc
    ksp_hats = PETSc.KSP()
    ksp_hats.create()
    ksp_hats.setOperators(hats)
    opts = PETSc.Options()

    opts['ksp_type'] = inner_ksp
    opts['ksp_max_it'] = max_iterations
    opts['pc_type'] = 'hypre'
    ksp_hats.setFromOptions()

    class SchurInv(object):
        def mult(self, mat, x, y):
            tmp1 = y.duplicate()
            tmp2 = y.duplicate()
            ksp_hats.solve(x, tmp1)
            mass.mult(tmp1, tmp2)
            ksp_hats.solve(tmp2, y)

    pc_schur = PETSc.Mat()
    pc_schur.createPython(mass.getSizes(), SchurInv())
    pc_schur.setUp()
    pc = solver.snes.ksp.pc
    pc.setFieldSplitSchurPreType(PETSc.PC.SchurPreType.USER, pc_schur)

    for step in range(steps):
        casper.invoke_task(ctx, "assign", state)
        solver.solve()
        if out_file is not None:
            out_file.write(u.split()[0], time=step)
        if compute_norms:
            nu = norm(u)
            if comm.rank == 0:
                print(step, 'L2(u):', nu)
